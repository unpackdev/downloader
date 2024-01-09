// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract BidAny is Ownable {

    // wallet -> erc721 -> bid price
    mapping(address => mapping(address => uint)) public bids;
    address payable public feeReceiver;
    uint public fee;

    event NewBid(
        address indexed bidder,
        uint256 price,
        address indexed erc721
    );

    constructor(address payable _feeReceiver) {
        feeReceiver = _feeReceiver;
    }

    function makeBid(address _erc721, uint _price) external payable {
        uint bid = bids[msg.sender][_erc721];
        require(_price != bid, "Cannot bid the same.");
        if (_price > bid) {
            require(msg.value >= (_price - bid), "Insufficient payment");
        } else {
            (bool sent, ) = msg.sender.call{value: bid - _price}("");
            require(sent, "Transfer failed");
        }
        bids[msg.sender][_erc721] = _price;
        emit NewBid(msg.sender, _price, _erc721);
    }

    function takeBid(address _erc721, uint256 _tokenId, address _bidder, uint _minBid) external {
        require(
            IERC721(_erc721).ownerOf(_tokenId) == msg.sender,
            "You don't own this NFT"
        );
        uint bid = bids[_bidder][_erc721];
        require(bid >= _minBid, "minBid not met");
        // Clear out bid price
        bids[_bidder][_erc721] = 0;
        emit NewBid(_bidder, 0, _erc721);
        IERC721(_erc721).safeTransferFrom(msg.sender, _bidder, _tokenId);
        (bool sent1, ) = msg.sender.call{value: bid * (1000 - fee) / 1000}("");
        require(sent1, "Transfer failed");
        if (fee > 0) {
            (bool sent2, ) = feeReceiver.call{value: bid * fee / 1000}("");
            require(sent2, "Transfer failed");
        }
    }

    function setFee(uint _fee) external onlyOwner {
        // Max fee 10%
        require(_fee < 101);
        fee = _fee;
    }

    function setFeeReceiver(address payable _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }
}