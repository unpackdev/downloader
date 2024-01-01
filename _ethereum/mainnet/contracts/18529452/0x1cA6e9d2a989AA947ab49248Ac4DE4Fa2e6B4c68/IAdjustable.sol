// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20.sol";

/**
 * @title IAdjustable
 * @dev Interface for the Adjustable contract. Defines methods to update
 * the contract and events emitted upon update.
 */
interface IAdjustable {
	event Adjust(address indexed beneficiary, int256 amount);
	event SetToken(IERC20 indexed token);
	event SetTotal(uint256 total);
	event SetUri(string indexed uri);

	// Adjust the quantity claimable by a user
	function adjust(address beneficiary, int256 amount) external;

	// Set the token being distributed
	function setToken(IERC20 token) external;

	// Set the total distribution quantity
	function setTotal(uint256 total) external;

	// Set the distributor metadata URI
	function setUri(string memory uri) external;

	// Set the voting power of undistributed tokens
	function setVoteFactor(uint256 setVoteFactor) external;
}
