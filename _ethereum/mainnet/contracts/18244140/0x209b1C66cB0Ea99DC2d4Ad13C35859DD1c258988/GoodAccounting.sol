// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IHEX.sol";
import "./UnderlyingStakeable.sol";
import "./Bank.sol";
import "./Tipper.sol";

abstract contract GoodAccounting is Tipper {
  /**
   * check that the provided stake can be ended and end it
   * @param stakeId the stake id to end as custodied by this contract
   */
  function checkAndDoStakeGoodAccounting(uint256 stakeId) external {
    _checkAndDoStakeGoodAccounting({
      staker: address(this),
      index: _stakeIdToIndex(stakeId),
      stakeId: stakeId
    });
  }
  /**
   * check that the stake can be good accounted, and execute the method if it will not fail
   * @param staker the custodian of the provided stake
   * @param index the index of the stake
   * @param stakeId the stake id of the stake
   */
  function checkAndDoStakeGoodAccountingFor(address staker, uint256 index, uint256 stakeId) external {
    _checkAndDoStakeGoodAccounting({
      staker: staker,
      index: index,
      stakeId: stakeId
    });
  }
  /**
   * run the appropriate checks if the stake is good accountable.
   * return 0 if it can be good accounted
   * return other numbers for those failed conditions
   * @param staker the custodian of the provided stake
   * @param index the index of the stake
   * @param stakeId the stake id of the stake
   */
  function isGoodAccountable(
    address staker,
    uint256 index,
    uint256 stakeId
  ) external view returns(GoodAccountingStatus) {
    return _isGoodAccountable({
      staker: staker,
      index: index,
      stakeId: stakeId
    });
  }
  function isStakeIdGoodAccountable(uint256 stakeId) external view returns(GoodAccountingStatus) {
    return _isGoodAccountable({
      staker: address(this),
      index: _stakeIdToIndex({
        stakeId: stakeId
      }),
      stakeId: stakeId
    });
  }
  enum GoodAccountingStatus {
    READY,
    ENDED,
    EARLY,
    MISMATCH,
    MISCOUNT
  }
  function _isGoodAccountable(
    address staker,
    uint256 index,
    uint256 stakeId
  ) internal view returns(GoodAccountingStatus) {
    uint256 count = IHEX(TARGET).stakeCount(staker);
    if (index >= count) {
      return GoodAccountingStatus.MISCOUNT;
    }
    StakeStore memory stake = _getStake({
      custodian: staker,
      index: index
    });
    if (stake.stakeId != stakeId) {
      // the stake id does not match
      return GoodAccountingStatus.MISMATCH;
    }
    if (_isEarlyEnding({
      lockedDay: stake.lockedDay,
      stakedDays: stake.stakedDays,
      targetDay: IHEX(TARGET).currentDay()
    })) {
      // return if it is too early to run good accounting
      return GoodAccountingStatus.EARLY;
    }
    if (stake.unlockedDay > ZERO) {
      // the stake has already been ended
      return GoodAccountingStatus.ENDED;
    }
    return GoodAccountingStatus.READY;
  }
  function _checkAndDoStakeGoodAccounting(address staker, uint256 index, uint256 stakeId) internal {
    if (_isGoodAccountable({
      staker: staker,
      index: index,
      stakeId: stakeId
    }) == GoodAccountingStatus.READY) {
      _stakeGoodAccounting({
        stakerAddr: staker,
        stakeIndex: index,
        stakeIdParam: stakeId
      });
    }
  }
  /**
   * freeze the progression of a stake to avoid penalties and preserve payout
   * @param stakerAddr the originating stake address
   * @param stakeIndex the index of the stake on the address
   * @param stakeIdParam the stake id to verify the same stake is being targeted
   */
  function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam) external override {
    _stakeGoodAccounting({
      stakerAddr: stakerAddr,
      stakeIndex: stakeIndex,
      stakeIdParam: stakeIdParam
    });
  }
  /**
   * freeze the progression of a stake to avoid penalties and preserve payout
   * @param stakerAddr the originating stake address
   * @param stakeIndex the index of the stake on the address
   * @param stakeIdParam the stake id to verify the same stake is being targeted
   */
  function _stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint256 stakeIdParam) internal {
    // no data is marked during good accounting, only computed and placed into logs
    // so we cannot return anything useful to the caller of this method
    UnderlyingStakeable(TARGET).stakeGoodAccounting(stakerAddr, stakeIndex, uint40(stakeIdParam));
  }
}
