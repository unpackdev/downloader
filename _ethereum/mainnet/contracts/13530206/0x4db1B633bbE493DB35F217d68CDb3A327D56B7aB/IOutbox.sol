// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

interface IOutbox {
	function l2ToL1Sender() external view returns (address);
}
