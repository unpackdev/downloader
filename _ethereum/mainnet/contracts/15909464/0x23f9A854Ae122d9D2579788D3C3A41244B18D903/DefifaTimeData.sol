// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JB721TierParams.sol";

/**
  @member mintDuration The amount of time mints will be open for before the game's start.
  @member start The timestamp at which the game should start.
  @member tradeDeadline The timestamp at which the game's trade deadline should begin.
  @member end The timestamp at which the game should end.
*/
struct DefifaTimeData {
  uint48 mintDuration;
  uint48 start;
  uint48 tradeDeadline;
  uint48 end;
}
