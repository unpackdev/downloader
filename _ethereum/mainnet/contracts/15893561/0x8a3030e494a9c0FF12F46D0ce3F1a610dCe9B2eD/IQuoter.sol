// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IQuoter {
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);
}