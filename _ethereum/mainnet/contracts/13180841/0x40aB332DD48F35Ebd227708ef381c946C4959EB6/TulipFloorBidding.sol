// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EtherTulip.sol";
import "./IERC721.sol";
import "./EnumerableSet.sol";

contract TulipFloorBidding {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private bidderSet;

    mapping(address => uint256) public bids;

    address public immutable feeRecipient;
    uint256 public immutable feeBps;
    address public immutable etherTulip;

    event BidPlaced(address buyer, uint256 price);
    event BidRevoked(address buyer);
    event BidClaimed(address bot);

    constructor(
        address _feeRecipient,
        uint256 _feeBps,
        address _etherTulip
    ) {
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
        etherTulip = _etherTulip;
    }

    function getBidderCount() external view returns (uint256 count) {
        return bidderSet.length();
    }

    function getBidderAt(uint256 bidderIndex) external view returns (address bidder) {
        return bidderSet.at(bidderIndex);
    }

    function getBidders() external view returns (address[] memory bidders) {
        return bidderSet.values();
    }

    function placeBid() external payable {
        // increase bid
        bids[msg.sender] += msg.value;
        // add to bidder set
        bidderSet.add(msg.sender);
        // emit event
        emit BidPlaced(msg.sender, bids[msg.sender]);
    }

    function revokeBid() external {
        uint256 bid = bids[msg.sender];
        // clear bid
        delete bids[msg.sender];
        // remove from bidder set
        require(bidderSet.remove(msg.sender), "!bidder");
        // return funds
        payable(msg.sender).transfer(bid);
        // emit event
        emit BidRevoked(msg.sender);
    }

    function arbBid(
        uint256 tulipNumber,
        address buyer,
        uint256 botFee
    ) external {
        uint256 value = bids[buyer];
        uint256 marketFee = (value * feeBps) / 10000;
        uint256 price = value - botFee - marketFee;
        // clear bid
        delete bids[buyer];
        // remove from bidder set
        require(bidderSet.remove(buyer), "!bidder");
        // perform purchase
        EtherTulip(etherTulip).buyTulip{value: price}(tulipNumber);
        // transfer tulip to buyer
        EtherTulip(etherTulip).giftTulip(tulipNumber, buyer);
        // pay the fees
        payable(msg.sender).transfer(botFee);
        payable(feeRecipient).transfer(marketFee);
        // emit event
        emit BidClaimed(msg.sender);
    }

    function fillBid(uint256 tulipNumber, address buyer) external {
        uint256 value = bids[buyer];
        uint256 marketFee = (value * feeBps) / 10000;
        uint256 price = value - marketFee;
        // clear bid
        delete bids[buyer];
        // remove from bidder set
        require(bidderSet.remove(buyer), "!bidder");
        // transfer tulip to buyer
        IERC721(etherTulip).transferFrom(msg.sender, buyer, tulipNumber);
        // pay the fees
        payable(msg.sender).transfer(price);
        payable(feeRecipient).transfer(marketFee);
        // emit event
        emit BidClaimed(msg.sender);
    }
}
