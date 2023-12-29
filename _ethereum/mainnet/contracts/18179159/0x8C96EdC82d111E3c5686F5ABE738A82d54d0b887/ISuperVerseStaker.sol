// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	This enum tracks each type of asset that may be operated on with this 
	staker.

	@param ET1155 A staked Elliotrades NFT.
	@param SF1155 A staked SuperFarm NFT.
*/
enum ItemOrigin {
	ET1155,
	SF1155
}

interface ISuperVerseStaker {

	error ItemAlreadyStaked ();

	error ItemNotFound ();

	error AmountExceedsStakedAmount ();

	error RewardPayoutFailed ();

	/**
		Thrown when attempting to withdraw before withdraw buffer has transpired.
	*/
	error WithdrawBufferNotFinished ();
	
	/**
		Thrown when attempting to stake or unstake no tokens and no items.
	*/
	error BadArguments ();

	/**
		Thrown when attempting to rebase before cooldown window is finished.
	*/
	error rebaseWindowClosed ();

	/**
		Thrown when attempting to rebase before cooldown window is finished.
	*/
	error RebaseWindowClosed ();

	/**
	   Emitted on new staking position.
	*/
	event Stake (
		address indexed user,
		uint256 amount,
		uint256 power,
		InputItem[] items
	);

	/** 
	   Emitted on successful reward claim.
	*/
	event Claim (
		address indexed user,
		uint256 amount
	);

	/** 
	   Emitted on successful withdrawal.
	*/
	event Withdraw (
		address indexed user,
		uint256 amount,
		uint256 power,
		InputItem[] items
	);

	/** 
	   Emitted on reward funding.
	*/
	event Fund (
		address indexed user,
		uint256 amount
	);

	/**
	   Input helper struct.
	*/
	struct InputItem {
		uint256 itemId;
		ItemOrigin origin;
	}

	/**
		Stake ERC20 tokens and items from specified collections.  The amount of 
		ERC20 tokens can be zero as long as at least one item is staked.  
		Similarly, the amount of items being staked can be zero as long as the 
		user is staking ERC20 tokens.  Tokens can be staked on a user's behalf,
		provided the caller has the necessary approvals for transfers by the user

		@param _amount The amount of ERC20 tokens being staked
		@param _user The address of the user staking tokens
		@param _items The array of items being staked
	*/
	function stake(
		uint256 _amount,
		address _user,
		InputItem[] calldata _items
	) external;
}