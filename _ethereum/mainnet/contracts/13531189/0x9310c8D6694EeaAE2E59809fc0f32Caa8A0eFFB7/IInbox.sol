// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "./IBridge.sol";

interface IInbox {
	function bridge() external view returns (IBridge);
}
