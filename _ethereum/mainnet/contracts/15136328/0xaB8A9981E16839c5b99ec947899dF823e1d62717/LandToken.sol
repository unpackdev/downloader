// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC165.sol";
import "./IERC721.sol";
//import "./ERC1155NSBase.sol";

import "./OpenSeaProxyRegistry.sol";
import "./OpenSeaProxyStorage.sol";

import "./LandTypes.sol";
import "./LandInternal.sol";

import "./LandStorage.sol";
import "./LandPriceStorage.sol";

contract LandToken is LandInternal, ERC165 {
	function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
		return _isApprovedForAll(_owner, operator);
	}

	function versionRecipient() external view virtual override returns (string memory) {
		return "2.2.5";
	}

	function canMint(MintRequest memory request, bytes calldata signature)
		public
		view
		mintActive
		onlyEOA
		returns (bool isValid)
	{
		require(_verifyMint(_hashMint(request), signature), "canMint: invalid signature");
		require(_msgSender() == request.to, "canMint: not buyer");
		// note: the timestamp is not exact, so do not rely on this for sub-block precision
		// note: https://docs.soliditylang.org/en/v0.8.14/cheatsheet.html?highlight=timestamp#global-variables
		// slither-disable-next-line timestamp
		// solhint-disable-next-line not-rely-on-time
		require(request.deadline > block.timestamp, "canMint: signature expired");
		return true;
	}

	function canMintMany(MintManyRequest memory request, bytes calldata signature)
		public
		view
		mintActive
		onlyEOA
		returns (bool isValid)
	{
		require(_verifyMint(_hashMintMany(request), signature), "canMintMany: invalid signature");
		require(_msgSender() == request.to, "canMintMany: not buyer");
		// slither-disable-next-line timestamp
		// solhint-disable-next-line not-rely-on-time
		require(request.deadline > block.timestamp, "canMintMany: signature expired");
		require(request.zones.length <= LandStorage._getZoneIndex(), "canMintMany: wrong index");
		return true;
	}

	/**
	 * Mint in a specific zone for a count
	 */
	function mint(MintRequest memory request, bytes calldata signature) external payable {
		require(canMint(request, signature), "mint: invalid");

		uint256 price = LandPriceStorage._getPrice(request.segmentId);
		require(msg.value == price * request.count, "mint: wrong price");

		_mintInternal(request);
	}

	/**
	 * mint using the discount price
	 */
	function mintDiscount(MintRequest memory request, bytes calldata signature) external payable {
		require(canMint(request, signature), "mintDiscount: invalid");
		require(_discountAllowed(_msgSender(), request.zoneId), "mintDiscount: invalid zone");

		uint256 price = LandPriceStorage._getDiscountPrice(request.zoneId, request.segmentId);
		require(msg.value == price * request.count, "mintDiscount: wrong price");

		_mintInternal(request);
	}

	/**
	 * Mint many. Expects an ordered array of zones & segment count quantities
	 */
	function mintMany(MintManyRequest memory request, bytes calldata signature) external payable {
		require(canMintMany(request, signature), "mintMany: invalid");

		SegmentCount memory segment = _getSegmentCounts(request);
		require(msg.value == _getCost(segment), "mintMany: wrong price");

		_mintManyInternal(request);
	}

	/**
	 * Mint many using the discount price where possible.
	 */
	function mintManyDiscount(MintManyRequest memory request, bytes calldata signature)
		external
		payable
	{
		require(canMintMany(request, signature), "mintManyDiscount: invalid");
		require(msg.value == _getCostDiscount(_msgSender(), request), "mintManyDiscount: wrong price");

		_mintManyInternal(request);
	}
}
