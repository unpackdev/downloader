// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IDickManiac.sol";
import "./IEMC.sol";

import "./console.sol";

contract PreSale is ReentrancyGuard, Ownable {
    IDickManiac public immutable collection;
    IEMC public immutable echo3card;
    uint256 public preSaleSize;
    uint256 public itemPrice;
    uint256 public releaseDate;

    constructor(
        IDickManiac _collection,
        IEMC _echo3card,
        uint256 _preSaleSize,
        uint256 _releaseDate,
        uint256 _price
    ) {
        collection = _collection;
        echo3card = _echo3card;
        itemPrice = _price;
        preSaleSize = _preSaleSize;
        releaseDate = _releaseDate;
    }

    function mintNewDicks(uint256 quantity) external payable nonReentrant {
        require(block.timestamp >= releaseDate, "PS: Not started");
        uint256 priceToPay = itemPrice * quantity;
        require(msg.value >= priceToPay, "PS: Sent ETH too low");
        require(
            collection.getCurrentTokenTracker() + quantity <= preSaleSize,
            "PS: Pre-Sale sold out!"
        );

        console.log("passes require");

        for (uint256 i = 0; i < quantity; i++) {
            console.log("mint", i);
            collection.mint(msg.sender);
            echo3card.mint(msg.sender);
            console.log("mint done", i);
        }

        uint256 refund = msg.value - priceToPay;
        if (refund > 0) {
            console.log("refund");
            payable(msg.sender).transfer(refund);
        }

        // liquidityCollector.transfer(priceToPay);
    }

    function issueContingent(address to, uint256 quantity) external onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            collection.mint(to);
        }
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}
