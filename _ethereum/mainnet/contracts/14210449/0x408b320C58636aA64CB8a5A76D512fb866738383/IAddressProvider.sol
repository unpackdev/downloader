// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "ILiquidityPool.sol";
import "IPreparable.sol";
import "IGasBank.sol";
import "IOracleProvider.sol";

// solhint-disable ordering

interface IAddressProvider is IPreparable {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event PoolListed(address indexed pool);
    event PoolDelisted(address indexed pool);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function addKnownAddressKey(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function removePool(address pool) external returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (ILiquidityPool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function isAction(address action) external view returns (bool);

    /** Address functions */
    function getAddress(bytes32 key) external view returns (address);

    function prepareAddress(bytes32 key, address newAddress) external returns (bool);

    function executeAddress(bytes32 key) external returns (address);

    function resetAddress(bytes32 key) external returns (bool);

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external returns (bool);

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);

    /** BKD Locker functions */

    function getBKDLocker() external view returns (address);

    function setBKDLocker(address bkdLocker) external;
}
