// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

interface IWrappable {
	function wrap(uint256 _amount) external returns (bool);

	function unwrap(uint256 _amount) external returns (bool);
}
