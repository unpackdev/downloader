// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

library BeforeAwardListenerControlledLibrary {
  /*
    *     bytes4(keccak256('beforePrizePoolAwarded(uint256)')) == 0x157ef198
    */
  bytes4 public constant ERC165_INTERFACE_ID_BEFORE_AWARD_LISTENER = 0x157ef198;
}