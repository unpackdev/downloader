// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract NFTAuctionSale is Ownable, Pausable {
    uint256 public constant AUCTION_LENGTH = 14 days;
    uint256 public constant TIME_BUFFER = 4 hours;

    event PutOnAuction(
        uint256 nftTokenId,
        uint256 reservePrice,
        address seller
    );

    event BidPlaced(
        uint256 nftTokenId,
        address bidder,
        uint256 bidPrice,
        uint256 timestamp,
        uint256 transaction
    );

    event NFTClaimed(uint256 nftTokenId, address winner, uint256 price);

    event ReservePriceUpdated(
        uint256 nftTokenId,
        uint256 reservePrice,
        address seller
    );

    struct AuctionBid {
        address bidder;
        uint256 price;
    }

    struct Auction {
        address seller;
        uint256 reservePrice;
        uint256 endTime;
        AuctionBid bid;
    }

    mapping(uint256 => Auction) private auctions;

    address private escrowAccount;
    IERC721 private auctionToken;

    constructor(address _nftTokenAddress) {
        auctionToken = IERC721(_nftTokenAddress);
        require(
            auctionToken.supportsInterface(0x80ac58cd),
            "Auction token is not ERC721"
        );

        escrowAccount = _msgSender();
    }

    function updateEscrowAccount(address _escrowAccount) external onlyOwner {
        require(_escrowAccount != address(0x0), "Invalid account");
        require(
            auctionToken.isApprovedForAll(_escrowAccount, escrowAccount),
            "New EscrowAccount is not approved to transfer tokens"
        );
        escrowAccount = _escrowAccount;
    }

    function getRequiredBid(uint256 price) internal pure returns (uint256) {
        uint256 a = price + 10000000000000000; // 0.01 ether
        uint256 b = price + (price / 20); // 5%

        return a < b ? a : b;
    }

    function putOnAuction(uint256 nftTokenId) public whenNotPaused onlyOwner {
        require(
            auctions[nftTokenId].seller == address(0x0),
            "NFT already on Auction"
        );

        auctions[nftTokenId] = Auction(
            _msgSender(),
            10000000000000000,
            block.timestamp + AUCTION_LENGTH,
            AuctionBid(address(0x0), 0)
        );

        emit PutOnAuction(nftTokenId, 10000000000000000, _msgSender());
    }

    function putOnAuctionBulk(uint256 i, uint256 j)
        public
        whenNotPaused
        onlyOwner
    {
        while (i < j) {
            putOnAuction(i++);
        }
    }

    function distributeReward(uint256 nftTokenId) external {
        Auction storage _auction = auctions[nftTokenId];
        AuctionBid storage _bid = _auction.bid;

        require(
            _auction.endTime < block.timestamp,
            "Auction still in progress"
        );

        require(_bid.bidder != address(0x0), "No bids placed");
        require(_auction.reservePrice != 0, "Auction completed");

        _auction.reservePrice = 0;

        // Token transfer
        auctionToken.safeTransferFrom(escrowAccount, _bid.bidder, nftTokenId);

        // Seller fee
        payable(_auction.seller).transfer(_bid.price);

        emit NFTClaimed(nftTokenId, _bid.bidder, _bid.price);

        delete auctions[nftTokenId];
    }

    function bid(uint256 nftTokenId) external payable whenNotPaused {
        uint256 bidPrice = msg.value;

        Auction storage _auction = auctions[nftTokenId];
        AuctionBid storage _auctionBid = _auction.bid;

        require(_auction.seller != address(0x0), "Auction not found");
        require(_auction.seller != _msgSender(), "Seller cannot place bids");

        // Validate can place bids
        require(_auction.endTime >= block.timestamp, "Cannot place new bids");

        // first bid
        if (_auctionBid.price == 0) {
            // Validate bid price
            require(
                bidPrice >= getRequiredBid(_auction.reservePrice),
                "New bids needs to higher by 5% or 0.01 ether"
            );
            _auction.bid = AuctionBid(_msgSender(), bidPrice);
            // update auction if bid placed in last 15 minutes
            if (_auction.endTime - block.timestamp < 15 minutes) {
                _auction.endTime = _auction.endTime + TIME_BUFFER;
            }
            emit BidPlaced(
                nftTokenId,
                _msgSender(),
                bidPrice,
                block.timestamp,
                block.number
            );
            return;
        }

        // Validate bid price
        uint256 requiredBid = getRequiredBid(_auctionBid.price);
        require(
            bidPrice >= requiredBid,
            "New bids needs to higher by 5% or 0.01 ether"
        );

        // Previous bid
        AuctionBid memory prevBid = _auctionBid;

        // update storage bid
        _auction.bid.price = bidPrice;
        _auction.bid.bidder = _msgSender();

        // update auction if bid placed in last 15 minutes
        if (_auction.endTime - block.timestamp < 15 minutes) {
            _auction.endTime = _auction.endTime + TIME_BUFFER;
        }

        payable(prevBid.bidder).transfer(prevBid.price);
        emit BidPlaced(
            nftTokenId,
            _msgSender(),
            bidPrice,
            block.timestamp,
            block.number
        );
    }

    function getAuction(uint256 nftId) public view returns (Auction memory) {
        return auctions[nftId];
    }

    function getAuctionsBulk(uint256 i, uint256 j)
        public
        view
        returns (Auction[] memory)
    {
        Auction[] memory _auctions = new Auction[](j - i);
        for (; i < j; ++i) {
            _auctions[i] = auctions[i];
        }
        return _auctions;
    }

    /*
        Rescue any ERC-20 tokens (doesnt include ETH) that are sent to this contract mistakenly
    */
    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transferFrom(address(this), owner(), _amount);
    }

    function selfDestruct(address adr) public onlyOwner whenPaused {
        selfdestruct(payable(adr));
    }
}
