// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AuraVault {
    address public owner;
    uint256 public subscriptionPrice;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        subscriptionPrice = 0.03 ether; 
    }

    // Events
    event Authentificate(address indexed user, string code);
    event Subscribe(address indexed user);


    // Admin
    function setSubscriptionPrice(uint256 newPrice) external onlyOwner {
        subscriptionPrice = newPrice;
    }

    // Admin
    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Admin
    function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Invalid new owner address");
    owner = newOwner;
}


    // Authentificate your wallet
    function authenticate(string memory code) external {
        emit Authentificate(msg.sender, code);
    }

    // Pay the monthly sub
    function subscribe() external payable {
        require(msg.value >= subscriptionPrice, "Insufficient payment");

        if (msg.value > subscriptionPrice) {
            payable(msg.sender).transfer(msg.value - subscriptionPrice);
        }

        emit Subscribe(msg.sender);
    }
}
