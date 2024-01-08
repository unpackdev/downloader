/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

// BOIS feature bitmask
uint256 constant LEVEL2BOIS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000F;
uint256 constant LEVEL2WOLF = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000F0;

interface ISFTEvaluator {
  /**
   * @dev Returns the reward in 1e6 factor notation (1e6 = 100%)
   */
  function rewardRate(uint256 sftTokenId) external view returns (uint32);

  /**
   * @dev Calculate the current reward rate, and notify TFC in case of change
   *
   * Optional revert on unchange to save gas on external calls.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged) external;
}
