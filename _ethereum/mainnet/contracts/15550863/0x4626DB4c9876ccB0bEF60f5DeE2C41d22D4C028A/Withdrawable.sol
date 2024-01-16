//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

abstract contract Withdrawable is Ownable {
    
    IERC20 public paymentToken;

    function setPaymentTokenContract(address _address) external onlyOwner {
        paymentToken = IERC20(_address);
    }

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawPaymentToken() public payable onlyOwner {
        uint256 bal = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, bal);
    }

    function withdrawToken(address _tokenAddress) public payable onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
}
