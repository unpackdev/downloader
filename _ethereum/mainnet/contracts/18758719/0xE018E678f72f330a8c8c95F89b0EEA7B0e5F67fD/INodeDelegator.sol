// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./IStrategy.sol";

interface INodeDelegator {
    // event
    event AssetDepositIntoStrategy(address indexed asset, address indexed strategy, uint256 depositAmount);

    // errors
    error TokenTransferFailed();
    error StrategyIsNotSetForAsset();

    // methods
    function depositAssetIntoStrategy(address asset) external;

    function maxApproveToEigenStrategyManager(address asset) external;

    function getAssetBalances() external view returns (address[] memory, uint256[] memory);

    function getAssetBalance(address asset) external view returns (uint256);
}
