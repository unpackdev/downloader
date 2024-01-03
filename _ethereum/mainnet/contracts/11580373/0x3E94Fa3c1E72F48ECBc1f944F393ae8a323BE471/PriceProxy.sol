// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Oracle {
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint);
}

contract PriceProxy {
    address public immutable tokenIn;
    address public immutable tokenOut;
    uint public immutable amountIn;
    Oracle public constant ORACLE = Oracle(0x73353801921417F465377c8d898c6f4C0270282C);
    constructor(address _tokenIn, address _tokenOut, uint _amountIn) {
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        amountIn = _amountIn;
    }
    function latestAnswer() external view returns(uint) {
        return ORACLE.current(tokenIn, amountIn, tokenOut);
    }
}