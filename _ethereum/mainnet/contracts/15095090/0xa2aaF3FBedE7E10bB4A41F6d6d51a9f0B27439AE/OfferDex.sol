// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IXanaliaNFT.sol";
import "./IXanaliaAddressesStorage.sol";

contract OfferDex is Initializable, OwnableUpgradeable {
	uint256 public totalOffers;
	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	struct Offer {
		address offerOwner;
		address paymentToken;
		address collectionAddress;
		uint256 tokenId;
		uint256 offerPrice;
		uint256 expireTime;
		bool isOwnerAcceptOffer;
		bool status;
	}

	mapping(uint256 => Offer) public offers;

	function initialize(address _xanaliaAddressesStorage) public initializer {
		__Ownable_init_unchained();
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}

	modifier onlyXanaliaDex() {
		require(msg.sender == xanaliaAddressesStorage.xanaliaDex(), "Xanalia: caller is not xanalia dex");
		_;
	}

	function makeOffer(
		address _collectionAddress,
		address _paymentToken,
		address _offerOwner,
		uint256 _tokenId,
		uint256 _price,
		uint256 _expireTime
	) external onlyXanaliaDex returns (uint256 _offerId) {
		Offer memory newOffer;
		newOffer.offerOwner = _offerOwner;
		newOffer.offerPrice = _price;
		newOffer.tokenId = _tokenId;
		newOffer.collectionAddress = _collectionAddress;
		newOffer.paymentToken = _paymentToken;
		newOffer.isOwnerAcceptOffer = false;
		newOffer.status = true;
		newOffer.expireTime = _expireTime;

		totalOffers++;
		offers[totalOffers] = newOffer;

		return totalOffers;
	}

	function acceptOffer(uint256 _offerId)
		external
		onlyXanaliaDex
		returns (
			address,
			address,
			address,
			uint256,
			uint256
		)
	{
		Offer storage offer = offers[_offerId];
		require(block.timestamp < offer.expireTime && offer.status, "Offer-expired-or-cancelled");

		require(!offer.isOwnerAcceptOffer, "Offer-accepted");

		offer.isOwnerAcceptOffer = true;
		offer.status = false;

		return (offer.offerOwner, offer.paymentToken, offer.collectionAddress, offer.tokenId, offer.offerPrice);
	}

	function cancelOffer(uint256 _offerId, address _offerOwner) external onlyXanaliaDex returns (address, uint256) {
		Offer storage offer = offers[_offerId];
		require(offer.offerOwner == _offerOwner, "Not-offer-owner");
		require(offer.status, "Offer-cancelled");

		offer.status = false;
		offers[_offerId] = offer;

		return (offer.paymentToken, offer.offerPrice);
	}

	function setAddressesStorage(address _xanaliaAddressesStorage) external onlyOwner {
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}
}
