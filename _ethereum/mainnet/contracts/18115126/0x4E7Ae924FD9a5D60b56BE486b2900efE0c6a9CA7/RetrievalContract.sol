// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RetrievalContract {
    
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function retrieveTokens(address _tokenAddress) external {
        require(msg.sender == owner, "Not the contract owner");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to retrieve");

        token.transfer(owner, balance);
    }
}