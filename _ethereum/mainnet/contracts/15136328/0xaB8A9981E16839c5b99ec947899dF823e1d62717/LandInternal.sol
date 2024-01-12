// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";

import "./ECDSA.sol";
import "./IERC721.sol";

import "./ERC1155NSBase.sol";
import "./ERC1155NSBaseStorage.sol";

import "./OpenSeaProxyRegistry.sol";
import "./OpenSeaProxyStorage.sol";

import "./LandPriceStorage.sol";
import "./LandStorage.sol";
import "./LandTypes.sol";

abstract contract LandInternal is ERC1155NSBase {
	// only allow if mint is active
	modifier mintActive() {
		MintState state = MintState(LandStorage.layout().mintState);
		require(state == MintState.OPEN || state == MintState.PRESALE, "mintActive: not active");
		_;
	}

	// only allow externally owned accounts
	modifier onlyEOA() {
		require(tx.origin == msg.sender, "onlyEOA: caller is contract");
		_;
	}

	// determine if the user is allowed the discounted price for a specific zone
	function _discountAllowed(address to, uint8 zoneId) internal view returns (bool) {
		if (!LandPriceStorage._isDiscountable(zoneId)) {
			return false;
		}

		// ensure they own a lion
		if (
			zoneId == LandStorage._getIndexLionLands() &&
			IERC721(LandStorage.layout().lions).balanceOf(to) > 0
		) {
			return true;
		}
		return false;
	}

	function _isApprovedForAll(address _owner, address operator) public view returns (bool) {
		address proxy1155 = OpenSeaProxyStorage.layout().os1155Proxy;
		if (LibOpenSeaProxy._isApprovedForAll(proxy1155, _owner, operator)) {
			return true;
		}

		address proxy721 = OpenSeaProxyStorage.layout().os721Proxy;
		if (LibOpenSeaProxy._isApprovedForAll(proxy721, _owner, operator)) {
			return true;
		}

		if (LandStorage.layout().proxies[operator]) {
			return true;
		}
		return super.isApprovedForAll(_owner, operator);
	}

	// mint internally
	function _mintInternal(MintRequest memory request) internal {
		Zone memory zone = LandStorage._getZone(request.zoneId);
		Segment memory segment = LandStorage._getSegment(zone, request.segmentId);

		_mintSegment(request.count, segment);

		// update the storage
		LandStorage._addCount(request.zoneId, request.segmentId, request.count);
	}

	// mint many internally for a mint request
	function _mintManyInternal(MintManyRequest memory request) internal {
		for (uint8 i = 0; i < request.zones.length; i++) {
			uint8 zoneId = i + 1;
			SegmentCount memory segmentRequest = request.zones[i];
			_mintSegments(zoneId, segmentRequest);
		}
	}

	// mint all of the sgments in the segment count
	function _mintSegments(uint8 zoneId, SegmentCount memory count) internal {
		Zone memory zone = LandStorage._getZone(zoneId);

		if (count.countOne > 0) {
			_mintSegment(count.countOne, zone.one);
			LandStorage._addCount(zoneId, uint8(Category.ONExONE), count.countOne);
		}

		if (count.countTwo > 0) {
			_mintSegment(count.countTwo, zone.two);
			LandStorage._addCount(zoneId, uint8(Category.TWOxTWO), count.countTwo);
		}

		if (count.countThree > 0) {
			_mintSegment(count.countThree, zone.three);
			LandStorage._addCount(zoneId, uint8(Category.THREExTHREE), count.countThree);
		}

		if (count.countFour > 0) {
			_mintSegment(count.countFour, zone.four);
			LandStorage._addCount(zoneId, uint8(Category.SIXxSIX), count.countFour);
		}
	}

	// mint a specific segment
	function _mintSegment(uint16 amount, Segment memory segment) internal {
		require(amount > 0, "invalid amount");
		require(segment.count + amount <= segment.max, "sold out");

		uint64 start = segment.startIndex + segment.count;
		uint64 end = start + amount;

		_mintAsERC721(start, end);
	}

	// mint as an ERC721
	function _mintAsERC721(uint64 start, uint64 end) internal {
		unchecked {
			for (start; start < end; ) {
				// Since this is treated like a 721, the only valid assignment is 1
				// and since we don't allow smart contracts
				// we can just update the storage slot directly
				ERC1155NSBaseStorage.layout().balances[start][_msgSender()] = 1;
				emit TransferSingle(_msgSender(), address(0), _msgSender(), start, 1);
				start++;
			}
		}
	}

	// get the combined counts of each type for all requested segments
	function _getSegmentCounts(MintManyRequest memory request)
		internal
		pure
		returns (SegmentCount memory segment)
	{
		for (uint8 i = 0; i < request.zones.length; i++) {
			SegmentCount memory segmentRequest = request.zones[i];
			segment.countOne += segmentRequest.countOne;
			segment.countTwo += segmentRequest.countTwo;
			segment.countThree += segmentRequest.countThree;
			segment.countFour += segmentRequest.countFour;
		}
		return segment;
	}

	// get the cost for a segment (it may be the combined segment)
	function _getCost(SegmentCount memory segment) internal view returns (uint256) {
		SegmentPrice memory price = LandPriceStorage._getPrice();
		return _getCost(segment, price);
	}

	function _getCost(SegmentCount memory segment, SegmentPrice memory price)
		internal
		pure
		returns (uint256)
	{
		return
			(uint256(price.one) * segment.countOne) +
			(uint256(price.two) * segment.countTwo) +
			(uint256(price.three) * segment.countThree) +
			(uint256(price.four) * segment.countFour);
	}

	// get the discounted cost for a user and their request
	function _getCostDiscount(address to, MintManyRequest memory request)
		internal
		view
		returns (uint256)
	{
		SegmentPrice memory price = LandPriceStorage._getPrice();

		uint256 cost = 0;
		for (uint8 i = 0; i < request.zones.length; i++) {
			uint8 zoneId = i + 1;
			if (_discountAllowed(to, zoneId)) {
				// get the cost discount for a zoneId and a specific segment count request
				SegmentPrice memory discountPrice = LandPriceStorage._getDiscountPrice(zoneId);
				cost += _getCost(request.zones[i], discountPrice);
			} else {
				cost += _getCost((request.zones[i]), price);
			}
		}
		return cost;
	}

	// hash mint many using EIP-191. loops through the request hasing the previous iteration
	function _hashMintMany(MintManyRequest memory request) internal pure returns (bytes32) {
		bytes32 keccakHash = keccak256(abi.encodePacked(request.to, request.deadline));
		for (uint8 i = 0; i < request.zones.length; i++) {
			uint8 zoneId = i + 1;
			SegmentCount memory segmentRequest = request.zones[i];
			keccakHash = keccak256(
				abi.encodePacked(
					keccakHash,
					zoneId,
					segmentRequest.countOne,
					segmentRequest.countTwo,
					segmentRequest.countThree,
					segmentRequest.countFour
				)
			);
		}

		return ECDSA.toEthSignedMessageHash(keccakHash);
	}

	function _hashMint(MintRequest memory request) internal pure returns (bytes32) {
		return
			ECDSA.toEthSignedMessageHash(
				keccak256(
					abi.encodePacked(
						request.to,
						request.deadline,
						request.zoneId,
						request.segmentId,
						request.count
					)
				)
			);
	}

	function _verifyMint(bytes32 digest, bytes memory signature) internal view returns (bool) {
		return LandStorage.layout().signer == ECDSA.recover(digest, signature);
	}
}
