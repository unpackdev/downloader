// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./VRFIntegration.sol";

contract RandomTest is Ownable, VRFIntegration {
  constructor(
    address coordinator,
    bytes32 keyHash,
    uint64 subscriptionId
  ) VRFIntegration(coordinator, keyHash, subscriptionId) {}

  function resetRandomRequest() external onlyOwner {
    randomSeedSettled = false;
  }
}