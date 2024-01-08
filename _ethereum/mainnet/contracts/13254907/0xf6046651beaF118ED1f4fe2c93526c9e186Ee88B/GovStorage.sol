// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <dev@sherlock.xyz> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import "./IERC20.sol";

library GovStorage {
  bytes32 constant GOV_STORAGE_POSITION = keccak256('diamond.sherlock.gov');

  struct Base {
    // The address appointed as the govMain entity
    address govMain;
    // NOTE: UNUSED
    mapping(bytes32 => address) protocolManagers;
    // Based on the protocol identifier, get the address of the protocol that is able the withdraw balances
    mapping(bytes32 => address) protocolAgents;
    // Check if the protocol is included in the solution at all
    mapping(bytes32 => bool) protocolIsCovered;
    // The array of tokens the accounts are able to stake in
    IERC20[] tokensStaker;
    // The array of tokens the protocol are able to pay premium in
    // These tokens will also be the underlying for SherX
    IERC20[] tokensSherX;
    // The address of the watsons, an account that can receive SherX rewards
    address watsonsAddress;
    // How much sherX is distributed to this account
    // The max value is type(uint16).max, which means 100% of the total SherX minted is allocated to this acocunt
    uint16 watsonsSherxWeight;
    // The last block the total amount of rewards were accrued.
    uint40 watsonsSherxLastAccrued;
    // Max amount of SherX token to be in the `tokensSherX` array
    uint8 maxTokensSherX;
    // Max amount of Staker token to be in the `tokensStaker` array
    uint8 maxTokensStaker;
    // Max amount of protocol to be in single pool
    uint8 maxProtocolPool;
    // The amount of blocks the cooldown period takes
    uint40 unstakeCooldown;
    // The amount of blocks for the window of opportunity of unstaking
    uint40 unstakeWindow;
  }

  function gs() internal pure returns (Base storage gsx) {
    bytes32 position = GOV_STORAGE_POSITION;
    assembly {
      gsx.slot := position
    }
  }
}
