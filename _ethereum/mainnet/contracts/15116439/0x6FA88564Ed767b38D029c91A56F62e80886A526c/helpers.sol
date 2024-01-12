//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces.sol";
import "./basic.sol";
import "./interfaces.sol";
import "./stores.sol";

abstract contract Helpers is Stores, Basic {
	/**
	 * @dev dexSimulation Address
	 */
	address internal constant dexSimulation =
		0x49B159E897b7701769B1E66061C8dcCd7240c461;
}
