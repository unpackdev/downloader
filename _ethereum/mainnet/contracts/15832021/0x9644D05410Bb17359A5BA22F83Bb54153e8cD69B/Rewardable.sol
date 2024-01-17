// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Context.sol";
import "./INST.sol";

abstract contract Rewardable is Ownable {

  INST public yieldToken;

  function setYieldToken(address _yield) external onlyOwner {
		yieldToken = INST(_yield);
	}
}