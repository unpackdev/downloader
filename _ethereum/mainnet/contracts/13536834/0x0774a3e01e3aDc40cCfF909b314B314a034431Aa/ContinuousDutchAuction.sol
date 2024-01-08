// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Manageable.sol";
import "./Address.sol";

abstract contract ContinuousDutchAuction is Manageable {


    struct Auction {
        uint128 startingPrice;
        uint64 decreasingConstant;
        uint32 startingBlock;
        uint32 period; //period (in blocks) during which price will decrease
    }

    mapping (uint => Auction) private _auctions;

    function auctions(uint256 auctionId) public view returns (
        uint128 startingPrice,
        uint64 decreasingConstant,
        uint32 startingBlock,
        uint32 period,
        bool active
    ) {
        Auction memory auction = _auctions[auctionId];
        startingPrice = auction.startingPrice;
        decreasingConstant = auction.decreasingConstant;
        startingBlock = auction.startingBlock;
        period = auction.period;
        active = block.number >= startingBlock;
    }

    function setAuction(
        uint256 auctionId,
        uint128 startingPrice,
        uint64 decreasingConstant,
        uint32 startingBlock,
        uint32 period
    ) virtual public onlyRole(MANAGER_ROLE) {
        unchecked {
            require(startingPrice - decreasingConstant * period <= startingPrice, "setAuction: floor price underflow");
        }
        _auctions[auctionId] = Auction(startingPrice, decreasingConstant, startingBlock, period);
    }

    function getPrice(uint256 auctionId) virtual public view returns (uint256 price) {
        Auction memory auction = _auctions[auctionId];
        //only compute correct price if necessary
        if (block.number < auction.startingBlock) price = auction.startingPrice;
        else if (block.number >= auction.startingBlock + auction.period) price = auction.startingPrice - auction.period * auction.decreasingConstant;
        else price = auction.startingPrice - (auction.decreasingConstant * (block.number - auction.startingBlock));
    }

    function verifyBid(uint256 auctionId) internal returns (uint256) {
        Auction memory auction = _auctions[auctionId];
        require(auction.startingBlock > 0, "AUCTION:NOT CREATED");
        require(block.number >= auction.startingBlock, "PURCHASE:AUCTION NOT STARTED");
        uint256 pricePaid = getPrice(auctionId);
        require(msg.value >= pricePaid, "PURCHASE:INCORRECT MSG.VALUE");
        if (msg.value - pricePaid > 0) Address.sendValue(payable(msg.sender), msg.value-pricePaid); //refund difference
        return pricePaid;
    }
}