// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IMaster {
    function haircutRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function merchantFeeTo() external view returns (address);

    function whitelistEndTime() external view returns (uint256);

    function getTokens() external view returns (address[] memory);

    function addressOfAsset(address token) external view returns (address);

    function feesCollected(address token) external view returns (uint256);

    function buy(address token, uint256 amount, uint256 maxAmount, address to, uint256 deadline) external returns (uint256 finalAmount);

    function sell(address token, uint256 amount, uint256 minAmount, address to, uint256 deadline) external returns (uint256 finalAmount);

    function redeem(address token, uint256 deadline) external returns (uint256 tokenAmount);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 amount
    ) external view returns (uint256 quote, uint256 haircut);

    function mintFee(address token) external;
}
