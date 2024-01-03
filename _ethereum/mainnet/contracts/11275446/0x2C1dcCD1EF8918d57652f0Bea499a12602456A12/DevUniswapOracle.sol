// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IUniswapV2Oracle.sol";
import "./UniswapV2Library.sol";

contract DevUniswapOracle is IUniswapV2Oracle {

    address public uniswapFactory;

    constructor(address uniswapFactory_) public {
        uniswapFactory = uniswapFactory_;
    }

    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) public override view returns (uint256 amountOut) {
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapFactory, tokenIn, tokenOut);
        return UniswapV2Library.quote(amountIn, reserveIn, reserveOut);
    }
}
