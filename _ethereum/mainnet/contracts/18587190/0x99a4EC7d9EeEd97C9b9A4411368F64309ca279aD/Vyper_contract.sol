# @version 0.3.9

# Interfaces

interface ISelf:
    def tokenid_to_vault(token_id: uint256) -> address: view
    def is_vault_available(token_id: uint256) -> bool: view


interface IVault:
    def is_initialised() -> bool: view
    def initialise(owner: address, payment_token_addr: address, nft_contract_addr: address, delegation_registry_addr: address): nonpayable
    def deposit(token_id: uint256, price: uint256, min_duration: uint256, max_duration: uint256): nonpayable
    def set_listing(sender: address, price: uint256, min_duration: uint256, max_duration: uint256): nonpayable
    def set_listing_and_delegate_to_owner(sender: address, price: uint256, min_duration: uint256, max_duration: uint256): nonpayable
    def start_rental(renter: address, expiration: uint256) -> Rental: nonpayable
    def close_rental(sender: address) -> (Rental, uint256): nonpayable
    def claim(sender: address) -> uint256: nonpayable
    def withdraw(sender: address) -> uint256: nonpayable
    def delegate_to_owner(sender: address): nonpayable
    def owner() -> address: view


# Structs

struct Rental:
    id: bytes32 # keccak256 of the renter, token_id, start and expiration
    owner: address
    renter: address
    token_id: uint256
    start: uint256
    min_expiration: uint256
    expiration: uint256
    amount: uint256

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

struct RewardLog:
    vault: address
    token_id: uint256
    amount: uint256

struct WithdrawalLog:
    vault: address
    token_id: uint256
    rewards: uint256


# Events

event VaultsCreated:
    owner: address
    nft_contract: address
    min_duration: uint256
    max_duration: uint256
    price: uint256
    vaults: DynArray[VaultLog, 32]

event NftsDeposited:
    owner: address
    nft_contract: address
    min_duration: uint256
    max_duration: uint256
    price: uint256
    vaults: DynArray[VaultLog, 32]

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

event ListingsCancelled:
    owner: address
    nft_contract: address
    vaults: DynArray[VaultLog, 32]

event RentalStarted:
    renter: address
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


# Global Variables

_COLLISION_OFFSET: constant(bytes1) = 0xFF
_DEPLOYMENT_CODE: constant(bytes9) = 0x602D3D8160093D39F3
_PRE: constant(bytes10) = 0x363d3d373d3d3d363d73
_POST: constant(bytes15) = 0x5af43d82803e903d91602b57fd5bf3

vault_impl_addr: public(immutable(address))
payment_token_addr: public(immutable(address))
nft_contract_addr: public(immutable(address))
delegation_registry_addr: public(immutable(address))

active_vaults: public(HashMap[uint256, address]) # token_id -> vault


##### EXTERNAL METHODS - WRITE #####

@external
def __init__(
    _vault_impl_addr: address,
    _payment_token_addr: address,
    _nft_contract_addr: address,
    _delegation_registry_addr: address
):
    vault_impl_addr = _vault_impl_addr
    payment_token_addr = _payment_token_addr
    nft_contract_addr = _nft_contract_addr
    delegation_registry_addr = _delegation_registry_addr


@external
def create_vaults_and_deposit(token_ids: DynArray[uint256, 32], price: uint256, min_duration: uint256, max_duration: uint256):
    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self._create_vault_and_deposit(token_id, price, min_duration, max_duration)
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
        vault_logs
    )


@external
def deposit(token_ids: DynArray[uint256, 32], price: uint256, min_duration: uint256, max_duration: uint256):
    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self._deposit_nft(token_id, price, min_duration, max_duration)
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
        vault_logs
    )


@external
def set_listings(token_ids: DynArray[uint256, 32], price: uint256, min_duration: uint256, max_duration: uint256):
    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).set_listing(msg.sender, price, min_duration, max_duration)

        vault_logs.append(VaultLog({
            vault: vault,
            token_id: token_id
        }))

    log ListingsChanged(
        msg.sender,
        nft_contract_addr,
        min_duration,
        max_duration,
        price,
        vault_logs
    )


@external
def set_listings_and_delegate_to_owner(token_ids: DynArray[uint256, 32], price: uint256, min_duration: uint256, max_duration: uint256):
    vault_logs: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).set_listing_and_delegate_to_owner(msg.sender, price, min_duration, max_duration)

        vault_logs.append(VaultLog({
            vault: vault,
            token_id: token_id
        }))

    log ListingsChanged(
        msg.sender,
        nft_contract_addr,
        min_duration,
        max_duration,
        price,
        vault_logs
    )

@external
def cancel_listings(token_ids: DynArray[uint256, 32]):
    vaults: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).set_listing(msg.sender, 0, 0, 0)

        vaults.append(VaultLog({
            vault: vault,
            token_id: token_id
        }))

    log ListingsCancelled(
        msg.sender,
        nft_contract_addr,
        vaults
    )


@external
def cancel_listings_and_delegate_to_owner(token_ids: DynArray[uint256, 32]):
    vaults: DynArray[VaultLog, 32] = empty(DynArray[VaultLog, 32])

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).set_listing_and_delegate_to_owner(msg.sender, 0, 0, 0)

        vaults.append(VaultLog({
            vault: vault,
            token_id: token_id
        }))

    log ListingsCancelled(
        msg.sender,
        nft_contract_addr,
        vaults
    )


@external
def start_rentals(token_ids: DynArray[uint256, 32], duration: uint256):
    rental_logs: DynArray[RentalLog, 32] = []

    expiration: uint256 = block.timestamp + duration * 3600

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        rental: Rental = IVault(vault).start_rental(msg.sender, expiration)

        rental_logs.append(RentalLog({
            id: rental.id,
            vault: vault,
            owner: rental.owner,
            token_id: token_id,
            start: rental.start,
            min_expiration: rental.min_expiration,
            expiration: expiration,
            amount: rental.amount
        }))

    log RentalStarted(msg.sender, nft_contract_addr, rental_logs)


@external
def close_rentals(token_ids: DynArray[uint256, 32]):

    amount: uint256 = 0
    rental: Rental = empty(Rental)
    rental_logs: DynArray[RentalLog, 32] = []

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        rental, amount = IVault(vault).close_rental(msg.sender)

        rental_logs.append(RentalLog({
            id: rental.id,
            vault: vault,
            owner: rental.owner,
            token_id: token_id,
            start: rental.start,
            min_expiration: rental.min_expiration,
            expiration: block.timestamp,
            amount: amount
        }))

    log RentalClosed(msg.sender, nft_contract_addr, rental_logs)


@external
def claim(token_ids: DynArray[uint256, 32]):
    reward_logs: DynArray[RewardLog, 32] = []

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        rewards: uint256 = IVault(vault).claim(msg.sender)

        reward_logs.append(RewardLog({
            vault: vault,
            token_id: token_id,
            amount: rewards
        }))

    log RewardsClaimed(msg.sender, nft_contract_addr, reward_logs)


@external
def withdraw(token_ids: DynArray[uint256, 32]):
    withdrawal_log: DynArray[WithdrawalLog, 32] = empty(DynArray[WithdrawalLog, 32])
    total_rewards: uint256 = 0

    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        self.active_vaults[token_id] = empty(address)

        rewards: uint256 = IVault(vault).withdraw(msg.sender)

        withdrawal_log.append(WithdrawalLog({
            vault: vault,
            token_id: token_id,
            rewards: rewards
        }))
        total_rewards += rewards

    log NftsWithdrawn(
        msg.sender,
        nft_contract_addr,
        total_rewards,
        withdrawal_log
    )

@external
def delegate_to_owner(token_ids: DynArray[uint256, 32]):
    for token_id in token_ids:
        vault: address = self.active_vaults[token_id]
        assert vault != empty(address), "no vault exists for token_id"

        IVault(vault).delegate_to_owner(msg.sender)



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
def _create_vault_and_deposit(token_id: uint256, price: uint256, min_duration: uint256, max_duration: uint256) -> address:
    assert self.active_vaults[token_id] == empty(address), "vault exists for token_id"

    vault: address = create_minimal_proxy_to(vault_impl_addr, salt=convert(token_id, bytes32))

    self.active_vaults[token_id] = vault

    IVault(vault).initialise(
        msg.sender,
        payment_token_addr,
        nft_contract_addr,
        delegation_registry_addr
    )
    IVault(vault).deposit(token_id, price, min_duration, max_duration)

    return vault


@internal
def _deposit_nft(token_id: uint256, price: uint256, min_duration: uint256, max_duration: uint256) -> address:
    assert ISelf(self).is_vault_available(token_id), "vault is not available"

    vault: address = ISelf(self).tokenid_to_vault(token_id)
    self.active_vaults[token_id] = vault

    IVault(vault).initialise(
        msg.sender,
        payment_token_addr,
        nft_contract_addr,
        delegation_registry_addr
    )

    IVault(vault).deposit(token_id, price, min_duration, max_duration)

    return vault


##### EXTERNAL METHODS - VIEW #####

@view
@external
def is_vault_available(token_id: uint256) -> bool:
    vault: address = ISelf(self).tokenid_to_vault(token_id)
    return self.active_vaults[token_id] == empty(address) and vault.is_contract and not IVault(vault).is_initialised()


@view
@external
def tokenid_to_vault(token_id: uint256) -> address:
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