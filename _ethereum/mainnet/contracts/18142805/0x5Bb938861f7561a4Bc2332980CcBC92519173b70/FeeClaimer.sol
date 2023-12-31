// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Auction.sol";

contract FeeClaimer {

	address public owner;

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Must be owner of contract to execute");
		_;
	}

	function setOwner(address newOwner) onlyOwner public {
		owner = newOwner;
	}

	function claimFees(address auction, uint256[] calldata auctionIds, address recipient) onlyOwner public {
		for (uint i = 0; i < auctionIds.length; i++) {
			Auction(auction).confirmAuction(auctionIds[ i ], recipient);
		}
	}
}
