// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EtherTulip.sol";
import "./IERC721.sol";

contract TulipBidding {
    mapping(address => mapping(uint256 => uint256)) public bids;

    address public immutable feeRecipient;
    uint256 public immutable feeBps;
    address public immutable etherTulip;

    event BidPlaced(uint256 tulipNumber, address buyer, uint256 price);
    event BidRevoked(uint256 tulipNumber, address buyer);
    event BidClaimed(uint256 tulipNumber, address bot);

    constructor(
        address _feeRecipient,
        uint256 _feeBps,
        address _etherTulip
    ) {
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
        etherTulip = _etherTulip;
    }

    function placeBid(uint256 tulipNumber) external payable {
        // increase bid
        bids[msg.sender][tulipNumber] += msg.value;
        // emit event
        emit BidPlaced(tulipNumber, msg.sender, bids[msg.sender][tulipNumber]);
    }

    function revokeBid(uint256 tulipNumber) external {
        uint256 bid = bids[msg.sender][tulipNumber];
        // clear bid
        delete bids[msg.sender][tulipNumber];
        // return funds
        payable(msg.sender).transfer(bid);
        // emit event
        emit BidRevoked(tulipNumber, msg.sender);
    }

    function fillDirectBid(
        uint256 tulipNumber,
        address buyer,
        uint256 botFee
    ) external {
        uint256 value = bids[msg.sender][tulipNumber];
        uint256 marketFee = (value * feeBps) / 10000;
        uint256 price = value - botFee - marketFee;
        // clear bid
        delete bids[msg.sender][tulipNumber];
        // perform purchase
        EtherTulip(etherTulip).buyTulip{value: price}(tulipNumber);
        // transfer tulip to buyer
        EtherTulip(etherTulip).giftTulip(tulipNumber, buyer);
        // pay the fees
        payable(msg.sender).transfer(botFee);
        payable(feeRecipient).transfer(marketFee);
        // emit event
        emit BidClaimed(tulipNumber, msg.sender);
    }

    function fillIndirectBid(uint256 tulipNumber, address buyer) external {
        uint256 value = bids[msg.sender][tulipNumber];
        uint256 marketFee = (value * feeBps) / 10000;
        uint256 price = value - marketFee;
        // clear bid
        delete bids[msg.sender][tulipNumber];
        // transfer tulip to buyer
        IERC721(etherTulip).transferFrom(msg.sender, buyer, tulipNumber);
        // pay the fees
        payable(msg.sender).transfer(price);
        payable(feeRecipient).transfer(marketFee);
        // emit event
        emit BidClaimed(tulipNumber, msg.sender);
    }
}
