// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IRewardsSchedule.sol";


/**
 * @dev Rewards schedule that distributes 1,500,000 tokens over two years using a linear
 * decay that distributes roughly 1.7 tokens in the first block for every 0.3 tokens in the
 * last block.
 *
 * A value of 13.2 seconds was selected as the average block time to set 4778182 as the number
 * of blocks in 2 years. This has been a stable block time for roughly a year at the time of
 * writing.
 */
contract NDXRewardsSchedule is Ownable, IRewardsSchedule {
  uint256 public immutable override startBlock;
  uint256 public override endBlock;

  constructor(uint256 startBlock_) public Ownable() {
    startBlock = startBlock_;
    endBlock = startBlock_ + 4778181;
  }

  /**
   * @dev Set an early end block for rewards.
   * Note: This can only be called once.
   */
  function setEarlyEndBlock(uint256 earlyEndBlock) external override onlyOwner {
    uint256 endBlock_ = endBlock;
    require(endBlock_ == startBlock + 4778181, "Early end block already set");
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
    // rewards(b) = 0.5336757788 - 0.00000009198010879*b; b >= 0; b < 4778182
    // where b is the block number offset from {startBlock} and the output is multiplied by 1e18.
    return (45990054395 * x**2)
      + (5336757788e8 * (y - x))
      - (45990054395 * y**2);
  }
}

