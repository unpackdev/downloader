// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IERC4626ETH is IERC20, IERC20Metadata {
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function convertToShares(
        uint256 assets
    ) external view returns (uint256 shares);

    function convertToAssets(
        uint256 shares
    ) external view returns (uint256 assets);

    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets);

    function previewDeposit(
        uint256 assets
    ) external view returns (uint256 shares);

    function deposit(
        address receiver
    ) external payable returns (uint256 shares);

    function maxRedeem(address owner) external view returns (uint256 maxShares);

    function previewRedeem(
        uint256 shares
    ) external view returns (uint256 assets);

    function redeem(
        uint256 shares,
        address payable receiver,
        address owner
    ) external returns (uint256 assets);
}
