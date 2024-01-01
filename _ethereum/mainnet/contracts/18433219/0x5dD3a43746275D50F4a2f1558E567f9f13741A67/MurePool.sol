// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.21;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./IERC20.sol";
import "./SignatureChecker.sol";
import "./Poolable.sol";
import "./Depositable.sol";
import "./Refundable.sol";

contract MurePool is
    EIP712Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    Poolable,
    Depositable,
    Refundable
{
    /// @custom:storage-location erc7201:mure.MurePool
    struct MurePoolStorage {
        mapping(string => PoolState) pools;
        mapping(string => mapping(address => DepositRecord)) deposits;
    }

    /**
     * @dev Struct hash for storage location
     * `keccak256(abi.encode(uint256(keccak256("mure.MurePool")) - 1)) & ~bytes32(uint256(0xff))`
     */
    bytes32 private constant MurePoolStorageLocation =
        0x79bd164051f83036bb52eee1d9b6be5ba887eaf3a9d8907adbaadfa56c970700;

    /**
     * @dev Struct hash for validating deposits
     * `keccak256("Deposit(uint256 amount,string pool,address depositor,uint8 nonce)")`
     */
    bytes32 private constant DEPOSIT_HASH = 0xc5b44054231c7194afce4ed4062c5abd2c0cb26e0686f9ba69d2cfc04b490e33;

    /**
     * @dev Defines if the pool is initialized
     */
    uint16 constant INITIALIZED = 0x01;

    /**
     * @dev Defines if the pool is paused from any interaction
     */
    uint16 constant PAUSED = 0x02;

    /**
     * @dev Defines if deposits should pass straight to associtated raising wallet upon deposit
     * @notice `PASSTHROUGH_FUNDS` and `REFUNDABLE` cannot be set at the same time
     */
    uint16 constant PASSTHROUGH_FUNDS = 0x04;

    /**
     * @dev Defines if the pool is open for claiming refunds
     * @notice `PASSTHROUGH_FUNDS` and `REFUNDABLE` cannot be set at the same time
     */
    uint16 constant REFUNDABLE = 0x08;

    /**
     * @dev Defines if the pool is having tiers and gating
     */
    uint16 constant TIERED = 0x10;

    /**
     * @dev Defines if the pool is cross-chain enabled, pooling funds across different networks
     */
    uint16 constant CROSS_CHAIN = 0x20;

    /**
     * @dev Defines if the pool allows for use of delegated wallets for security
     */
    uint16 constant DELEGATED = 0x40;

    modifier poolValid(string calldata poolName) {
        if (!_poolExists(poolName)) {
            revert PoolNotFound();
        }
        _;
    }

    modifier poolActive(string calldata poolName) {
        MurePoolStorage storage storage_ = _getStorage();
        if (_hasFlag(storage_.pools[poolName].flags, PAUSED)) {
            revert PoolPaused();
        }
        if (_poolComplete(poolName)) {
            revert PoolClosed();
        }
        _;
    }

    modifier poolNotPaused(string calldata poolName) {
        MurePoolStorage storage storage_ = _getStorage();
        if (_hasFlag(storage_.pools[poolName].flags, PAUSED)) {
            revert PoolPaused();
        }
        _;
    }

    modifier valid(PoolParameters calldata params) {
        _verifyParams(params);
        _;
    }

    function initialize(string calldata name, string calldata version, address owner) external initializer {
        __EIP712_init(name, version);
        __Ownable_init(owner);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    /**
     * @notice Creates a new pool with the specified parameters.
     * @dev Requires the pool to not already exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to create
     * @param params the parameters for the new pool
     */
    function createPool(string calldata poolName, PoolParameters calldata params) external onlyOwner valid(params) {
        if (_poolExists(poolName)) {
            revert PoolInitialized();
        }

        MurePoolStorage storage storage_ = _getStorage();
        storage_.pools[poolName] = PoolState({
            poolSize: params.poolSize,
            totalCollected: 0,
            endTime: params.endTime,
            signer: params.signer,
            depositors: 0,
            currency: params.currency,
            custodian: params.custodian,
            flags: params.flags | INITIALIZED // Ensure pool is always marked as `initialized`
        });

        emit PoolCreation(poolName);
    }

    /**
     * @notice Updates the specified pool with the provided parameters.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @dev Requires the updated pool size to be greater than or equal to the total amount collected.
     * @param poolName the name of the pool to update
     * @param params the updated parameters for the pool
     */
    function updatePool(string calldata poolName, PoolParameters calldata params)
        external
        onlyOwner
        valid(params)
        poolValid(poolName)
    {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage state_ = storage_.pools[poolName];

        if (params.poolSize < state_.totalCollected) {
            revert IllegalPoolState(PoolParameter.POOL_SIZE);
        }

        if (
            state_.totalCollected > 0
                && _hasFlag(state_.flags, PASSTHROUGH_FUNDS) != _hasFlag(params.flags, PASSTHROUGH_FUNDS)
        ) {
            revert IllegalPoolOperation(PoolErrorReason.ALREADY_INVESTED_POOL);
        }

        state_.poolSize = params.poolSize;
        state_.endTime = params.endTime;
        state_.signer = params.signer;
        state_.currency = params.currency;
        state_.custodian = params.custodian;
        state_.flags = params.flags | INITIALIZED; // Ensure pool is always marked as `initialized`

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Updates the size of the specified pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @dev Requires the new pool size to be greater than or equal to the total amount collected.
     * @param poolName the name of the pool to update
     * @param poolSize the updated size of the pool
     */
    function updatePoolSize(string calldata poolName, uint256 poolSize) external onlyOwner poolValid(poolName) {
        MurePoolStorage storage storage_ = _getStorage();

        if (storage_.pools[poolName].totalCollected > poolSize) {
            revert IllegalPoolState(PoolParameter.POOL_SIZE);
        }

        storage_.pools[poolName].poolSize = uint112(poolSize);

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Updates the end time of the specified pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to update
     * @param endTime the updated end time for the pool
     */
    function updatePoolEndTime(string calldata poolName, uint256 endTime) external onlyOwner poolValid(poolName) {
        if (endTime < block.timestamp) {
            revert IllegalPoolState(PoolParameter.END_TIME);
        }

        MurePoolStorage storage storage_ = _getStorage();
        storage_.pools[poolName].endTime = uint32(endTime);

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Updates the signer of the specified pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to update
     * @param _signer the updated signer for the pool
     */
    function updatePoolSigner(string calldata poolName, address _signer) external onlyOwner poolValid(poolName) {
        if (_signer == address(0)) {
            revert IllegalPoolState(PoolParameter.SIGNER);
        }

        MurePoolStorage storage storage_ = _getStorage();
        storage_.pools[poolName].signer = _signer;

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Pauses or unpauses the specified pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to pause or unpause
     * @param pause a boolean representing whether to pause or unpause the pool
     */
    function updatePoolPaused(string calldata poolName, bool pause) external onlyOwner poolValid(poolName) {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage pool = storage_.pools[poolName];

        pool.flags = pause ? _activateFlag(pool.flags, PAUSED) : _deactivateFlag(pool.flags, PAUSED);

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Updates whether the specified pool allows refunds or not.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @dev Requires that the pool does not have the `PASSTHROUGH_FUNDS` flag set if enabling refunds.
     * @param poolName the name of the pool to update
     * @param refundable a boolean representing whether refunds should be enabled or not
     */
    function updatePoolRefundable(string calldata poolName, bool refundable) external onlyOwner poolValid(poolName) {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage pool = storage_.pools[poolName];

        if (_hasFlag(pool.flags, PASSTHROUGH_FUNDS) && refundable) {
            revert IllegalPoolState(PoolParameter.FLAGS);
        }

        pool.flags = refundable ? _activateFlag(pool.flags, REFUNDABLE) : _deactivateFlag(pool.flags, REFUNDABLE);

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Updates whether the specified pool passes funds through to the custodian directly or not.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @dev Requires that the pool does not have the `REFUNDABLE` flag set if enabling passthrough funds.
     * @param poolName the name of the pool to update
     * @param passthroughFunds a boolean representing whether to enable passthrough funds or not
     */
    function updatePoolPassthroughFunds(string calldata poolName, bool passthroughFunds)
        external
        onlyOwner
        poolValid(poolName)
    {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage pool = storage_.pools[poolName];

        if (_hasFlag(pool.flags, REFUNDABLE) && passthroughFunds) {
            revert IllegalPoolState(PoolParameter.FLAGS);
        }

        if (pool.totalCollected > 0) {
            revert IllegalPoolOperation(PoolErrorReason.ALREADY_INVESTED_POOL);
        }

        pool.flags = passthroughFunds
            ? _activateFlag(pool.flags, PASSTHROUGH_FUNDS)
            : _deactivateFlag(pool.flags, PASSTHROUGH_FUNDS);

        emit PoolUpdate(poolName);
    }

    /**
     * @notice Withdraws the total collected amount from the specified pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to withdraw from
     */
    function withdrawPoolFunds(string calldata poolName) external onlyOwner poolValid(poolName) {
        if (!_poolComplete(poolName)) {
            revert PoolOpen();
        }

        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage pool = storage_.pools[poolName];

        if (_hasFlag(pool.flags, PASSTHROUGH_FUNDS)) {
            revert IllegalPoolOperation(PoolErrorReason.INVALID_POOL_TYPE);
        }

        IERC20 currency = IERC20(pool.currency);

        currency.transfer(address(pool.custodian), pool.totalCollected);

        emit Withdrawal(poolName, pool.totalCollected, address(pool.custodian));
    }

    /**
     * @notice Withdraw any token from the contract. This should only be used in emergencies
     * as this can withdraw capital from any pool, be it active or not. Always prefer using `withdraw`
     * over this function, unless you need clean up the contract by, e.g., burning garbage tokens.
     * @param receiver the address to which the token will be transferred
     * @param currency the address of the token contract
     */
    function withdrawCurrency(address receiver, address currency) external onlyOwner {
        IERC20 currency_ = IERC20(currency);
        uint256 balance = currency_.balanceOf(address(this));
        currency_.transfer(receiver, balance);
    }

    /**
     * @notice Adds a deposit of the specified amount to the pool for the designated depositor.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to add the deposit to
     * @param depositor the address of the depositor
     * @param amount the amount of the deposit
     */
    function addDeposit(string calldata poolName, address depositor, uint256 amount)
        external
        onlyOwner
        poolValid(poolName)
    {
        _addDeposit(poolName, depositor, amount);
    }

    /**
     * @notice Deducts the specified amount from the deposit of the designated depositor in the pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to deduct the deposit from
     * @param depositor the address of the depositor
     * @param amount the amount to deduct
     */
    function deductDeposit(string calldata poolName, address depositor, uint256 amount)
        external
        onlyOwner
        poolValid(poolName)
    {
        _deductDeposit(poolName, depositor, amount);
    }

    /**
     * @notice Moves the specified amount from one depositor's deposit to another in the pool.
     * @dev Requires the pool to exist. Can only be called by the contract owner.
     * @param poolName the name of the pool to move the deposit in
     * @param from the address of the depositor to deduct the deposit from
     * @param to the address of the depositor to add the deposit to
     * @param amount the amount to move
     */
    function moveDeposit(string calldata poolName, address from, address to, uint256 amount)
        external
        onlyOwner
        poolValid(poolName)
    {
        _deductDeposit(poolName, from, amount);
        _addDeposit(poolName, to, amount);
    }

    /**
     * @notice Deposits `amount` of the relevant currency for the pool `poolName`.
     * This operation assumes that the contract is an approved spender of the depositor.
     *
     * @param poolName bytes32 representation of the pool name
     * @param amount the amount the user want to invest. Need that for accounting
     * @param sig the signatures generated for the user, including the amount.
     * and verifying the signature.
     */
    function deposit(string calldata poolName, uint256 amount, bytes memory sig)
        external
        whenNotPaused
        nonReentrant
        poolValid(poolName)
        poolActive(poolName)
    {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage pool = storage_.pools[poolName];

        if (!SignatureChecker.isValidSignatureNow(pool.signer, _hash(amount, poolName), sig)) {
            revert Unauthorized();
        }

        address destinationAddress = _hasFlag(pool.flags, PASSTHROUGH_FUNDS) ? pool.custodian : address(this);

        _addDeposit(poolName, _msgSender(), amount);

        _transferUpdate(_msgSender(), destinationAddress, amount, pool.currency);
    }

    /**
     * @notice Allows a user to refund their deposited amount from the specified pool.
     * @dev Requires the pool to exist.
     * @dev Requires the pool to be not paused and must have the `REFUNDABLE` flag set.
     * @param poolName the name of the pool from which to refund
     */
    function refund(string calldata poolName)
        external
        nonReentrant
        whenNotPaused
        poolNotPaused(poolName)
        poolValid(poolName)
    {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage pool = storage_.pools[poolName];

        if (!_hasFlag(pool.flags, REFUNDABLE)) revert Unauthorized();

        uint256 amount = storage_.deposits[poolName][_msgSender()].amount;

        if (amount == 0) revert DepositNotFound();

        _deductDeposit(poolName, _msgSender(), amount);

        _transferUpdate(address(this), _msgSender(), amount, pool.currency);

        emit Refund(poolName, amount, _msgSender());
    }

    /**
     * @notice Retrieves the state of the specified pool.
     * @dev Requires the pool to exist.
     * @param poolName the name of the pool to retrieve the state of
     */
    function poolState(string calldata poolName) external view poolValid(poolName) returns (PoolState memory) {
        MurePoolStorage storage storage_ = _getStorage();
        return storage_.pools[poolName];
    }

    /**
     * @notice Retrieves the amount deposited by the specified depositor in the specified pool.
     * @dev Requires the pool to exist.
     * @param poolName the name of the pool to retrieve the deposit from
     * @param depositor the address of the depositor
     */
    function deposited(string calldata poolName, address depositor)
        external
        view
        poolValid(poolName)
        returns (uint256)
    {
        MurePoolStorage storage storage_ = _getStorage();
        return storage_.deposits[poolName][depositor].amount;
    }

    /**
     * @notice Retrieves the nonce of the specified depositor in the specified pool.
     * @dev Requires the pool to exist.
     * @param poolName the name of the pool to retrieve the nonce from
     * @param depositor the address of the depositor
     */
    function nonce(string calldata poolName, address depositor) external view poolValid(poolName) returns (uint8) {
        MurePoolStorage storage storage_ = _getStorage();
        return storage_.deposits[poolName][depositor].nonce;
    }

    /**
     * @notice Checks if the specified pool exists.
     * @param pool the name of the pool to check for existence
     */
    function poolExists(string calldata pool) external view returns (bool) {
        return _poolExists(pool);
    }

    /**
     * @dev Adds deposit `amount` to designated `poolName` under `depositor`.
     * As `totalCollected` is bound by `poolSize`, overflow is not possible unless `poolSize`
     * is in a disallowed state to begin with.
     */
    function _addDeposit(string calldata poolName, address depositor, uint256 amount) private {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage state_ = storage_.pools[poolName];
        DepositRecord storage deposit_ = storage_.deposits[poolName][depositor];

        if (state_.totalCollected + amount > state_.poolSize) revert PoolFull();
        unchecked {
            deposit_.amount += uint112(amount);
            ++deposit_.nonce;
            state_.totalCollected += uint112(amount);
            if (deposit_.amount == uint112(amount)) {
                ++state_.depositors;
            }
        }

        emit Deposit(poolName, amount, depositor);
    }

    /**
     * @dev Deducts deposit `amount` from designated `poolName` under `depositor`.
     * As `totalCollected` is the cumulative sum of all `depositor`s under `poolName`,
     * underflow is not possible unless `totalCollected` is in a disallowed state to begin with.
     */
    function _deductDeposit(string calldata poolName, address depositor, uint256 amount) private {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage state_ = storage_.pools[poolName];
        DepositRecord storage deposit_ = storage_.deposits[poolName][depositor];

        if (deposit_.amount < amount) {
            revert PoolError(PoolErrorReason.ARITHMETIC_OUT_OF_BOUNDS);
        }
        unchecked {
            deposit_.amount -= uint112(amount);
            ++deposit_.nonce;
            state_.totalCollected -= uint112(amount);
            if (deposit_.amount == 0) {
                --state_.depositors;
            }
        }

        emit Withdrawal(poolName, amount, depositor);
    }

    /**
     * @dev Updates the transfer between two addresses with a specified amount of a given currency.
     * @param from the address from which the transfer is initiated
     * @param to the address to which the transfer is made
     * @param amount the amount of the currency being transferred
     * @param currency the address of the currency being transferred
     */
    function _transferUpdate(address from, address to, uint256 amount, address currency) private {
        IERC20 currency_ = IERC20(currency);
        bool success;
        if (from == address(this)) success = currency_.transfer(to, amount);
        else success = currency_.transferFrom(from, to, amount);

        if (!success) {
            revert PoolError(PoolErrorReason.TRANSFER_FAILURE);
        }
    }

    /**
     * @dev Checks whether a pool with the specified name exists.
     * @param pool the name of the pool being checked
     */
    function _poolExists(string calldata pool) private view returns (bool) {
        MurePoolStorage storage storage_ = _getStorage();
        return _hasFlag(storage_.pools[pool].flags, INITIALIZED);
    }

    /**
     * @dev Verifies the validity of the specified pool parameters.
     * @param config the parameters of the pool being verified
     */
    function _verifyParams(PoolParameters calldata config) private view {
        if (config.endTime < block.timestamp) {
            revert IllegalPoolState(PoolParameter.END_TIME);
        }
        if (config.signer == address(0)) {
            revert IllegalPoolState(PoolParameter.SIGNER);
        }
        if (config.currency == address(0)) {
            revert IllegalPoolState(PoolParameter.CURRENCY);
        }
        if (config.custodian == address(0)) {
            revert IllegalPoolState(PoolParameter.CUSTODIAN);
        }
        if (_hasFlag(config.flags, PASSTHROUGH_FUNDS) && _hasFlag(config.flags, REFUNDABLE)) {
            revert IllegalPoolState(PoolParameter.FLAGS);
        }
    }

    /**
     * @dev Checks whether the specified pool has been completed.
     * @param poolName the name of the pool being checked
     */
    function _poolComplete(string calldata poolName) private view returns (bool) {
        MurePoolStorage storage storage_ = _getStorage();
        PoolState storage state_ = storage_.pools[poolName];
        return state_.totalCollected == state_.poolSize || state_.endTime < block.timestamp;
    }

    /**
     * @dev Generates a hashed representation of the specified amount and pool name, along with the sender's nonce.
     * @param amount the amount of the deposit
     * @param poolName the name of the pool
     */
    function _hash(uint256 amount, string calldata poolName) private view returns (bytes32) {
        MurePoolStorage storage storage_ = _getStorage();
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    DEPOSIT_HASH,
                    amount,
                    keccak256(bytes(poolName)),
                    _msgSender(),
                    storage_.deposits[poolName][_msgSender()].nonce
                )
            )
        );
    }

    /**
     * @dev Checks whether a specific flag is activated within a set of flags.
     * @param flags the set of flags being checked
     * @param flag the flag being checked for activation
     */
    function _hasFlag(uint16 flags, uint16 flag) private pure returns (bool) {
        return flags & flag != 0;
    }

    /**
     * @dev Activates the specified flag within a set of flags.
     * @param flags the set of flags being modified
     * @param flag the flag being activated
     */
    function _activateFlag(uint16 flags, uint16 flag) private pure returns (uint16) {
        return flags | flag;
    }

    /**
     * @dev Deactivates the specified flag within a set of flags.
     * @param flags the set of flags being modified
     * @param flag the flag being deactivated
     */
    function _deactivateFlag(uint16 flags, uint16 flag) private pure returns (uint16) {
        return flags & ~flag;
    }

    /**
     * @dev Retrieves the storage for the MurePool contract.
     */
    function _getStorage() private pure returns (MurePoolStorage storage $) {
        assembly {
            $.slot := MurePoolStorageLocation
        }
    }
}
