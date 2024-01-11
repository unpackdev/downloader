// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
  function generateTeenBull() external;
  function generateMergerOrb() external;
  
  function burnTeenBull(uint) external;
}