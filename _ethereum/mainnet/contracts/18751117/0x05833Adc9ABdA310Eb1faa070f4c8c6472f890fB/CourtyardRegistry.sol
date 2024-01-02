// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CourtyardRegistryV3.sol";

/**
 *  @dev pointing to the latest version of {CourtyardRegistry}.
 */
contract CourtyardRegistry is CourtyardRegistryV3 {
	/**
	 * Never add any variables to this contract.
	 * It is just used as a proxy to point to the correct
	 * version of {CourtyardRegistry} without losing the generic
	 * name.
	 */ 
}