// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract AssetCoin is ERC20, Ownable {
    // Addresses to receive Buy and Sell tax fees
    address public buyTaxAddress = 0x42573b955dB053B118166C80B3503e44f4F45A98;
    address public sellTaxAddress = 0x90561A2f2F6f02F8ED3A4f2B875785d356C7B676;

    // Tax rates (1% and 3%)
    uint256 public buyTaxRate = 1;
    uint256 public sellTaxRate = 3;

    // Maximum token supply
    uint256 public maxSupply = 1000000000 * 10**18;

    // Maximum tax rate allowed to be set by the owner
    uint256 public maxTaxRate = 4;

    constructor() ERC20("AssetCoin", "ASSET") Ownable(msg.sender) {
        // Mint the total supply to the contract owner
        _mint(msg.sender, maxSupply);
    }

    // Function for transferring with tax
    function _transferWithTax(address sender, address recipient, uint256 amount, uint256 taxRate, address taxAddress) internal {
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 transferAmount = amount - taxAmount;

        // Transfer tokens without tax to the recipient
        _transfer(sender, recipient, transferAmount);

        // Transfer tax fee to the specified address
        _transfer(sender, taxAddress, taxAmount);
    }

    // Function for transferring with Buy tax during buy transactions
    function transferWithBuyTax(address recipient, uint256 amount) external {
        require(buyTaxRate <= maxTaxRate, "Buy tax rate exceeds maximum allowed");
        _transferWithTax(msg.sender, recipient, amount, buyTaxRate, buyTaxAddress);
    }

    // Function for transferring with Sell tax during sell transactions
    function transferWithSellTax(address recipient, uint256 amount) external {
        require(sellTaxRate <= maxTaxRate, "Sell tax rate exceeds maximum allowed");
        _transferWithTax(msg.sender, recipient, amount, sellTaxRate, sellTaxAddress);
    }

    // Set a new address for Buy tax fees
    function setBuyTaxAddress(address newAddress) external onlyOwner {
        buyTaxAddress = newAddress;
    }

    // Set a new address for Sell tax fees
    function setSellTaxAddress(address newAddress) external onlyOwner {
        sellTaxAddress = newAddress;
    }

    // Set a new Buy tax rate
    function setBuyTaxRate(uint256 newRate) external onlyOwner {
        require(newRate <= maxTaxRate, "Buy tax rate exceeds maximum allowed");
        buyTaxRate = newRate;
    }

    // Set a new Sell tax rate
    function setSellTaxRate(uint256 newRate) external onlyOwner {
        require(newRate <= maxTaxRate, "Sell tax rate exceeds maximum allowed");
        sellTaxRate = newRate;
    }

    // Set a new maximum tax rate allowed to be set by the owner
    function setMaxTaxRate(uint256 newMaxTaxRate) external onlyOwner {
        maxTaxRate = newMaxTaxRate;
    }
   
}