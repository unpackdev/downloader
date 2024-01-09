// SPDX-License-Identifier: MIT
/*
 * HueyAccessControlnoGold.sol
 *
 * Author: Don Huey
 * Created: December 8th, 2021
 *
 * This is an extension of `Ownable` to allow a larger set of addresses to have
 * certain control in the inheriting contracts.
 * goldlist feature as well.
 *
 * Referrenced: KasbeerAccessControl.sol / dev: @jcksber - github
 */

pragma solidity >=0.5.16 <0.9.0;

import "./Ownable.sol"; // "../node_modules/@openzeppelin/contracts/access/Ownable.sol"

contract HueyAccessControlnoGold is Ownable {
	
	// -----
	// Gang
	// -----

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _gang;

	//@dev Custom "approved" modifier because I don't like that language (Jack is right, the language sucks.)
	modifier isGang()
	{
		require(isInGang(msg.sender), "HueyAccessControl: Caller not part of gang.");
		_;
	}

	//@dev Determine if address `addy` is an approved owner
	function isInGang(address addy) 
		public view returns (bool) 
	{
		return _gang[addy];
	}

	//@dev Add `addy` to the gang
	function addToGang(address addy)
		onlyOwner public
	{
		require(!isInGang(addy), "HueyAccessControl: Address already in gang.");
		_gang[addy] = true;
	}

}