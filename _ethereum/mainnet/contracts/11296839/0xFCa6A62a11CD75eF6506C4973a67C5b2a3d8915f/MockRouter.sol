//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./SafeMath.sol";
import "./IV2Router.sol";
import "./IPairFactory.sol";
import "./IPair.sol";

import "./console.sol";

contract MockRouter is IV2Router {
    using SafeMath for uint256;
    using SafeMath for uint;

    IPairFactory factory;

    constructor(IPairFactory fac) public {
        factory = fac;
    }

    function addLiquidity(IERC20 tokenA, uint aAmount, IERC20 tokenB, uint bAmount) 
        external 
        override 
        returns (address) {

        require(tokenA.allowance(msg.sender, address(this)) >= aAmount, "Must have allowance to transfer tokens");
        require(tokenB.allowance(msg.sender, address(this)) >= bAmount, "Must have allowance to transfer tokens");
        
        IPair pair = IPair(factory.createPair(address(tokenA), address(tokenB)));
        tokenA.transferFrom(msg.sender, address(pair), aAmount);
        tokenB.transferFrom(msg.sender, address(pair), bAmount);
        (uint amount0, uint amount1) = address(tokenA) > address(tokenB) ? (bAmount,aAmount) : (aAmount,bAmount);
        pair.addLiquid(amount0, amount1);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        view
        override
        returns (uint amount) {

        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amount = (numerator / denominator).add(1);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        view
        override
        returns (uint amount) {
            
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amount = uint(numerator / denominator);
    }
    

}