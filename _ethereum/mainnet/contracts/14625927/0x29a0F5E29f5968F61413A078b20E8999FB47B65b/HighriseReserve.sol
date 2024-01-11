// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./MerkleProof.sol";

contract HighriseReserve is Ownable {
	constructor(uint8 lowerTokenIdBound_, uint8 upperTokenIdBound_) {
		lowerTokenIdBound = lowerTokenIdBound_;
		upperTokenIdBound = upperTokenIdBound_;
	}

	/**--------------------------
	 * Opening mechanics
	 */
	/// @dev private sale bounds
	bool public isPrivateReserveOpen = false;
	bool public isPublicReserveOpen = false;

	/// @notice toggle private sale open state
	function setIsPrivateReserveOpen(bool isPrivateReserveOpen_)
		public
		onlyOwner
	{
		isPrivateReserveOpen = isPrivateReserveOpen_;
	}

	/// @notice toggle public sale open state
	function setIsPublicReserveOpen(bool isPublicReserveOpen_)
		public
		onlyOwner
	{
		isPublicReserveOpen = isPublicReserveOpen_;
	}

	/**--------------------------
	 * Reserve mechanics
	 */

	/// @dev token bounds
	uint8 lowerTokenIdBound;
	uint8 upperTokenIdBound;
	mapping(address => bool) public reserveAddressMap;
	mapping(address => bool) public claimedTokenMap;
	mapping(uint8 => address) public tokenAddressMap;

	/**
	 * @notice get current reserve
	 * @return list of addresses that have reserved current tokens
	 */
	function getCurrentReserve() public view returns (address[] memory) {
		require(lowerTokenIdBound < upperTokenIdBound, "TOKEN_BOUNDS_ERROR");

		address[] memory currentReserve = new address[](
			upperTokenIdBound - lowerTokenIdBound
		);
		for (uint8 i = 0; i < upperTokenIdBound - lowerTokenIdBound; i++) {
			currentReserve[i] = tokenAddressMap[i];
		}

		return currentReserve;
	}

	/**
	 * @notice set token bounds
	 */
	function setTokenBounds(uint8 lowerTokenIdBound_, uint8 upperTokenIdBound_)
		public
		onlyOwner
	{
		require(lowerTokenIdBound < upperTokenIdBound, "TOKEN_BOUNDS_ERROR");
		lowerTokenIdBound = lowerTokenIdBound_;
		upperTokenIdBound = upperTokenIdBound_;
	}

	/**
	 * @notice check if address is on private reserve
	 * @param privateReserveAddress address on private reserve
	 * @return isPrivateReserve if item is private reserve
	 */
	function checkPrivateReserve(address privateReserveAddress)
		private
		returns (bool)
	{
		if (reserveAddressMap[privateReserveAddress]) {
			reserveAddressMap[privateReserveAddress] = false;
			return true;
		}

		return false;
	}

	/**
	 * @notice set reserve addresses from array
	 * @param addresses addresses to add to reserve mapping
	 */
	function setReserveAddresses(address[] memory addresses) public {
		for (uint8 i = 0; i < addresses.length; i++) {
			reserveAddressMap[addresses[i]] = true;
		}
	}

	/**
	 * @notice reserve token bounds
	 * @param tokenId token id to reserve
	 */
	function reserve(uint8 tokenId) public {
		require(
			tokenId >= lowerTokenIdBound && tokenId <= upperTokenIdBound,
			"TOKEN_OUT_OF_BOUNDS"
		);
		require(tokenAddressMap[tokenId] == address(0), "TOKEN_RESERVED");
		require(
			isPrivateReserveOpen || isPublicReserveOpen,
			"RESERVE_NOT_OPEN"
		);
		require(
			claimedTokenMap[msg.sender] == false,
			"ADDRESS_ALREADY_CLAIMED"
		);

		tokenAddressMap[tokenId] = msg.sender;
		claimedTokenMap[msg.sender] = true;
	}
}
