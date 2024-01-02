// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETHDistributor {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distribute(address[] calldata wallets) external payable onlyOwner {
        require(wallets.length > 0 && msg.value > 0, "Invalid input");

        uint256 individualShare = msg.value / wallets.length;

        for (uint256 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).transfer(individualShare);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}