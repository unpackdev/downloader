// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";

contract PoolStorageV1 {
    IERC20 public token; // Collateral token

    address public poolAccountant; // PoolAccountant address
    address public poolRewards; // PoolRewards contract address
    address public feeWhitelist; // sol-address-list address which contains whitelisted addresses to withdraw without fee
    address public keepers; // sol-address-list address which contains addresses of keepers
    address public maintainers; // sol-address-list address which contains addresses of maintainers
    address public feeCollector; // Fee collector address
    uint256 public withdrawFee; // Withdraw fee for this pool
    uint256 public decimalConversionFactor; // It can be used in converting value to/from 18 decimals
    bool internal withdrawInETH; // This flag will be used by VETH pool as switch to withdraw ETH or WETH
}
