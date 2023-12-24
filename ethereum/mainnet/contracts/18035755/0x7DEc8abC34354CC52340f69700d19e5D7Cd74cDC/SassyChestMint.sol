// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";

contract SassyChestMint is Ownable {
    using Strings for string;
    uint256 public pricePerChest = 12500000000000000; // .0125 ETH

    event Mint(
        address indexed to,
        uint256 indexed quantity,
        uint256 indexed paymentAmount
    );
    event Refund(
        address indexed to,
        uint256 indexed amount,
        string indexed originalPurchaseTransactionHash
    );

    event Withdraw(uint256 indexed amount);

    function MintOnPoly(uint256 quantity) external payable {
        require(
            msg.value == pricePerChest * quantity,
            "Incorrect ETH amount sent"
        );
        emit Mint(msg.sender, quantity, msg.value);
    }

    function refund(
        address to,
        uint256 amount,
        string calldata transactionHash
    ) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= address(this).balance,
            "Amount must be less than contract balance"
        );
        payable(to).transfer(amount);
        emit Refund(to, amount, transactionHash);
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        emit Withdraw(address(this).balance);
    }

    function setPricePerChest(uint256 newPrice) external onlyOwner {
        pricePerChest = newPrice;
    }
}
