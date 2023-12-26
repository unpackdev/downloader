// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InnovatorSale {
    // State variables
    address public owner;
    uint256 public currentPrice = 0.15 ether;
    uint256 public constant INCREASE_PERCENTAGE = 2; // 2%
    mapping(address => uint256) public buyers;
    uint256 public totalSales = 0; // New state variable to store total sales
    bool public saleActive = true; // State variable to track if the sale is active

    // Events
    event ItemSold(address indexed buyer, uint256 price);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier saleIsActive() {
        require(saleActive, "Sale is not active");
        _;
    }

    modifier reentrancyGuard() {
        require(!locked, "Reentrant call detected!");
        locked = true;
        _;
        locked = false;
    }

    bool private locked = false;

    // Constructor to set the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    // Function to buy an item
    function buy() external payable reentrancyGuard saleIsActive {
        processPurchase(msg.sender, msg.value);
    }

    // Function to get the current price of the item
    function getCurrentPrice() external view returns (uint256) {
        return currentPrice;
    }

    // Function to withdraw the funds to the owner's address
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Function to check the number of purchases by an address
    function numberOfPurchases(address buyer) external view returns (uint256) {
        return buyers[buyer];
    }

    // Fallback function to handle Ether sent to the contract with data
    fallback() external payable {
        processPurchase(msg.sender, msg.value);
    }

    // Receive function to handle plain Ether transfers
    receive() external payable {
        processPurchase(msg.sender, msg.value);
    }

    // Function to stop the sale
    function stopSale() external onlyOwner {
        saleActive = false;
    }

    // Function to start the sale
    function startSale() external onlyOwner {
        saleActive = true;
    }

    // Function to transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    // Internal function to process a purchase
    function processPurchase(address buyer, uint256 amount) internal {
        require(amount == currentPrice, "Incorrect Ether sent");

        // Record the buyer's address and increment their purchase count
        buyers[buyer] += 1;

        // Increment total sales
        totalSales += 1;

        // Emit the event
        emit ItemSold(buyer, currentPrice);

        // Increase the price by 2%
        currentPrice = currentPrice + (currentPrice * INCREASE_PERCENTAGE / 100);
    }
}