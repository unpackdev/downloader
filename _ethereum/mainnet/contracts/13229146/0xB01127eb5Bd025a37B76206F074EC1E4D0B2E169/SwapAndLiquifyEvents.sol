// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SwapAndLiquifyEvents {
    event Initialized(address aldnAddress, address uniswapV2RouterAddress);
    event SwapAndLiquified(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event LiquidityInitialized(uint256 tokensIntoLiquidity, uint256 ethIntoLiquidity);
}
