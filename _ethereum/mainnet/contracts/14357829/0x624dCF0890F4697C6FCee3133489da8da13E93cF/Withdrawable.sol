//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";

abstract contract Withdrawable is Ownable {
    function withdraw(address payable to) external onlyOwner {
        require(to != address(0), "Cannot recover tokens to the 0 address");
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }
    
    function withdrawETH(address payable receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0), "Cannot recover ETH to the 0 address");
        receiver.transfer(amount);
    }

    function withdrawTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot recover tokens to the 0 address");
        token.transfer(receiver, amount);
    }
}