// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExchange {
    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable returns (uint256);
}
