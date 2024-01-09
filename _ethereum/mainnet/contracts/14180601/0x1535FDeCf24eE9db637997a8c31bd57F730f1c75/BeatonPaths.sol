// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";

contract BeatonPaths is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct NFTInfo {
        uint256 minBidPrice;
        uint32 auctionDurationBlocks;
    }

    struct Bid {
        uint256 bidPrice;
        address bidder;
    }

    struct Auction {
        uint256 endBlock;
        uint32 numExtraClaimers;
        bool claimed;
        Bid[] bids;
    }

    struct PublicAuctionInfo {
        uint256 minBidPrice;
        uint256 auctionEndBlock;
        uint32 numExtraClaimers;
        bool claimed;
        Bid[] activeBids;
    }

    Counters.Counter private _tokenIds;
    mapping(string => uint256) private _mintedHashes;
    mapping(uint256 => NFTInfo) private _nftInfos;
    mapping(uint256 => Auction) private _auctions;

    constructor() ERC721("BeatonPaths", "BPA") {}

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function mint(
        string memory hash,
        string memory metadata,
        uint256 minBidPrice,
        uint32 auctionDurationBlocks
    ) public onlyOwner returns (uint256) {
        require(_mintedHashes[hash] == 0, "Object has already been minted");
        require(minBidPrice > 0, "Minimum bid price must be greater than 0");
        require(auctionDurationBlocks > 0, "Auction must last more than 0 blocks");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _nftInfos[newTokenId] = NFTInfo({minBidPrice: minBidPrice, auctionDurationBlocks: auctionDurationBlocks});
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, metadata);

        return newTokenId;
    }

    function _requireNFTExists(uint256 tokenId) internal view {
        require(
            _nftInfos[tokenId].minBidPrice != 0 && _nftInfos[tokenId].auctionDurationBlocks != 0,
            "No NFT exists for provided token"
        );
    }

    function _auctionStarted(uint256 tokenId) internal view returns (bool) {
        return _auctions[tokenId].bids.length != 0;
    }

    function _auctionEnded(uint256 tokenId) internal view returns (bool) {
        return _auctions[tokenId].endBlock < block.number;
    }

    function bid(uint256 tokenId, uint256 bidPrice) public {
        _requireNFTExists(tokenId);
        require(bidPrice >= _nftInfos[tokenId].minBidPrice, "Bid must be at least the minimum bid");
        require(
            !_auctionStarted(tokenId) || bidPrice > _auctions[tokenId].bids[0].bidPrice,
            "Bid must be more than current bid"
        );
        require(!_auctionStarted(tokenId) || !_auctionEnded(tokenId), "Auction has ended");
        require(!_auctions[tokenId].claimed, "NFT has been claimed");

        if (_auctionStarted(tokenId)) {
            bool hasBidBefore = false;
            for (uint256 i = 0; i < _auctions[tokenId].bids.length; i++) {
                if (_auctions[tokenId].bids[i].bidder == msg.sender) {
                    _auctions[tokenId].bids[i].bidPrice = bidPrice;
                    hasBidBefore = true;
                    break;
                }
            }

            if (!hasBidBefore) {
                _auctions[tokenId].bids.push(Bid({bidPrice: bidPrice, bidder: msg.sender}));
            }
            sort(_auctions[tokenId].bids);
        } else {
            (bool isSafe, uint256 endBlock) = SafeMath.tryAdd(block.number, _nftInfos[tokenId].auctionDurationBlocks);
            require(isSafe, "Failed to calculate auction expiration");

            _auctions[tokenId].endBlock = endBlock;
            _auctions[tokenId].bids.push(Bid({bidPrice: bidPrice, bidder: msg.sender}));
        }
    }

    function claim(uint256 tokenId) external payable nonReentrant {
        _requireNFTExists(tokenId);
        require(_auctionStarted(tokenId), "Auction has not started");
        require(_auctionEnded(tokenId), "Auction has not ended");
        require(_auctions[tokenId].bids[0].bidPrice >= _nftInfos[tokenId].minBidPrice, "Minimum bid has not been met");
        require(!_auctions[tokenId].claimed, "NFT has already been claimed");

        for (
            uint256 i = 0;
            i < Math.min(_auctions[tokenId].bids.length, _auctions[tokenId].numExtraClaimers + 1);
            i++
        ) {
            if (_auctions[tokenId].bids[i].bidder == msg.sender) {
                require(msg.value == _auctions[tokenId].bids[i].bidPrice, "Incorrect amount of ether sent");

                _auctions[tokenId].claimed = true;
                _approve(msg.sender, tokenId);
                safeTransferFrom(ownerOf(tokenId), msg.sender, tokenId);
                return;
            }
        }

        require(false, "Address did not win auction");
    }

    function allowNextBidderToClaim(uint256 tokenId) public onlyOwner {
        _requireNFTExists(tokenId);
        require(_auctionStarted(tokenId), "Auction has not started");
        require(_auctionEnded(tokenId), "Auction has not ended");
        require(!_auctions[tokenId].claimed, "NFT has already been claimed");

        uint32 numExtraClaimers = _auctions[tokenId].numExtraClaimers + 1;
        require(numExtraClaimers < _auctions[tokenId].bids.length, "All bidders have the ability to claim");

        _auctions[tokenId].numExtraClaimers = numExtraClaimers;
    }

    function numberOfTokens() public view returns (uint256) {
        return _tokenIds.current();
    }

    function auctionInfo(uint256 tokenId) public view returns (PublicAuctionInfo memory) {
        _requireNFTExists(tokenId);

        Bid[] memory activeBids = new Bid[](
            Math.min(_auctions[tokenId].bids.length, _auctions[tokenId].numExtraClaimers + 1)
        );
        for (uint256 i = 0; i < activeBids.length; i++) {
            activeBids[i] = _auctions[tokenId].bids[i];
        }

        return
            PublicAuctionInfo({
                minBidPrice: _nftInfos[tokenId].minBidPrice,
                activeBids: activeBids,
                auctionEndBlock: _auctions[tokenId].endBlock,
                numExtraClaimers: _auctions[tokenId].numExtraClaimers,
                claimed: _auctions[tokenId].claimed
            });
    }

    function updateMinimumBidPrice(uint256 tokenId, uint256 minBidPrice) public onlyOwner {
        _requireNFTExists(tokenId);
        require(!_auctionStarted(tokenId), "Bidding has already started");

        _nftInfos[tokenId].minBidPrice = minBidPrice;
    }

    function updateAuctionDuration(uint256 tokenId, uint32 auctionDurationBlocks) public onlyOwner {
        _requireNFTExists(tokenId);
        require(!_auctions[tokenId].claimed, "NFT has been claimed");
        require(!_auctionStarted(tokenId), "Auction already started. Update auction expiration instead");
        require(auctionDurationBlocks > 0, "Auction must last more than 0 blocks");

        _nftInfos[tokenId].auctionDurationBlocks = auctionDurationBlocks;
    }

    function updateAuctionEndBlock(uint256 tokenId, uint256 auctionEndBlock) public onlyOwner {
        _requireNFTExists(tokenId);
        require(!_auctions[tokenId].claimed, "NFT has been claimed");
        require(_auctionStarted(tokenId), "Auction has not started. Update auction duration instead");
        require(auctionEndBlock != 0, "Auction end block cannot be zero");

        _auctions[tokenId].endBlock = auctionEndBlock;
    }

    function resetAuction(uint256 tokenId) public onlyOwner {
        _requireNFTExists(tokenId);
        require(_auctionStarted(tokenId), "Auction has not started");
        require(!_auctions[tokenId].claimed, "NFT has been claimed");

        delete _auctions[tokenId];
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function sort(Bid[] storage bids) internal {
        quickSort(bids, 0, int256(bids.length - 1));
    }

    function quickSort(
        Bid[] storage bids,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) {
            return;
        }
        uint256 pivot = bids[uint256(left + (right - left) / 2)].bidPrice;
        while (i <= j) {
            while (bids[uint256(i)].bidPrice > pivot) {
                i++;
            }
            while (pivot > bids[uint256(j)].bidPrice) {
                j--;
            }
            if (i <= j) {
                Bid memory iVal = bids[uint256(i)];
                bids[uint256(i)] = bids[uint256(j)];
                bids[uint256(j)] = iVal;
                i++;
                j--;
            }
        }
        if (left < j) {
            quickSort(bids, left, j);
        }
        if (i < right) {
            quickSort(bids, i, right);
        }
    }
}
