// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface NFT {
    function mint(address receiver) external;
}

contract SueiBianSale is Ownable, ReentrancyGuard {
    uint256 public publicSaleStartTime = 1647349200; // Tuesday, March 15, 2022 9:00:00 PM GMT+08:00
    uint256 public publicSaleMaxPurchaseAmount = 5;

    uint256 public remainingCount = 4692;
    uint256 public mintPrice = 0.2 ether;

    address public sueiBianDAOAddress;

    constructor(address _sueiBianDAOAddress) {
        sueiBianDAOAddress = _sueiBianDAOAddress;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function mint(uint256 quantity) external payable nonReentrant {
        // checks
        require(tx.origin == msg.sender, "smart contract not allowed");
        require(publicSaleStartTime != 0, "start time not set yet");
        require(block.timestamp >= publicSaleStartTime, "not started");
        require(quantity > 0, "quantity cannot be 0");
        require(
            quantity <= publicSaleMaxPurchaseAmount,
            "cant buy more than publicSaleMaxPurchaseAmount in each tx"
        );
        require(quantity <= remainingCount, "sold out");
        require(
            msg.value == mintPrice * quantity,
            "sent ether value incorrect"
        );
        // effects
        remainingCount -= quantity;
        // interactions
        for (uint256 i = 0; i < quantity; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */
    function setup(
        uint256 _publicSaleStartTime,
        uint256 _publicSaleMaxPurchaseAmount,
        uint256 _remainingCount,
        uint256 _mintPrice
    ) external onlyOwner {
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleMaxPurchaseAmount = _publicSaleMaxPurchaseAmount;
        remainingCount = _remainingCount;
        mintPrice = _mintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
