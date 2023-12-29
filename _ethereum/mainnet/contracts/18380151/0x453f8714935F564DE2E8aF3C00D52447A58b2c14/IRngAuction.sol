// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNGInterface.sol";

interface IRngAuction {
    function startRngRequest(address _rewardRecipient) external;
    function getNextRngService() external view returns (RNGInterface);
}