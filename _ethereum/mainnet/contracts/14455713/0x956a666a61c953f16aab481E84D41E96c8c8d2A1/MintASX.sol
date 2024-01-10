// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./PostDeliveryCrowdsale.sol";

contract MintASX is PostDeliveryCrowdsale, Ownable {
	constructor(
		uint256 _rate,
		address payable _wallet,
		ERC20 _token,
		address _tokenWallet,
		uint256 _openingTime,
		uint256 _closingTime
	)
		Crowdsale(_rate, _wallet, _token)
		AllowanceCrowdsale(_tokenWallet)
		TimedCrowdsale(_openingTime, _closingTime)
	{
		// solhint-disable-previous-line no-empty-blocks
	}

	function extendTime(uint256 newClosingTime) public onlyOwner {
		_extendTime(newClosingTime);
	}

	/**
	 * @dev Extend parent behavior requiring to be within contributing period.
	 * @param beneficiary Token purchaser
	 * @param weiAmount Amount of wei contributed
	 */
	function _preValidatePurchase(address beneficiary, uint256 weiAmount)
		internal
		view
		override
		onlyWhileOpen
	{
		super._preValidatePurchase(beneficiary, weiAmount);
	}

	/**
	 * @dev Overrides parent behavior by transferring tokens from wallet.
	 * @param beneficiary Token purchaser
	 * @param tokenAmount Amount of tokens purchased
	 */
	function _deliverTokens(address beneficiary, uint256 tokenAmount)
		internal
		override
	{
		super._deliverTokens(beneficiary, tokenAmount);
	}
}
