// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface INounsParty {
	struct Deposit {
		address owner;
		uint256 amount;
	}

	struct TokenClaim {
		uint256 nounId;
		uint256 tokens;
	}

	enum NounStatus {
		WON,
		BURNED,
		MINTED,
		LOST,
		NOTFOUND
	}

	event LogWithdraw(address sender, uint256 amount);

	event LogFractionalize(uint256 indexed nounId, uint256 supply, uint256 fee);

	event LogClaim(address sender, uint256 nounId, address fracTokenVaultAddress, uint256 tokens);

	event LogSettleWon(uint256 nounId);

	event LogSettleLost(uint256 nounId);

	event LogDeposit(address sender, uint256 amount);

	event LogBid(uint256 indexed nounId, uint256 amount, address sender);

	event LogSetNounsPartyFee(uint256 fee);

	event LogBidIncrease(uint256 bidIncrease);

	event LogAllowBid(bool allow);

	event LogNounsAuctionHouseBidIncrease(uint256 bidIncrease);

	event LogPause();

	event LogUnpause();
}
