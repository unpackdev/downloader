// SPDX-License-Identifier: MIT
//https://www.boundfinance.co.uk/
//https://boundfinance.app/
//Twitter - @BoundFinance
//Discord - https://discord.com/invite/kBDEWndd7m
//Public sale Contract for BCKGOV Tokens


pragma solidity ^0.8.19;

import "./ReentrancyGuard.sol";


interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint8);
    function transferFrom(address user1, address user2, uint256 amount) external returns (bool);
}

contract TokenSale is ReentrancyGuard {
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price;              // the price, in wei, per token
    address public owner;
    uint256 public tokensSold;

    event Sold(address indexed buyer, uint256 amount);
    event BoughtBack(address indexed seller, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }


    constructor(IERC20Token _tokenContract, uint256 _price) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
    }

    function buyTokens(uint256 numberOfTokens) public payable nonReentrant {
        require(msg.value == ((numberOfTokens * price) / 1E18), "Mismatched value sent");

        require(tokenContract.balanceOf(address(this)) >= numberOfTokens, "Insufficient tokens");

        tokensSold += numberOfTokens;

        emit Sold(msg.sender, numberOfTokens);

        require(tokenContract.transfer(msg.sender, numberOfTokens), "Token transfer failed");
    }

    function sellTokens(uint256 numberOfTokens) public nonReentrant {

        require(tokenContract.balanceOf(msg.sender) >= numberOfTokens, "Insufficient tokens to sell");

        require(address(this).balance >= ((numberOfTokens * price) / 1E18), "Insufficient ETH in contract");

        tokensSold -= numberOfTokens;

        emit BoughtBack(msg.sender, numberOfTokens);

        require(tokenContract.transferFrom(msg.sender, address(this), numberOfTokens), "Token transfer failed");

        payable(msg.sender).transfer(((numberOfTokens * price) / 1E18));
    }

    function endSale() public onlyOwner nonReentrant {
        // Send unsold tokens to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))), "Transfer failed");

        // Transfer the balance to the owner
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
    
    }

    function transferOwnership(address newOwner) public onlyOwner  {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
