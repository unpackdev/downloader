//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";

contract MunySwap {

    using SafeMath for uint256;
    IERC20 public tokenA;
    IERC20 public tokenB;
    address public owner;

    // assuming 3 digits like 120 or 115
    uint256 swapRate;

    constructor(address tokenA_, address tokenB_, uint256 swapRate_) {
        require(tokenA_ != address(0), "token A cant be 0 address");
        require(tokenB_ != address(0), "token B cant be 0 address");
        require(swapRate_ != 0, "swapRate cant be 0");

        owner = msg.sender;
        tokenA = IERC20(tokenA_);
        tokenB = IERC20(tokenB_);
        swapRate = swapRate_;
    }

    function setTokenA(address token) public {
        require(msg.sender == owner, "sender is not owner");
        require(token != address(0), "token A cant be 0 address");
        tokenA = IERC20(token);
    }

    function setTokenB(address token) public {
        require(msg.sender == owner, "sender is not owner");
        require(token != address(0), "token B cant be 0 address");
        tokenB = IERC20(token);
    }

    function setSwapRate(uint256 rate) public {
        require(msg.sender == owner, "sender is not owner");
        require(rate != 0, "swapRate cant be 0");
        swapRate = rate;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "sender is not owner");
        owner = newOwner;
    }

    function withdrawTokens(uint256 amountA, uint256 amountB, address withdrawTo) public {
        require(msg.sender == owner, "sender is not owner");

        require(tokenA.balanceOf(address(this)) >= amountA, "amountA balance not sufficient");
        require(tokenB.balanceOf(address(this)) >= amountB, "amountB balance not sufficient");

        tokenA.transfer(withdrawTo, amountA);
        tokenB.transfer(withdrawTo, amountB);
    }

    // direction 0 : A to B
    // direction 1 : B to A
    function swapTokens(uint256 amount, uint256 direction) public {
        uint256 outputAmount;
        uint256 contractBal;

        if (direction == 0) {
            require(tokenA.balanceOf(msg.sender) >= amount, "input balance not sufficient");
            tokenA.transferFrom(msg.sender, address(this), amount);

            outputAmount = amount.mul(swapRate).div(100);
            contractBal = tokenB.balanceOf(address(this));

            require(contractBal >= outputAmount, "not enough output token");
            tokenB.transfer(msg.sender, outputAmount);
        } else {
            require(tokenB.balanceOf(msg.sender) >= amount, "input balance not sufficient");
            tokenB.transferFrom(msg.sender, address(this), amount);

            outputAmount = amount.mul(100).div(swapRate);
            contractBal = tokenA.balanceOf(address(this));

            require(contractBal >= outputAmount, "not enough output token");
            tokenA.transfer(msg.sender, outputAmount);
        }
    }
}
