// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IRewarder.sol";

contract EmptyRewarder is IRewarder {
    function onIOSTReward(uint256 pid, address user, address recipient, uint256 iostAmount, uint256 newLpAmount) override external {
    }
    function pendingTokens(uint256 pid, address user, uint256 iostAmount) override external view returns (IERC20[] memory, uint256[] memory){    
    }
}