// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "./Ownable2Step.sol";

contract Ownable2StepNoRenounce is Ownable2Step {
	function renounceOwnership() public override onlyOwner {
		revert("FW601");
	}
}
