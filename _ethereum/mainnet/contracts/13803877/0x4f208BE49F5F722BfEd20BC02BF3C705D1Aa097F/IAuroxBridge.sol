//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAuroxBridge {
    function registerSwap(
        address[] calldata thisTokenPath,
        address[] calldata targetTokenPath,
        uint256 amountIn,
        uint minAmountOut) external;
    function buyAssetOnBehalf(
        address[] calldata path,
        address userAddress,
        uint256 usdAmount,
        uint256 usdBalance) external;
    function issueOwnershipNft(
        address userAddress,
        address token,
        uint256 amount) external;

    event RegisterSwap(address, address, address, uint256, uint256);
    event BuyAssetOnBehalf(address, address, uint256, uint256);
}