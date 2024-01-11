// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DataTypes.sol";
import "./ReserveLogic.sol";


contract LendingPoolStorage {
	using ReserveLogic for DataTypes.ReserveData;

	mapping(address => DataTypes.ReserveData) internal _reserves;

	//the list of the available reserves, structured as a mapping for gas savings reasons
	mapping(uint256 => address) _reservesList;

	uint256 internal _reservesCount;

	bool internal _paused;

}