// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.11;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./IDickManiac.sol";
import "./IEMC.sol";

contract PreSale is Pausable, ReentrancyGuard, Ownable {
    IDickManiac public immutable collection;
    IEMC public immutable echo3card;
    uint256 public preSaleSize;
    uint256 public itemPrice;
    uint256 public releaseDate;
    address payable public liquidityCollector;
    Counters.Counter private tokenTracker;

    constructor(
        IDickManiac _collection,
        IEMC _echo3card,
        uint256 _preSaleSize,
        address payable _liquidityCollector,
        uint256 _releaseDate,
        uint256 _price
    ) {
        collection = _collection;
        echo3card = _echo3card;
        itemPrice = _price;
        liquidityCollector = _liquidityCollector;
        preSaleSize = _preSaleSize;
        releaseDate = _releaseDate;
    }

    function mintNewDicks(uint256 quantity)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(block.timestamp >= releaseDate, "PS: Not started");
        uint256 priceToPay = itemPrice * quantity;
        require(msg.value >= priceToPay, "PS: Sent ETH too low");
        require(
            collection.getCurrentTokenTracker() + quantity <= preSaleSize,
            "PS: Pre-Sale sold out!"
        );

        for (uint256 i = 0; i < quantity; i++) {
            collection.mint(msg.sender);
            echo3card.mint(msg.sender);
        }

        uint256 refund = msg.value - priceToPay;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        liquidityCollector.transfer(priceToPay);
    }

    function issueContingent(address to, uint256 quantity) external onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            collection.mint(to);
        }
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}
