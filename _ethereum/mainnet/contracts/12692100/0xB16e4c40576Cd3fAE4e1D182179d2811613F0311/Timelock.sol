// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./TimelockController.sol";

/**
 * @title Timelock for critical maintenance activities
 * @author Jazzer 9F
 * @notice Thank you @openzeppelin for being awesome
 */
contract Timelock is TimelockController {
  constructor(address[] memory admins)
    TimelockController(86400, admins, admins) {    // 1 day timelock
  }
}
