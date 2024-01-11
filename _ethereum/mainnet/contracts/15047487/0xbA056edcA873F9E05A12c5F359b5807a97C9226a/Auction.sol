// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./NFT.sol";
import "./Traits.sol";


contract Auction is NFT {
    struct _Auction {
        uint256 minBid;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        uint256 maxBidsCount;
        uint256 bidsCount;
    }

    uint256 public autoMintInterval;
    uint256 public creatorRoyalty;
    uint256 public treasureRoyalty;
    uint256 public treasureAmount;

    mapping(uint256 => _Auction) public auctions;
    mapping(address => uint256) public balances;

    mapping(uint256 => uint256) public lastPrice;
    uint256 public sold;
    uint256 public lastPricesSum;
    uint256 public lastAuctionTokenId;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_,
        uint256 autoMintInterval_,
        uint256 creatorRoyalty_,
        uint256 treasureRoyalty_
    ) NFT(name_, symbol_, baseURI_, mutagenFrequency_) {
        autoMintInterval = autoMintInterval_;
        creatorRoyalty = creatorRoyalty_;
        treasureRoyalty = treasureRoyalty_;
    }

    function auctionStarted(uint256 tokenId) internal view virtual returns (bool) {
        return auctions[tokenId].endTime > 0;
    }

    function auctionFinished(uint256 tokenId) internal view virtual returns (bool) {
        _Auction storage auction = auctions[tokenId];
        return block.timestamp >= auction.endTime || (auction.maxBidsCount > 0 && auction.bidsCount >= auction.maxBidsCount);
    }

    function _auctionStart(uint256 tokenId, uint256 duration, uint256 minBid, uint256 maxBidsCount) internal virtual {
        auctions[tokenId].minBid = minBid;
        auctions[tokenId].endTime = block.timestamp + duration;
        auctions[tokenId].maxBidsCount = maxBidsCount;
    }

    function auctionStart(uint256 tokenId, uint256 duration, uint256 minBid, uint256 maxBidsCount) public virtual {
        require(!auctionStarted(tokenId), "A2");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "A5");
        _auctionStart(tokenId, duration, minBid, maxBidsCount);
    }

    function auctionBid(uint256 tokenId, uint256 bid) external payable virtual {
        bool startedAndFinished = _exists(lastAuctionTokenId) &&
            ownerOf(lastAuctionTokenId) == address(this) &&
            auctionStarted(lastAuctionTokenId) &&
            auctionFinished(lastAuctionTokenId);
        bool notExistsOrFinished = !_exists(lastAuctionTokenId) || (ownerOf(lastAuctionTokenId) != address(this)) || startedAndFinished;
        if (tokenId == tokenIdCounter && (tokenIdCounter == 0 || notExistsOrFinished)) {
            if (startedAndFinished) {
                auctionFinish(lastAuctionTokenId);
            }

            lastAuctionTokenId = tokenIdCounter;
            _mintWithTraits(address(this));
            _auctionStart(lastAuctionTokenId, autoMintInterval, 0, _randint(totalSupply() == 0 ? 1 : totalSupply()) == 0 ? 1 : 0);
        }

        require(auctionStarted(tokenId), "A14");
        require(!auctionFinished(tokenId), "A4");
        require(!_isApprovedOrOwner(_msgSender(), tokenId), "A6");

        _Auction storage auction = auctions[tokenId];

        require(_msgSender() != auction.highestBidder, "A7");

        uint256 newBid = bid > msg.value ? bid : msg.value;

        require(newBid >= auction.minBid, "A8");
        require(auction.highestBidder == address(0) || newBid > auction.highestBid, "A9");

        uint256 getFromBalance = newBid - msg.value;

        require(balances[_msgSender()] >= getFromBalance, "A10");

        balances[auction.highestBidder] += auction.highestBid;

        auction.bidsCount += 1;
        auction.highestBidder = _msgSender();
        auction.highestBid = newBid;
        balances[_msgSender()] -= getFromBalance;

        if (auctionFinished(tokenId)) {
            auctionFinish(tokenId);
        }
    }

    function auctionFinish(uint256 tokenId) public virtual {
        require(auctionStarted(tokenId), "A15");
        require(_isApprovedOrOwner(_msgSender(), tokenId) || auctionFinished(tokenId), "A11");

        _Auction storage auction = auctions[tokenId];

        bool firstSale = ownerOf(tokenId) == address(this);

        if (auction.highestBidder != address(0)) {
            uint256 creatorRoyaltyValue = auction.highestBid * creatorRoyalty / 1000;
            uint256 treasureRoyaltyValue = auction.highestBid * treasureRoyalty / 1000;
            uint256 withdrawValue = auction.highestBid - creatorRoyaltyValue - treasureRoyaltyValue;

            if (auction.highestBid > 0) {
                if (lastPrice[tokenId] == 0) {
                    sold += 1;
                } else {
                    lastPricesSum -= lastPrice[tokenId];
                }
                lastPricesSum += auction.highestBid;
                lastPrice[tokenId] = auction.highestBid;
            }

            balances[owner()] += creatorRoyaltyValue;
            treasureAmount += treasureRoyaltyValue;

            if (firstSale) {
                treasureAmount += withdrawValue;
            } else {
                balances[ownerOf(tokenId)] += withdrawValue;
            }

            _safeTransfer(ownerOf(tokenId), auction.highestBidder, tokenId, "");
        } else if (firstSale) {
            _burn(tokenId);
        }

        delete auctions[tokenId];
    }

    function auctionWithdraw(address to, uint256 amount) external virtual {
        require(amount > 0, "A12");
        require(balances[_msgSender()] >= amount, "A13");

        // Add long term randomness
        _randint(block.timestamp);

        balances[_msgSender()] -= amount;
        payable(to).transfer(amount);
    }

//    function auctionAvgMarketPrice() public view virtual returns (uint256){
//        return sold == 0 ? 0 : lastPricesSum / sold;
//    }
}
