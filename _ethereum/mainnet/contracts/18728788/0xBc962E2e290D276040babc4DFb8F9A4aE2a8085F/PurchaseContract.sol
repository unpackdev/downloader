// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PurchaseContract {
    address public owner;
    uint256 public feePercentage = 2;

    struct Purchase {
        bytes32 ethsId;
        bytes32 listId;
        address listAddress;
        uint256 price;
        bool isPurchased;
    }

    mapping(bytes32 => Purchase) public purchases;

    event PurchaseMade(address from, address to, bytes32 listHash);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function setFeePercentage(uint256 newFee) public onlyOwner {
        feePercentage = newFee;
    }

    function buy(bytes32 ethsId, bytes32 listId, address listAddress, uint256 price) public payable {
        bytes32 purchaseHash = keccak256(abi.encodePacked(ethsId, listId));
        require(!purchases[purchaseHash].isPurchased, "This item is already purchased.");
        require(msg.value == price, "Incorrect price.");

        purchases[purchaseHash] = Purchase(ethsId, listId, listAddress, price, true);

        uint256 fee = (price * feePercentage) / 100;
        uint256 amountToSend = price - fee;

        payable(listAddress).transfer(amountToSend);
        // The fee remains in the contract

        emit PurchaseMade(msg.sender, listAddress, purchaseHash);
    }

    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(amount > 0, "Amount must be greater than 0");
        require(balance >= amount, "Insufficient funds in contract");

        payable(owner).transfer(amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    
}