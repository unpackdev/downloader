// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface INounsAuctionHouse {
	struct Auction {
		uint256 nounId;
		uint256 amount;
		uint256 startTime;
		uint256 endTime;
		address payable bidder;
		bool settled;
	}

	function createBid(uint256 nounId) external payable;

	function auction()
		external
		view
		returns (
			uint256, // nounId
			uint256, // amount
			uint256, // startTime
			uint256, // endTime
			address payable, // bidder
			bool // settled
		);
}
