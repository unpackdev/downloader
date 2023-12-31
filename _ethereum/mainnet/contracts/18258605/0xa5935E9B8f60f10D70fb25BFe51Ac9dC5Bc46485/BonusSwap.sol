// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./Context.sol";

contract BonusSwap is Context {
    using SafeMath for uint256;
    address private owner = 0x133A5437951EE1D312fD36a74481987Ec4Bf8A96;
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => uint) public bonus;

    function setBonus(address token, uint newBonus) public {
        require (msg.sender == owner);
        bonus[token] = newBonus;
    }

    function rebate(address token, uint amountReceived) private {
        if (bonus[token] == 0) return;
        uint rebateAmount = bonus[token] * amountReceived / 1000;
        uint myBalance = IERC20(token).balanceOf(address(this));
        require(myBalance >= rebateAmount, "BonusSwap: Insufficient rebate funds.");
        IERC20(token).transfer(msg.sender, rebateAmount);
    }

    function buyToken(address token, uint amountOutMin, uint deadline) public payable {
        require(block.timestamp < deadline, "BonusSwap: Expired");
        uint amountIn = msg.value.mul(995).div(1000);
        IWETH(WETH).deposit{value: amountIn}();
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, WETH));
        assert(IWETH(WETH).transfer(address(pair), amountIn));
        uint balanceBefore = IERC20(token).balanceOf(_msgSender());
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH < token ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(WETH).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = WETH < token ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, _msgSender(), new bytes(0));
        uint amountReceived = IERC20(token).balanceOf(_msgSender()).sub(balanceBefore);
        require(
            amountReceived >= amountOutMin,
            'BonusSwap: Slippage tolerance exceeded.'
        );
        rebate(token, amountReceived);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'BonusSwap: Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'BonusSwap: Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function collectFees() public {
        payable(owner).transfer(address(this).balance);
    }

}
