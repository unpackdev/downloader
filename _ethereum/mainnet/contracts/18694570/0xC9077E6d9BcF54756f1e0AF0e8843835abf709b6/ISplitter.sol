// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISplitter {
	function split() external;
	function pendingOf(address who) external view returns (uint);
}
