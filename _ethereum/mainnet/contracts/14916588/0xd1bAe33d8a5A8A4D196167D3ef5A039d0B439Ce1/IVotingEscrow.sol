// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVotingEscrow {
  // Voting escrow to have time-weighted votes
  // Votes have a weight depending on time, so that users are committed
  // to the future of (whatever they are voting for).
  // The weight in this implementation is linear, and lock cannot be more than maxtime:
  // w ^
  // 1 +        /
  //   |      /
  //   |    /
  //   |  /
  //   |/
  // 0 +--------+------> time
  //       maxtime (4 years?)

  struct Point {
    uint256 bias;
    uint256 slope; // # -dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  function user_point_epoch(address addr) external view returns (uint256);

  function epoch() external view returns (uint256);

  function user_point_history(address addr, uint256 loc)
    external
    view
    returns (Point memory);

  function point_history(uint256 loc) external view returns (Point memory);

  function checkpoint() external;
}
