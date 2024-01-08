// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct IncreasePositionWithFlashswapParams {
    uint256 principalAmount; // Amount that will be used as principal
    uint256 minimumSupplyAmount; // Minimum amount expected to be supplied (enforce slippage here)
    uint256 borrowAmount; // Amount that will be borrowed to pay the flashswap
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    uint24 fee; // Selector of Uniswap Pool to flash
}

struct DecreasePositionWithFlashswapParams {
    uint256 redeemAmount; // Total amount of supply token that will be redeemed from position to repay flash and withdraw to user
    uint256 maximumFlashAmount; // Amount of supply token that will be redeemed to repay the flash
    uint256 repayAmount; // Amount of borrowToken that will be repaid with maximumFlashAmount
    address platform; // Lending platform
    address supplyToken; // Token to be supplied
    address borrowToken; // Token to be borrowed
    uint24 fee; // Selector of Uniswap Pool to flash
}

// Struct that is received by UniswapV3SwapCallback
struct SwapCallbackDataParams {
    bool increasePosition; // Whether to increase position or decrease position
    bytes internalParams;
}

// Parameters that are passed to UniswapV3Callback when the action is increase position
struct IncreasePositionInternalParams {
    uint256 principalAmount;
    uint256 minimumSupplyAmount;
    address borrowToken;
    address supplyToken;
    address platform;
}

// Parameters that are passed to UniswapV3Callback when the action is decrease position
struct DecreasePositionInternalParams {
    uint256 redeemAmount; // Total amount to be redeemed
    uint256 maximumFlashAmount;
    uint256 debt; // Computed debt prior to flashswap, for tax purposes and gas savings
    address borrowToken;
    address supplyToken;
    address platform;
    address lender; // For gas savings
}

interface ILeverageWithV3FlashswapConnector {
    function increasePositionWithV3Flashswap(IncreasePositionWithFlashswapParams calldata params) external;

    function decreasePositionWithV3Flashswap(DecreasePositionWithFlashswapParams calldata params) external;
}
