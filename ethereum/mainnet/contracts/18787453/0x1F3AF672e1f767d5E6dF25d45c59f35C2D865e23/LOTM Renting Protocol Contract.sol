# @version 0.3.9

"""
@title LOTM Renting Protocol Contract
@author [Zharta](https://zharta.io/)
@notice This contract manages the renting process for NFTs in the LOTM Renting Protocol.
@dev This contract is the single user-facing contract for each Renting Market. It does not hold any assets, it manages the creation of vaults (as minimal proxies to the vault implementation) and delegates the calls to the vaults, with the exception of the admin functions.
"""

# Interfaces

interface ISelf:
    def tokenid_to_vault(token_id: uint256) -> address: view
    def is_vault_available(token_id: uint256) -> bool: view


interface IVault:
    def is_initialised() -> bool: view
    def initialise(owner: address): nonpayable
    def deposit(token_id: uint256, price: uint256, min_duration: uint256, max_duration: uint256, delegate: address): nonpayable
    def set_listing(state: VaultState, token_id: uint256, sender: address, price: uint256, min_duration: uint256, max_duration: uint256, delegate: address): nonpayable
    def start_rental(state: VaultState, renter: address, expiration: uint256, delegate: address, protocol_fee: uint256, protocol_wallet: address) -> Rental: nonpayable
    def close_rental(state: VaultState, sender: address) -> uint256: nonpayable
    def claim(state: VaultState, sender: address) -> (Rental, uint256, uint256): nonpayable
    def withdraw(state: VaultState, sender: address) -> (uint256, uint256): nonpayable
    def delegate_to_wallet(state: VaultState, sender: address, delegate: address): nonpayable


# Structs

struct TokenContext:
    token_id: uint256
    active_rental: Rental
    listing: Listing

struct VaultState:
    active_rental: Rental
    listing: Listing

struct Rental:
    id: bytes32 # keccak256 of the renter, token_id, start and expiration
    owner: address
    renter: address
    delegate: address
    token_id: uint256
    start: uint256
    min_expiration: uint256
    expiration: uint256
    amount: uint256
    protocol_fee: uint256
    protocol_wallet: address

struct Listing:
    token_id: uint256
    price: uint256 # price per hour, 0 means not listed
    min_duration: uint256 # min duration in hours
    max_duration: uint256 # max duration in hours, 0 means unlimited

struct VaultLog:
    vault: address
    token_id: uint256

struct RentalLog:
    id: bytes32
    vault: address
    owner: address
    token_id: uint256
    start: uint256
    min_expiration: uint256
    expiration: uint256
    amount: uint256
    protocol_fee: uint256
    protocol_wallet: address

struct RewardLog:
    vault: address
    token_id: uint256
    amount: uint256
    protocol_fee_amount: uint256
    active_rental_amount: uint256

struct WithdrawalLog:
    vault: address
    token_id: uint256
    rewards: uint256
    protocol_fee_amount: uint256


# Events

event VaultsCreated:
    owner: address
    nft_contract: address
    min_duration: uint256
    max_duration: uint256
    price: uint256
    vaults: DynArray[VaultLog, 32]
    delegate: address

event NftsDeposited:
    owner: address
    nft_contract: address
    min_duration: uint256
    max_duration: uint256
    price: uint256
    vaults: DynArray[VaultLog, 32]
    delegate: address

event NftsWithdrawn:
    owner: address
    nft_contract: address
    total_rewards: uint256
    withdrawals: DynArray[WithdrawalLog, 32]

event ListingsChanged:
    owner: address
    nft_contract: address
    min_duration: uint256
    max_duration: uint256
    price: uint256
    vaults: DynArray[VaultLog, 32]
    delegate: address

event ListingsCancelled:
    owner: address
    nft_contract: address
    vaults: DynArray[VaultLog, 32]
    delegate: address

event RentalStarted:
    renter: address
    delegate: address
    nft_contract: address
    rentals: DynArray[RentalLog, 32]

event RentalClosed:
    renter: address
    nft_contract: address
    rentals: DynArray[RentalLog, 32]

event RewardsClaimed:
    owner: address
    nft_contract: address
    rewards: DynArray[RewardLog, 32]

event DelegatedToWallet:
    owner: address
    delegate: address
    nft_contract: address
    vaults: DynArray[VaultLog, 32]

event ProtocolFeeSet:
    old_fee: uint256
    new_fee: uint256
    fee_wallet: address

event ProtocolWalletChanged:
    old_wallet: address
    new_wallet: address

event AdminProposed:
    admin: address
    proposed_admin: address

event OwnershipTransferred:
    old_admin: address
    new_admin: address


# Global Variables

_COLLISION_OFFSET: constant(bytes1) = 0xFF
_DEPLOYMENT_CODE: constant(bytes9) = 0x602D3D8160093D39F3
_PRE: constant(bytes10) = 0x363d3d373d3d3d363d73
_POST: constant(bytes15) = 0x5af43d82803e903d91602b57fd5bf3

vault_impl_addr: public(immutable(address))
payment_token_addr: public(immutable(address))
nft_contract_addr: public(immutable(address))
delegation_registry_addr: public(immutable(address))
max_protocol_fee: public(immutable(uint256))

protocol_wallet: public(address)
protocol_fee: public(uint256)
protocol_admin: public(address)
proposed_admin: public(address)

active_vaults: public(HashMap[uint256, address]) # token_id -> vault


##### EXTERNAL METHODS - WRITE #####

@external
def __init__(
    _vault_impl_addr: address,
    _payment_token_addr: address,
    _nft_contract_addr: address,
    _delegation_registry_addr: address,
    _max_protocol_fee: uint256,
    _protocol_fee: uint256,
    _protocol_wallet: address,
    _protocol_admin: address
):

    """
    @notice Initialize the renting contract with necessary parameters and addresses.
    @dev Sets up the contract by initializing various addresses and fees.
    @param _vault_impl_addr The address of the vault implementation.
    @param _payment_token_addr The address of the payment token.
    @param _nft_contract_addr The address of the NFT contract.
    @param _delegation_registry_addr The address of the delegation registry.
    @param _max_protocol_fee The maximum protocol fee that can be set.
    @param _protocol_fee The initial protocol fee.
    @param _protocol_wallet The wallet to receive protocol fees.
    @param _protocol_admin The administrator of the protocol.
    """

    assert _vault_impl_addr != empty(address), "vault impl is the zero addr"
    assert _payment_token_addr != empty(address), "payment token is the zero addr"
    assert _nft_contract_addr != empty(address), "nft contract is the zero addr"
    assert _delegation_registry_addr != empty(address), "deleg registry is the zero addr"
    assert _max_protocol_fee <= 10000, "max protocol fee > 100%"
    assert _protocol_fee <= _max_protocol_fee, "protocol fee > max fee"
    assert _protocol_wallet != empty(address), "protocol wallet not set"
    assert _protocol_admin != empty(address), "admin wallet not set"

    vault_impl_addr = _vault_impl_addr
    payment_token_addr = _payment_token_addr
    nft_contract_addr = _nft_contract_addr
    delegation_registry_addr = _delegation_registry_addr
    max_protocol_fee = _max_protocol_fee

    self.protocol_wallet = _protocol_wallet
    self.protocol_fee = _protocol_fee
    self.protocol_admin = _protocol_admin


@external
def create_vaults_and_deposit(token_ids: DynArray[uint256, 32], price: uint256, min_duration: uint256, max_duration: uint256, delegate: address):

    """
    @notice Create new vaults and deposit NFTs with specified listing terms.
    @dev Iterates over a list of token ids, creating vaults and depositing NFTs with the given listing terms.
    @param token_ids An array of NFT token ids to create vaults for and deposit.
    @param price Rental price per hour for each NFT, 0 meaning unlisted.
    @param min_duration Minimum rental duration in hours.
    @param max_duration Maximum rental duration in hours, 0 for unlimited.
    @param delegate Address to delegate the NFT to while listed.
    """

    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self._create_vault_and_deposit(token_id, price, min_duration, max_duration, delegate)
        vault_logs.append(VaultLog({
            vault: vault,
            token_id: token_id
        }))

    log VaultsCreated(
        msg.sender,
        nft_contract_addr,
        min_duration,
        max_duration,
        price,
        vault_logs,
        delegate
    )


@external
def deposit(token_ids: DynArray[uint256, 32], price: uint256, min_duration: uint256, max_duration: uint256, delegate: address):

    """
    @notice Deposit NFTs into existing vaults with specified listing terms.
    @dev Iterates over a list of token ids, depositing NFTs into their respective vaults with the given listing terms.
    @param token_ids An array of NFT token ids to deposit.
    @param price Rental price per hour for each NFT, 0 meaning unlisted.
    @param min_duration Minimum rental duration in hours.
    @param max_duration Maximum rental duration in hours, 0 for unlimited.
    @param delegate Address to delegate the NFT to while listed.
    """

    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self._deposit_nft(token_id, price, min_duration, max_duration, delegate)
        vault_logs.append(VaultLog({
            vault: vault,
            token_id: token_id
        }))

    log NftsDeposited(
        msg.sender,
        nft_contract_addr,
        min_duration,
        max_duration,
        price,
        vault_logs,
        delegate
    )


@external
def set_listings(
    token_contexts: DynArray[TokenContext, 32],
    price: uint256,
    min_duration: uint256,
    max_duration: uint256,
    delegate: address
):

    """
    @notice Set listings for multiple NFTs in their respective vaults.
    @dev Iterates over a list of token contexts, updating the listings with the given terms.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    @param price Rental price per hour for each NFT, 0 meaning unlisted.
    @param min_duration Minimum rental duration in hours.
    @param max_duration Maximum rental duration in hours, 0 for unlimited.
    @param delegate Address to delegate the NFT to while listed.
    """

    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).set_listing(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing
            }),
            token_context.token_id,
            msg.sender,
            price,
            min_duration,
            max_duration,
            delegate
        )

        vault_logs.append(VaultLog({
            vault: vault,
            token_id: token_context.token_id
        }))

    log ListingsChanged(
        msg.sender,
        nft_contract_addr,
        min_duration,
        max_duration,
        price,
        vault_logs,
        delegate,
    )

@external
def cancel_listings(token_contexts: DynArray[TokenContext, 32], delegate: address):

    """
    @notice Cancel listings for multiple NFTs in their respective vaults.
    @dev Iterates over a list of token contexts, canceling the listings in their respective vaults.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    @param delegate Address to delegate the NFT to while unlisted.
    """

    vaults: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).set_listing(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing
            }),
            token_context.token_id,
            msg.sender,
            0,
            0,
            0,
            delegate
        )

        vaults.append(VaultLog({
            vault: vault,
            token_id: token_context.token_id
        }))

    log ListingsCancelled(
        msg.sender,
        nft_contract_addr,
        vaults,
        delegate
    )


@external
def start_rentals(token_contexts: DynArray[TokenContext, 32], duration: uint256, delegate: address):

    """
    @notice Start rentals for multiple NFTs based on their token contexts.
    @dev Iterates over token contexts to begin rentals for each NFT in their respective vaults.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    @param duration The duration of the rentals in hours.
    @param delegate The address to delegate the NFT to during the rental period.
    """

    rental_logs: DynArray[RentalLog, 32] = []

    expiration: uint256 = block.timestamp + duration * 3600

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        rental: Rental = IVault(vault).start_rental(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing,
            }),
            msg.sender,
            expiration,
            delegate,
            self.protocol_fee,
            self.protocol_wallet
        )

        rental_logs.append(RentalLog({
            id: rental.id,
            vault: vault,
            owner: rental.owner,
            token_id: token_context.token_id,
            start: rental.start,
            min_expiration: rental.min_expiration,
            expiration: expiration,
            amount: rental.amount,
            protocol_fee: rental.protocol_fee,
            protocol_wallet: rental.protocol_wallet
        }))

    log RentalStarted(msg.sender, delegate, nft_contract_addr, rental_logs)


@external
def close_rentals(token_contexts: DynArray[TokenContext, 32]):

    """
    @notice Close rentals for multiple NFTs, allowing for early rental cancelation by the renter.
    @dev Iterates over token contexts to end rentals for each NFT in their respective vaults.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    """

    rental_logs: DynArray[RentalLog, 32] = []

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        amount: uint256 = IVault(vault).close_rental(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing
            }),
            msg.sender
        )

        rental_logs.append(RentalLog({
            id: token_context.active_rental.id,
            vault: vault,
            owner: token_context.active_rental.owner,
            token_id: token_context.active_rental.token_id,
            start: token_context.active_rental.start,
            min_expiration: token_context.active_rental.min_expiration,
            expiration: block.timestamp,
            amount: amount,
            protocol_fee: token_context.active_rental.protocol_fee,
            protocol_wallet: token_context.active_rental.protocol_wallet
        }))

    log RentalClosed(msg.sender, nft_contract_addr, rental_logs)


@external
def claim(token_contexts: DynArray[TokenContext, 32]):

    """
    @notice Claim rewards and protocol fees for multiple NFTs.
    @dev Iterates over token contexts to claim any unclaimed rewards and fees from the vaults.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    """

    reward_logs: DynArray[RewardLog, 32] = []
    active_rental: Rental = empty(Rental)
    rewards: uint256 = 0
    protocol_fee_amount: uint256 = 0

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        active_rental, rewards, protocol_fee_amount = IVault(vault).claim(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing
            }),
            msg.sender
        )

        reward_logs.append(RewardLog({
            vault: vault,
            token_id: token_context.token_id,
            amount: rewards,
            protocol_fee_amount: protocol_fee_amount,
            active_rental_amount: active_rental.amount
        }))

    log RewardsClaimed(msg.sender, nft_contract_addr, reward_logs)


@external
def withdraw(token_contexts: DynArray[TokenContext, 32]):

    """
    @notice Withdraw multiple NFTs and claim rewards and protocol fees.
    @dev Iterates over token contexts to withdraw NFTs from their vaults and claim any unclaimed rewards and fees.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    """

    withdrawal_log: DynArray[WithdrawalLog, 32] = empty(DynArray[WithdrawalLog, 32])
    total_rewards: uint256 = 0
    rewards: uint256 = 0
    protocol_fee_amount: uint256 = 0

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        self.active_vaults[token_context.token_id] = empty(address)

        rewards, protocol_fee_amount = IVault(vault).withdraw(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing
            }),
            msg.sender
        )

        withdrawal_log.append(WithdrawalLog({
            vault: vault,
            token_id: token_context.token_id,
            rewards: rewards,
            protocol_fee_amount: protocol_fee_amount
        }))
        total_rewards += rewards

    log NftsWithdrawn(
        msg.sender,
        nft_contract_addr,
        total_rewards,
        withdrawal_log
    )

@external
def delegate_to_wallet(token_contexts: DynArray[TokenContext, 32], delegate: address):

    """
    @notice Delegate NFTs to a specified wallet.
    @dev Iterates over token contexts to set the delegation of NFTs in their vaults.
    @param token_contexts An array of token contexts, each containing the vault state for an NFT.
    @param delegate The address to delegate the NFTs to.
    """

    vaults: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_context in token_contexts:
        vault: address = self.active_vaults[token_context.token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).delegate_to_wallet(
            VaultState({
                active_rental: token_context.active_rental,
                listing: token_context.listing
            }),
            msg.sender,
            delegate
        )

        vaults.append(VaultLog({
            vault: vault,
            token_id: token_context.token_id
        }))

    log DelegatedToWallet(
        msg.sender,
        delegate,
        nft_contract_addr,
        vaults,
    )

@external
def set_protocol_fee(protocol_fee: uint256):

    """
    @notice Set the protocol fee for the renting process.
    @dev Updates the protocol fee, ensuring it doesn't exceed the maximum allowed.
    @param protocol_fee The new protocol fee to be set, in bps (e.g., 500 for 5%).
    """

    assert msg.sender == self.protocol_admin, "not protocol admin"
    assert protocol_fee <= max_protocol_fee, "protocol fee > max fee"
    assert protocol_fee != self.protocol_fee, "protocol fee is the same"

    log ProtocolFeeSet(
        self.protocol_fee,
        protocol_fee,
        self.protocol_wallet
    )

    self.protocol_fee = protocol_fee


@external
def change_protocol_wallet(new_protocol_wallet: address):

    """
    @notice Change the wallet address that receives the protocol fees.
    @dev Updates the protocol wallet address.
    @param new_protocol_wallet The new address for the protocol wallet.
    """

    assert msg.sender == self.protocol_admin, "not protocol admin"
    assert new_protocol_wallet != empty(address), "wallet is the zero address"

    log ProtocolWalletChanged(
        self.protocol_wallet,
        new_protocol_wallet
    )

    self.protocol_wallet = new_protocol_wallet


@external
def propose_admin(_address: address):

    """
    @notice Propose a new administrator for the protocol.
    @dev Sets a new proposed admin, which needs to claim ownership to become effective.
    @param _address The address of the proposed new admin.
    """

    assert msg.sender == self.protocol_admin, "not the admin"
    assert _address != empty(address), "_address is the zero address"
    assert self.protocol_admin != _address, "proposed admin addr is the admin"
    assert self.proposed_admin != _address, "proposed admin addr is the same"

    self.proposed_admin = _address

    log AdminProposed(
        self.protocol_admin,
        _address
    )


@external
def claim_ownership():

    """
    @notice Claim the role of protocol administrator.
    @dev Finalizes the admin transfer process by setting the caller as the new admin.
    """

    assert msg.sender == self.proposed_admin, "not the proposed"

    log OwnershipTransferred(
        self.protocol_admin,
        self.proposed_admin
    )

    self.protocol_admin = self.proposed_admin
    self.proposed_admin = empty(address)


##### INTERNAL METHODS #####

@pure
@internal
def _compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
    """
    @dev An `internal` helper function that returns the address
         where a contract will be stored if deployed via `deployer`
         using the `CREATE2` opcode. Any change in the `bytecode_hash`
         or `salt` values will result in a new destination address.
    @param salt The 32-byte random value used to create the contract
           address.
    @param bytecode_hash The 32-byte bytecode digest of the contract
           creation bytecode.
    @param deployer The 20-byte deployer address.
    @return address The 20-byte address where a contract will be stored.
    """
    data: bytes32 = keccak256(concat(_COLLISION_OFFSET, convert(deployer, bytes20), salt, bytecode_hash))
    return self._convert_keccak256_2_address(data)


@pure
@internal
def _convert_keccak256_2_address(digest: bytes32) -> address:
    """
    @dev Converts a 32-byte keccak256 digest to an address.
    @param digest The 32-byte keccak256 digest.
    @return address The converted 20-byte address.
    """
    return convert(convert(digest, uint256) & convert(max_value(uint160), uint256), address)


@internal
def _create_vault_and_deposit(token_id: uint256, price: uint256, min_duration: uint256, max_duration: uint256, delegate: address) -> address:
    assert self.active_vaults[token_id] == empty(address), "vault exists for token_id"

    vault: address = create_minimal_proxy_to(vault_impl_addr, salt=convert(token_id, bytes32))

    self.active_vaults[token_id] = vault

    IVault(vault).initialise(msg.sender)
    IVault(vault).deposit(token_id, price, min_duration, max_duration, delegate)

    return vault


@internal
def _deposit_nft(token_id: uint256, price: uint256, min_duration: uint256, max_duration: uint256, delegate: address) -> address:
    assert ISelf(self).is_vault_available(token_id), "vault is not available"

    vault: address = ISelf(self).tokenid_to_vault(token_id)
    self.active_vaults[token_id] = vault

    IVault(vault).initialise(msg.sender)

    IVault(vault).deposit(token_id, price, min_duration, max_duration, delegate)

    return vault


##### EXTERNAL METHODS - VIEW #####

@view
@external
def is_vault_available(token_id: uint256) -> bool:

    """
    @notice Check if a vault is available for a given NFT token id.
    @dev Determines if a vault exists and is available, ie not in use.
    @param token_id The NFT token id to check.
    @return True if the vault is available, False otherwise.
    """

    vault: address = ISelf(self).tokenid_to_vault(token_id)
    return self.active_vaults[token_id] == empty(address) and vault.is_contract and not IVault(vault).is_initialised()


@view
@external
def tokenid_to_vault(token_id: uint256) -> address:

    """
    @notice Get the vault address for a given NFT token id.
    @dev Computes the address of the vault (existent or yet to be created) associated with the specified token id.
    @param token_id The NFT token id.
    @return The address of the vault associated with the given token id.
    """

    return self._compute_address(
        convert(token_id, bytes32),
        keccak256(concat(
            _DEPLOYMENT_CODE,
            _PRE,
            convert(vault_impl_addr, bytes20),
            _POST
        )),
        self
    )


@view
@external
def get_nft_contract() -> address:
    return nft_contract_addr


@view
@external
def get_payment_token() -> address:
    return payment_token_addr


@view
@external
def get_delegation_registry() -> address:
    return delegation_registry_addr