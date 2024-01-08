// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IRewardsSchedule.sol";


/**
 * @dev Rewards schedule that distributes 2,500,000 tokens over 6 months using a linear
 * decay
 *
 * A value of 13.2 seconds was selected as the average block time to set 1194545 as the number
 * of blocks in 6 months. This has been a stable block time for roughly a year at the time of
 * writing.
 */
contract CNJRewardsSchedule is Ownable, IRewardsSchedule {
  uint256 public immutable override startBlock;
  uint256 public override endBlock;

  constructor(uint256 startBlock_) public Ownable() {
  startBlock = startBlock_;
  endBlock = startBlock_ + 1194545;
}

/**
 * @dev Set an early end block for rewards.
 * Note: This can only be called once.
 */
function setEarlyEndBlock(uint256 earlyEndBlock) external override onlyOwner {
  uint256 endBlock_ = endBlock;
  require(endBlock_ == startBlock + 1194545, "Early end block already set");
  require(earlyEndBlock > block.number && earlyEndBlock > startBlock, "End block too early");
  require(earlyEndBlock < endBlock_, "End block too late");
  endBlock = earlyEndBlock;
  emit EarlyEndBlockSet(earlyEndBlock);
}

function getRewardsForBlockRange(uint256 from, uint256 to) external view override returns (uint256) {
  require(to >= from, "Bad block range");
  uint256 endBlock_ = endBlock;
  // If queried range is entirely outside of reward blocks, return 0
  if (from >= endBlock_ || to <= startBlock) return 0;

  // Use start/end values where from/to are OOB
  if (to > endBlock_) to = endBlock_;
  if (from < startBlock) from = startBlock;

  uint256 x = from - startBlock;
  uint256 y = to - startBlock;

  // This formula is the definite integral of the following function:
  // rewards(b) = 2.789765141 -  0.000001166834357*b; b >= 0; b < 1194545
  // where b is the block number offset from {startBlock} and the output is multiplied by 1e18.

  return (583417178500 * x**2)
  + (2789765141e9 * (y - x))
  - (583417178500 * y**2);
  }
}