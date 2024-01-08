//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

//simple payments handling for splitting between a wallet and contract owner
contract PaymentHandler is Ownable{

    address otherWallet;

    function setWithdrawWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0));
        otherWallet = newWallet;
    }

    //payments
    function withdrawAll() external onlyOwner {
        require(otherWallet != address(0),"Withdraw wallet not set");
                
        payable(otherWallet).transfer(address(this).balance / 2); //50%
        payable(owner()).transfer(address(this).balance); //50%        
    }

    function withdrawAmount(uint amount) external onlyOwner {
        require(otherWallet != address(0),"Withdraw wallet not set");
        require(address(this).balance >= amount);

        payable(otherWallet).transfer(amount / 2); //50%
        payable(owner()).transfer(amount / 2); //50%     
    }

}