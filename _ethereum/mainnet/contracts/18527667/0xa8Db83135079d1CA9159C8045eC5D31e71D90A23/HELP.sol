// SPDX-License-Identifier: Unlicensed


/**
Dear friends, degens

I created this token because I need your help.
I am father of twins, boy Mark and girl Lori. 
Mark is healthy little boy.
Unfortunately, Lori has a leukemia and needs an experimental treatment in USA.
I need your help. Please consider a donation to this address:

0x91bc1051790b984cdf622b992f1aa1042ce032cd

or to creator address.
First one is the Binance address and it accepts ERC20 and BEP20 tokens.

I don't want to rug this or tax farm or whatever you call it nowadays.
Liquidity won't be added and trading won't be enabled, I don't want to scam anyone.

One day I might repay you, but I cannot promise that. 
My wife and I spent almost every single cent we had.

Thank you from the bottom of my heart
*/

pragma solidity ^0.8.20;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Lori against dragons";
    string public symbol = "LORI";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}