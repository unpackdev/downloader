// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title IUnderlyingStakeable
 * @notice this is the minimum interface needed to start and end stakes appropriately on hex
 */
interface IUnderlyingStakeable {
  /** the stake store that holds data about the stake */
  struct StakeStore {
    uint40 stakeId;
    uint72 stakedHearts;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
    uint16 unlockedDay;
    bool isAutoStake;
  }
  /**
   * starts a stake from the provided amount
   * @param newStakedHearts amount of tokens to stake
   * @param newStakedDays the number of days for this new stake
   * @dev this method interface matches the original underlying token contract
   */
  function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;
  /**
   * end your own stake which is custodied by the stake manager. skips tip computing
   * @param stakeIndex the index on the underlying contract to end stake
   * @param stakeId the stake id from the underlying contract to end stake
   * @notice this is not payable to match the underlying contract
   * @notice this moves funds back to the sender to make behavior match underlying token
   * @notice this method only checks that the sender owns the stake it does not care
   * if it is managed in a created contract and externally endable by this contract (1)
   * or requires that the staker send start and end methods (0)
   */
  function stakeEnd(uint256 stakeIndex, uint40 stakeId) external;
  /**
   * freeze the progression of a stake to avoid penalties and preserve payout
   * @param stakerAddr the custoidan of the stake
   * @param stakeIndex the index of the stake in question
   * @param stakeIdParam the id of the stake
   */
  function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam) external;
  /**
   * the count of stakes for a given custodian / staker
   * @param staker the custodian in question
   * @return count of the stakes under a given custodian / staker
   */
  function stakeCount(address staker) external view returns (uint256 count);
  /**
   * retrieve the global info from the target contract (hex)
   * updated at the first start or end stake on any given day
   */
  function globalInfo() external view returns(uint256[13] memory);
  /**
   * retrieve a stake at a staker's index given a staker address and an index
   * @param staker the staker in question
   * @param index the index to focus on
   * @return stake the stake custodied by a given staker at a given index
   */
  function stakeLists(address staker, uint256 index) view external returns(StakeStore memory);
  /**
   * retrieve the current day from the target contract
   * @return day the current day according to the hex contract
   */
  function currentDay() external view returns (uint256);
}
