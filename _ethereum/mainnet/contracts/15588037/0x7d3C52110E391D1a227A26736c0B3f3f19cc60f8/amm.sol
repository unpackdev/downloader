// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
@title HopAMM
@notice responsible for calling the HOP L2 Impl functions.
 */
interface HopAMM {
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;

    function getTokenIndex(address tokenAddress) external view returns (uint8);
}
