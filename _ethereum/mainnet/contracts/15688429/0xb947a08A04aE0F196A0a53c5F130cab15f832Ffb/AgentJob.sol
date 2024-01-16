// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract AgentJob {
  address public agent;

  modifier onlyAgent() {
    require(msg.sender == agent);
    _;
  }

  constructor(address agent_) {
    agent = agent_;
  }

  fallback() external virtual {
    revert("AgentJob: unexpected fallback");
  }
}
