// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IXanaliaNFT.sol";
import "./IXanaliaAddressesStorage.sol";

contract AuctionDex is Initializable, OwnableUpgradeable {
	uint256 public constant BASE_DENOMINATOR = 10_000;
	uint256 public constant MINIMUM_BID_RATE = 500;
	uint256 public totalAuctions;
	uint256 public totalBidAuctions;

	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	struct Auction {
		address owner;
		address collectionAddress;
		address paymentToken;
		uint256 tokenId;
		uint256 startPrice;
		uint256 startTime;
		uint256 endTime;
		uint256[] listBidId;
	}

	struct BidAuction {
		address bidder;
		address paymentToken;
		address collectionAddress;
		uint256 tokenId;
		uint256 auctionId;
		uint256 bidPrice;
		bool status;
		bool isOwnerAccepted;
		uint256 expireTime;
	}

	mapping(uint256 => Auction) public auctions;
	mapping(uint256 => BidAuction) public bidAuctions;

	mapping(address => mapping(uint256 => bool)) public tokenOnAuction; //collectionAddress => tokenId => bool

	mapping(uint256 => uint256) public auctionHighestBidId; //auctionId => bidId

	mapping(uint256 => uint256) public auctionBidCount;

	function initialize(address _xanaliaAddressesStorage) public initializer {
		__Ownable_init_unchained();
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}

	modifier onlyXanaliaDex() {
		require(msg.sender == xanaliaAddressesStorage.xanaliaDex(), "Xanalia: caller is not xanalia dex");
		_;
	}

	receive() external payable {}

	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external onlyXanaliaDex returns (uint256 _auctionId) {
		totalAuctions++;
		_auctionId = totalAuctions;

		tokenOnAuction[_collectionAddress][_tokenId] = true;

		Auction storage newAuction = auctions[_auctionId];

		newAuction.owner = _itemOwner;
		newAuction.collectionAddress = _collectionAddress;
		newAuction.paymentToken = _paymentToken;
		newAuction.tokenId = _tokenId;
		newAuction.startPrice = _startPrice;
		newAuction.startTime = _startTime;
		newAuction.endTime = _endTime;

		return _auctionId;
	}

	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		address _bidOwner,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external onlyXanaliaDex returns (uint256 _bidAuctionId) {
		Auction storage currentAuction = auctions[_auctionId];
		require(currentAuction.paymentToken == _paymentToken, "Incorrect-payment-method");
		require(currentAuction.owner != _bidOwner, "Owner-can-not-bid");
		require(
			block.timestamp >= currentAuction.startTime && block.timestamp <= currentAuction.endTime,
			"Not-in-auction-time"
		);

		if (bidAuctions[auctionHighestBidId[_auctionId]].bidPrice == 0) {
			require(_price >= currentAuction.startPrice, "Price-lower-than-start-price");
		} else {
			uint256 highestPrice = bidAuctions[auctionHighestBidId[_auctionId]].bidPrice;
			require(
				_price >= highestPrice + ((highestPrice * MINIMUM_BID_RATE) / BASE_DENOMINATOR),
				"Price-bid-less-than-max-price"
			);
		}

		require(tokenOnAuction[_collectionAddress][_tokenId], "Auction-closed");

		auctionBidCount[_auctionId] += 1;

		BidAuction memory newBidAuction;
		newBidAuction.bidder = _bidOwner;
		newBidAuction.bidPrice = _price;
		newBidAuction.tokenId = _tokenId;
		newBidAuction.auctionId = _auctionId;
		newBidAuction.collectionAddress = _collectionAddress;
		newBidAuction.status = true;
		newBidAuction.isOwnerAccepted = false;
		newBidAuction.paymentToken = _paymentToken;
		newBidAuction.expireTime = _expireTime;

		totalBidAuctions++;

		bidAuctions[totalBidAuctions] = newBidAuction;
		_bidAuctionId = totalBidAuctions;

		currentAuction.listBidId.push(_bidAuctionId);

		auctionHighestBidId[_auctionId] = _bidAuctionId;

		return _bidAuctionId;
	}

	function cancelAuction(
		uint256 _auctionId,
		address _auctionOwner,
		bool _isAcceptOffer
	) external onlyXanaliaDex returns (uint256) {
		require(auctions[_auctionId].owner == _auctionOwner, "Not-auction-owner");

		Auction storage currentAuction = auctions[_auctionId];
		bool isTokenOnAuction = tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId];

		if (_isAcceptOffer) {
			if (isTokenOnAuction) {
				tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId] = false;
			}
			return _auctionId;
		} else {
			require(isTokenOnAuction, "Auction-cancelled");
			require(currentAuction.endTime > block.timestamp, "Auction-ended");

			tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId] = false;
		}

		return _auctionId;
	}

	function cancelBidAuction(uint256 _bidAuctionId, address _auctionOwner)
		external
		onlyXanaliaDex
		returns (
			uint256,
			uint256,
			address
		)
	{
		BidAuction storage currentBid = bidAuctions[_bidAuctionId];
		Auction storage currentAuction = auctions[currentBid.auctionId];

		require(currentBid.status, "Bid-cancelled");
		require(_auctionOwner == currentBid.bidder, "Not-owner-of-bid-auction");

		currentBid.status = false;
		// Set new highest bid if highest bid is cancelled
		if (bidAuctions[auctionHighestBidId[currentBid.auctionId]].bidPrice == currentBid.bidPrice) {
			uint256 newHighestBidId;
			BidAuction memory bidInfo;
			if (currentAuction.listBidId.length == 1) {
				newHighestBidId = 0;
			} else {
				for (uint256 i = currentAuction.listBidId.length - 2; i >= 0; i--) {
					bidInfo = bidAuctions[currentAuction.listBidId[i]];
					if (bidInfo.status == true) {
						newHighestBidId = currentAuction.listBidId[i];
						break;
					}
					if (i == 0) break;
				}
				if (newHighestBidId == auctionHighestBidId[currentBid.auctionId]) {
					newHighestBidId = 0;
				}
			}
			auctionHighestBidId[currentBid.auctionId] = newHighestBidId;
		}

		return (_bidAuctionId, currentBid.bidPrice, currentBid.paymentToken);
	}

	function reclaimAuction(uint256 _auctionId, address _auctionOwner)
		external
		onlyXanaliaDex
		returns (address, uint256)
	{
		Auction memory currentAuction = auctions[_auctionId];

		require(
			currentAuction.endTime < block.timestamp ||
				!tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId],
			"Auction-not-end-or-cancelled"
		);
		require(currentAuction.owner == _auctionOwner, "Not-auction-owner");

		tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId] = false;

		return (currentAuction.collectionAddress, currentAuction.tokenId);
	}

	function acceptBidAuction(uint256 _bidAuctionId, address _auctionOwner)
		external
		onlyXanaliaDex
		returns (
			uint256,
			address,
			address,
			uint256,
			address,
			address
		)
	{
		BidAuction storage currentBid = bidAuctions[_bidAuctionId];
		Auction memory currentAuction = auctions[currentBid.auctionId];
		require(currentAuction.owner == _auctionOwner, "Not-owner-of-auction");
		require(block.timestamp < currentBid.expireTime && currentBid.status, "Bid-expired-or-cancelled");

		require(currentBid.bidPrice >= currentAuction.startPrice, "Bid-not-valid");

		require(!currentBid.isOwnerAccepted, "Bid-accepted");

		currentBid.isOwnerAccepted = true;
		tokenOnAuction[currentBid.collectionAddress][currentBid.tokenId] = false;

		return (
			currentBid.bidPrice,
			currentBid.collectionAddress,
			currentBid.paymentToken,
			currentBid.tokenId,
			currentAuction.owner,
			currentBid.bidder
		);
	}

	function setAddressesStorage(address _xanaliaAddressesStorage) external onlyOwner {
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}
}
