// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./IUnderlyingStakeable.sol";
import "./IHedron.sol";
import { IHEX } from  "./interfaces/IHEX.sol";
import "./MulticallExtension.sol";
import "./Utils.sol";

abstract contract UnderlyingStakeable is MulticallExtension, IUnderlyingStakeable {
  /**
   * gets the stake store at the provided index
   * @param custodian the custodian (usually this) whose list to check
   * @param index the index of the stake to get
   * @return the stake on the list at the provided index
   */
  function _getStake(
    address custodian, uint256 index
  ) virtual internal view returns(StakeStore memory) {
    return IUnderlyingStakeable(TARGET).stakeLists(custodian, index);
  }
  /**
   * the count of stakes for a given custodian / staker
   * @param staker the custodian in question
   * @return count of the stakes under a given custodian / staker
   */
  function stakeCount(address staker) external view returns(uint256 count) {
    return _stakeCount({
      staker: staker
    });
  }
  /**
   * the count of stakes for a given custodian / staker
   * @param staker the custodian in question
   * @return count of the stakes under a given custodian / staker
   */
  function _stakeCount(address staker) internal view returns(uint256 count) {
    return IUnderlyingStakeable(TARGET).stakeCount(staker);
  }
  function _getStakeCount(address staker) internal view virtual returns(uint256 count) {
    return _stakeCount({
      staker: staker
    });
  }
  /**
   * retrieve the balance of a given owner
   * @param owner the owner of the tokens
   * @return amount a balance amount
   */
  function balanceOf(address owner) external view returns(uint256 amount) {
    return _balanceOf({
      owner: owner
    });
  }
  /**
   * retrieve the balance of a given owner
   * @param owner the owner of the tokens
   * @return amount a balance amount
   */
  function _balanceOf(address owner) internal view returns(uint256 amount) {
    return IERC20(TARGET).balanceOf(owner);
  }
  /**
   * retrieve a stake at a staker's index given a staker address and an index
   * @param staker the staker in question
   * @param index the index to focus on
   * @return stake the stake custodied by a given staker at a given index
   */
  function stakeLists(
    address staker, uint256 index
  ) view external returns(StakeStore memory stake) {
    return _getStake({
      custodian: staker,
      index: index
    });
  }
  /**
   * retrieve the current day from the target contract
   * @return day the current day according to the hex contract
   */
  function currentDay() external view returns (uint256 day) {
    return _currentDay();
  }
  /**
   * retrieve the current day from the target contract
   * @return day the current day according to the hex contract
   */
  function _currentDay() internal view returns(uint256) {
    return IUnderlyingStakeable(TARGET).currentDay();
  }
  /**
   * retrieve the global info from the target contract (hex)
   * updated at the first start or end stake on any given day
   */
  function globalInfo() external view returns(uint256[13] memory) {
    return IUnderlyingStakeable(TARGET).globalInfo();
  }
  /**
   * check whether or not the stake is being ended early
   * @param lockedDay the day after the stake was locked
   * @param stakedDays the number of days that the stake is locked
   * @param targetDay the day to check whether it will be categorized as ending early
   * @return isEarly the locked and staked days are greater than the target day (usually today)
   */
  function isEarlyEnding(
    uint256 lockedDay, uint256 stakedDays, uint256 targetDay
  ) external pure returns(bool isEarly) {
    return _isEarlyEnding({
      lockedDay: lockedDay,
      stakedDays: stakedDays,
      targetDay: targetDay
    });
  }
  /**
   * check whether or not the stake is being ended early
   * @param lockedDay the day after the stake was locked
   * @param stakedDays the number of days that the stake is locked
   * @param targetDay the day to check whether it will be categorized as ending early
   * @return isEarly the locked and staked days are greater than the target day (usually today)
   */
  function _isEarlyEnding(
    uint256 lockedDay,
    uint256 stakedDays,
    uint256 targetDay
  ) internal pure returns(bool isEarly) {
    unchecked {
      return (lockedDay + stakedDays) > targetDay;
    }
  }
  /**
   * starts a stake from the provided amount
   * @param newStakedHearts amount of tokens to stake
   * @param newStakedDays the number of days for this new stake
   * @dev this method interface matches the original underlying token contract
   */
  function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external virtual;
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
  function stakeEnd(uint256 stakeIndex, uint40 stakeId) external virtual;
  function stakeGoodAccounting(
    address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam
  ) external virtual;
}
