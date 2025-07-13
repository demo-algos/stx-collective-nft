;; STX Collective NFT - Split expensive NFTs into smaller shares
;; Built on Stacks blockchain using Clarity

;; Define the NFT trait for compatibility
(define-trait nft-trait
  (
    (get-last-token-id () (response uint uint))
    (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
    (get-owner (uint) (response (optional principal) uint))
    (transfer (uint principal principal) (response bool uint))
  )
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-shares (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-transfer-failed (err u106))
(define-constant err-invalid-shares (err u107))

;; Data Variables
(define-data-var next-collective-id uint u1)

;; Data Maps
(define-map collectives
  { collective-id: uint }
  {
    nft-contract: principal,
    nft-token-id: uint,
    total-shares: uint,
    share-price: uint,
    creator: principal,
    active: bool
  }
)

(define-map shares
  { collective-id: uint, owner: principal }
  { amount: uint }
)

(define-map collective-metadata
  { collective-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256)
  }
)

;; Read-only functions
(define-read-only (get-collective (collective-id uint))
  (map-get? collectives { collective-id: collective-id })
)

(define-read-only (get-shares (collective-id uint) (owner principal))
  (default-to 
    { amount: u0 }
    (map-get? shares { collective-id: collective-id, owner: owner })
  )
)

(define-read-only (get-collective-metadata (collective-id uint))
  (map-get? collective-metadata { collective-id: collective-id })
)

(define-read-only (get-next-collective-id)
  (var-get next-collective-id)
)

(define-read-only (get-share-percentage (collective-id uint) (owner principal))
  (let (
    (collective-info (unwrap! (get-collective collective-id) (err err-not-found)))
    (user-shares (get amount (get-shares collective-id owner)))
    (total-shares (get total-shares collective-info))
  )
    (if (> total-shares u0)
      (ok (/ (* user-shares u10000) total-shares)) ;; Return basis points (1/10000)
      (err err-invalid-shares)
    )
  )
)

;; Private functions
(define-private (transfer-stx (amount uint) (from principal) (to principal))
  (stx-transfer? amount from to)
)

;; Public functions
(define-public (create-collective 
  (nft-contract principal)
  (nft-token-id uint)
  (total-shares uint)
  (share-price uint)
  (name (string-ascii 64))
  (description (string-ascii 256))
)
  (let (
    (collective-id (var-get next-collective-id))
  )
    (asserts! (> total-shares u0) err-invalid-shares)
    (asserts! (> share-price u0) err-invalid-amount)
    
    ;; Store collective info
    (map-set collectives
      { collective-id: collective-id }
      {
        nft-contract: nft-contract,
        nft-token-id: nft-token-id,
        total-shares: total-shares,
        share-price: share-price,
        creator: tx-sender,
        active: true
      }
    )
    
    ;; Store metadata
    (map-set collective-metadata
      { collective-id: collective-id }
      {
        name: name,
        description: description
      }
    )
    
    ;; Increment next ID
    (var-set next-collective-id (+ collective-id u1))
    
    (ok collective-id)
  )
)

(define-public (buy-shares (collective-id uint) (share-amount uint))
  (let (
    (collective-info (unwrap! (get-collective collective-id) err-not-found))
    (current-shares (get amount (get-shares collective-id tx-sender)))
    (total-cost (* share-amount (get share-price collective-info)))
  )
    (asserts! (get active collective-info) err-not-authorized)
    (asserts! (> share-amount u0) err-invalid-amount)
    
    ;; Transfer STX payment to contract
    (try! (transfer-stx total-cost tx-sender (as-contract tx-sender)))
    
    ;; Update shares
    (map-set shares
      { collective-id: collective-id, owner: tx-sender }
      { amount: (+ current-shares share-amount) }
    )
    
    (ok share-amount)
  )
)

(define-public (sell-shares (collective-id uint) (share-amount uint))
  (let (
    (collective-info (unwrap! (get-collective collective-id) err-not-found))
    (current-shares (get amount (get-shares collective-id tx-sender)))
    (refund-amount (* share-amount (get share-price collective-info)))
  )
    (asserts! (get active collective-info) err-not-authorized)
    (asserts! (>= current-shares share-amount) err-insufficient-shares)
    (asserts! (> share-amount u0) err-invalid-amount)
    
    ;; Update shares
    (map-set shares
      { collective-id: collective-id, owner: tx-sender }
      { amount: (- current-shares share-amount) }
    )
    
    ;; Transfer STX refund
    (try! (as-contract (transfer-stx refund-amount tx-sender tx-sender)))
    
    (ok share-amount)
  )
)

(define-public (transfer-shares 
  (collective-id uint) 
  (share-amount uint) 
  (recipient principal)
)
  (let (
    (collective-info (unwrap! (get-collective collective-id) err-not-found))
    (sender-shares (get amount (get-shares collective-id tx-sender)))
    (recipient-shares (get amount (get-shares collective-id recipient)))
  )
    (asserts! (get active collective-info) err-not-authorized)
    (asserts! (>= sender-shares share-amount) err-insufficient-shares)
    (asserts! (> share-amount u0) err-invalid-amount)
    
    ;; Update sender shares
    (map-set shares
      { collective-id: collective-id, owner: tx-sender }
      { amount: (- sender-shares share-amount) }
    )
    
    ;; Update recipient shares
    (map-set shares
      { collective-id: collective-id, owner: recipient }
      { amount: (+ recipient-shares share-amount) }
    )
    
    (ok true)
  )
)

(define-public (deactivate-collective (collective-id uint))
  (let (
    (collective-info (unwrap! (get-collective collective-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get creator collective-info)) err-not-authorized)
    
    (map-set collectives
      { collective-id: collective-id }
      (merge collective-info { active: false })
    )
    
    (ok true)
  )
)

;; Emergency functions (only contract owner)
(define-public (emergency-pause (collective-id uint))
  (let (
    (collective-info (unwrap! (get-collective collective-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set collectives
      { collective-id: collective-id }
      (merge collective-info { active: false })
    )
    
    (ok true)
  )
)

(define-public (withdraw-contract-balance (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (as-contract (transfer-stx amount tx-sender contract-owner)))
    (ok true)
  )
)

;; Initialize contract
(begin
  (print "STX Collective NFT contract deployed successfully")
)