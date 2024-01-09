// SPDX-License-Identifier: MIT
/*
 * HueyAccessControllite.sol
 *
 * Author: Don Huey
 * Created: December 8th, 2021
 *
 * This is an extension of `Ownable` to allow a larger set of addresses to have
 * certain control in the inheriting contracts.
 * goldlist feature as well.
 *
 * This will be a lite version for non-goldlist version
 *
 * Referrenced: KasbeerAccessControl.sol / dev: @jcksber - github
 */

pragma solidity >=0.5.16 <0.9.0;

import "./Ownable.sol"; // "../node_modules/@openzeppelin/contracts/access/Ownable.sol"

contract HueyAccessControllite is Ownable {
	
	// -----
	// Gang
	// -----

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _gang;



}