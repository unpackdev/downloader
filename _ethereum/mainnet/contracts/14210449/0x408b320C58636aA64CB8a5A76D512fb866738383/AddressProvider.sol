// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IGasBank.sol";
import "IAddressProvider.sol";
import "IStakerVault.sol";
import "IOracleProvider.sol";

import "EnumerableExtensions.sol";
import "EnumerableMapping.sol";
import "AddressProviderKeys.sol";

import "Admin.sol";
import "Preparable.sol";

// solhint-disable ordering

contract AddressProvider is IAddressProvider, Admin, Preparable {
    using EnumerableMapping for EnumerableMapping.AddressToAddressMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableExtensions for EnumerableSet.AddressSet;
    using EnumerableExtensions for EnumerableSet.Bytes32Set;
    using EnumerableExtensions for EnumerableMapping.AddressToAddressMap;

    bytes32 internal constant _BKD_LOCKER = "BKDLocker";

    // LpToken -> stakerVault
    EnumerableMapping.AddressToAddressMap internal _stakerVaults;

    EnumerableSet.AddressSet internal _whiteListedFeeHandlers;

    EnumerableSet.Bytes32Set internal _knownAddressKeys;

    EnumerableSet.AddressSet internal _actions; // list of all actions ever registered

    EnumerableMapping.AddressToAddressMap internal _tokenToPools;

    constructor(
        address treasury,
        address vaultReserve,
        address gasBank,
        address oracleProvider
    ) Admin(msg.sender) {
        _setConfig(AddressProviderKeys._TREASURY_KEY, treasury);
        _setConfig(AddressProviderKeys._VAULT_RESERVE_KEY, vaultReserve);
        _setConfig(AddressProviderKeys._GAS_BANK_KEY, gasBank);
        _setConfig(AddressProviderKeys._ORACLE_PROVIDER_KEY, oracleProvider);

        addKnownAddressKey(AddressProviderKeys._TREASURY_KEY);
        addKnownAddressKey(AddressProviderKeys._VAULT_RESERVE_KEY);
        addKnownAddressKey(AddressProviderKeys._GAS_BANK_KEY);
        addKnownAddressKey(AddressProviderKeys._ORACLE_PROVIDER_KEY);
        addKnownAddressKey(AddressProviderKeys._SWAPPER_REGISTRY_KEY);
    }

    function addKnownAddressKey(bytes32 key) public onlyAdmin {
        require(_knownAddressKeys.add(key), Error.INVALID_ARGUMENT);
        emit KnownAddressKeyAdded(key);
    }

    function getKnownAddressKeys() external view returns (bytes32[] memory) {
        return _knownAddressKeys.toArray();
    }

    function addFeeHandler(address feeHandler) external onlyAdmin returns (bool) {
        require(!_whiteListedFeeHandlers.contains(feeHandler), Error.ADDRESS_WHITELISTED);
        _whiteListedFeeHandlers.add(feeHandler);
        return true;
    }

    function removeFeeHandler(address feeHandler) external onlyAdmin returns (bool) {
        require(_whiteListedFeeHandlers.contains(feeHandler), Error.ADDRESS_NOT_WHITELISTED);
        _whiteListedFeeHandlers.remove(feeHandler);
        return true;
    }

    /**
     * @notice Adds action.
     * @param action Address of action to add.
     */
    function addAction(address action) external onlyAdmin returns (bool) {
        bool result = _actions.add(action);
        if (result) {
            emit ActionListed(action);
        }
        return result;
    }

    /**
     * @notice Adds pool.
     * @param pool Address of pool to add.
     */
    function addPool(address pool) external override onlyAdmin {
        require(pool != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);

        ILiquidityPool ipool = ILiquidityPool(pool);
        address poolToken = ipool.getLpToken();
        if (_tokenToPools.set(poolToken, pool)) {
            emit PoolListed(pool);
        }
    }

    /**
     * @notice Delists pool.
     * @param pool Address of pool to delist.
     * @return `true` if successful.
     */
    function removePool(address pool) external override onlyAdmin returns (bool) {
        address lpToken = ILiquidityPool(pool).getLpToken();
        bool removed = _tokenToPools.remove(lpToken);
        if (removed) {
            emit PoolDelisted(pool);
        }

        return removed;
    }

    /**
     * @notice Returns the address for the given key
     */
    function getAddress(bytes32 key) external view returns (address) {
        require(_knownAddressKeys.contains(key), Error.INVALID_ARGUMENT);
        return currentAddresses[key];
    }

    /**
     * @notice Prepare update of an address
     * @param key Key to update
     * @param newAddress New address for `key`
     * @return `true` if successful.
     */
    function prepareAddress(bytes32 key, address newAddress)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(_knownAddressKeys.contains(key), Error.INVALID_ARGUMENT);
        return _prepare(key, newAddress);
    }

    /**
     * @notice Execute update of `key`
     * @return New address.
     */
    function executeAddress(bytes32 key) external override returns (address) {
        require(_knownAddressKeys.contains(key), Error.INVALID_ARGUMENT);
        return _executeAddress(key);
    }

    /**
     * @notice Reset `key`
     * @return true if it was reset
     */
    function resetAddress(bytes32 key) external onlyAdmin returns (bool) {
        return _resetAddressConfig(key);
    }

    /**
     * @notice Add a new staker vault and add it's lpGauge if set in vault.
     * @dev This fails if the token of the staker vault is the token of an existing staker vault.
     * @param stakerVault Vault to add.
     * @return `true` if successful.
     */
    function addStakerVault(address stakerVault) external override onlyAdmin returns (bool) {
        address token = IStakerVault(stakerVault).getToken();
        require(token != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        require(!_stakerVaults.contains(token), Error.STAKER_VAULT_EXISTS);
        _stakerVaults.set(token, stakerVault);
        emit StakerVaultListed(stakerVault);
        return true;
    }

    /**
     * @notice Set the BKD locker
     * @dev this can only be done once and the change is permanent
     */
    function setBKDLocker(address bkdLocker) external override onlyAdmin {
        require(getBKDLocker() == address(0), Error.ADDRESS_ALREADY_SET);
        _setConfig(_BKD_LOCKER, bkdLocker);
    }

    function isWhiteListedFeeHandler(address feeHandler) external view override returns (bool) {
        return _whiteListedFeeHandlers.contains(feeHandler);
    }

    /**
     * @notice Get the liquidity pool for a given token
     * @dev Does not revert if the pool deos not exist
     * @param token Token for which to get the pool.
     * @return Pool address.
     */
    function safeGetPoolForToken(address token) external view override returns (ILiquidityPool) {
        (, address poolAddress) = _tokenToPools.tryGet(token);
        return ILiquidityPool(poolAddress);
    }

    /**
     * @notice Get the liquidity pool for a given token
     * @dev Reverts if the pool deos not exist
     * @param token Token for which to get the pool.
     * @return Pool address.
     */
    function getPoolForToken(address token) external view override returns (ILiquidityPool) {
        (bool exists, address poolAddress) = _tokenToPools.tryGet(token);
        require(exists, Error.ADDRESS_NOT_FOUND);
        return ILiquidityPool(poolAddress);
    }

    /**
     * @notice Get list of all action addresses.
     * @return Array with action addresses.
     */
    function allActions() external view override returns (address[] memory) {
        return _actions.toArray();
    }

    /**
     * @notice Check whether an address is an action.
     * @param action Address to check whether it is action.
     * @return True if address is an action.
     */
    function isAction(address action) external view override returns (bool) {
        return _actions.contains(action);
    }

    /**
     * @notice Get list of all pool addresses.
     * @return Array with pool addresses.
     */
    function allPools() external view override returns (address[] memory) {
        return _tokenToPools.valuesArray();
    }

    /**
     * @notice Returns all the staker vaults.
     */
    function allStakerVaults() external view override returns (address[] memory) {
        return _stakerVaults.valuesArray();
    }

    /**
     * @notice Get the staker vault for a given token
     * @dev There can only exist one staker vault per unique token.
     * @param token Token for which to get the vault.
     * @return Vault address.
     */
    function getStakerVault(address token) external view override returns (address) {
        return _stakerVaults.get(token);
    }

    /**
     * @notice Tries to get the staker vault for a given token but does not throw if it does not exist
     * @return A boolean set to true if the vault exists and the vault address.
     */
    function tryGetStakerVault(address token) external view override returns (bool, address) {
        return _stakerVaults.tryGet(token);
    }

    /**
     * @notice Check if a vault is registered (exists).
     * @param stakerVault Address of staker vault to check.
     * @return `true` if registered, `false` if not.
     */
    function isStakerVaultRegistered(address stakerVault) external view override returns (bool) {
        address token = IStakerVault(stakerVault).getToken();
        return isStakerVault(stakerVault, token);
    }

    function isStakerVault(address stakerVault, address token) public view override returns (bool) {
        (bool exists, address vault) = _stakerVaults.tryGet(token);
        return exists && vault == stakerVault;
    }

    /**
     * @return the address of the BKD locker
     */
    function getBKDLocker() public view override returns (address) {
        return currentAddresses[_BKD_LOCKER];
    }
}
