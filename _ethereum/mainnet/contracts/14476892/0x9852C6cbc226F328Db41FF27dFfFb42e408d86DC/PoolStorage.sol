// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";
import "./EnumerableSet.sol";

contract PoolStorageV1 {
    IERC20 public token; // Collateral token

    address public poolAccountant; // PoolAccountant address
    address public poolRewards; // PoolRewards contract address
    address private feeWhitelistObsolete; // Obsolete in favor of AddressSet of feeWhitelist
    address private keepersObsolete; // Obsolete in favor of AddressSet of keepers
    address private maintainersObsolete; // Obsolete in favor of AddressSet of maintainers
    address private feeCollectorObsolete; // Fee collector address. Obsolete as there is no fee to collect
    uint256 private withdrawFeeObsolete; // Withdraw fee for this pool. Obsolete in favor of universal fee
    uint256 public decimalConversionFactor; // It can be used in converting value to/from 18 decimals
    bool internal withdrawInETH; // This flag will be used by VETH pool as switch to withdraw ETH or WETH
}

contract PoolStorageV2 is PoolStorageV1 {
    EnumerableSet.AddressSet private _feeWhitelistObsolete; // Obsolete in favor of universal fee
    EnumerableSet.AddressSet internal _keepers; // List of keeper addresses
    EnumerableSet.AddressSet internal _maintainers; // List of maintainer addresses
}

abstract contract PoolStorageV3 is PoolStorageV2 {
    uint256 public universalFee; // Universal fee on this pool.
}
