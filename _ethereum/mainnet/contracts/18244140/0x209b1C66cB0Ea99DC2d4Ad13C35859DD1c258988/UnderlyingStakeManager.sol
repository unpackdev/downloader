// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./GoodAccounting.sol";
import "./UnderlyingStakeable.sol";

contract UnderlyingStakeManager is GoodAccounting {
  /**
   * start a stake for the staker given the amount and number of days
   * @param owner the underlying owner of the stake
   * @param amount the amount to add to the stake
   * @param newStakedDays the number of days that the stake should run
   * @param index where in the list the stake will be placed.
   * this is a param because it can be cached for internal loops
   */
  function _stakeStartFor(
    address owner,
    uint256 amount,
    uint256 newStakedDays,
    uint256 index
  ) internal virtual returns(uint256 stakeId) {
    UnderlyingStakeable(TARGET).stakeStart(amount, newStakedDays);
    // get the stake id
    stakeId = UnderlyingStakeable(TARGET).stakeLists(address(this), index).stakeId;
    stakeIdInfo[stakeId] = _encodeInfo({
      index: index,
      owner: owner
    });
  }
  /**
   * ends a stake for someone else
   * @param stakeIndex the stake index on the underlying contract to end
   * @param stakeId the stake id on the underlying contract to end
   * @param stakeCountAfter the stake count after the stake is ended (current length - 1)
   * @return delta the number of tokens that have been received from ending the stake
   */
  function _stakeEnd(
    uint256 stakeIndex, uint256 stakeId, uint256 stakeCountAfter
  ) internal virtual returns(uint256 delta) {
    // calculate the balance before
    // cannot use tokens attributed here because of tipping
    uint256 balanceBefore = _balanceOf({
      owner: address(this)
    });
    // end the stake - attributed to contract or through the managed stake
    UnderlyingStakeable(TARGET).stakeEnd(stakeIndex, uint40(stakeId));
    // for the last stake in this list, this branch will not be hit
    if (stakeCountAfter > stakeIndex) {
      uint256 shiftingStakeId = _getStake({
        custodian: address(this),
        index: stakeIndex
      }).stakeId;
      uint256 stakeInfo = stakeIdInfo[shiftingStakeId];
      stakeIdInfo[shiftingStakeId] = _encodeInfo({
        index: stakeIndex,
        owner: address(uint160(stakeInfo))
      });
    }
    // because the delta is only available in the logs
    // we need to calculate the delta to use it
    unchecked {
      delta = _balanceOf({
        owner: address(this)
      }) - balanceBefore;
    }
    stakeIdInfo[stakeId] = ZERO;
  }
  /**
   * starts a stake from the provided amount
   * @param amount amount of tokens to stake
   * @param newStakedDays the number of days for this new stake
   * @dev this method interface matches the original underlying token contract
   */
  function stakeStart(uint256 amount, uint256 newStakedDays) external override virtual {
    // ensures amount under/from sender is sufficient
    _depositTokenFrom({
      token: TARGET,
      depositor: msg.sender,
      amount: amount
    });
    _stakeStartFor({
      owner: msg.sender,
      amount: amount,
      newStakedDays: newStakedDays,
      index: _getStakeCount({
        staker: address(this)
      })
    });
  }
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
  function stakeEnd(uint256 stakeIndex, uint40 stakeId) external override virtual {
    _stakeEndByIndexAndId(stakeIndex, stakeId);
  }
  /**
   * end a stake given its index and id
   * @param stakeIndex the index of the stake to end
   * @param stakeId the stake id to end
   */
  function _stakeEndByIndexAndId(
    uint256 stakeIndex, uint256 stakeId
  ) internal virtual returns(uint256 amount) {
    _verifyStakeOwnership({
      owner: msg.sender,
      stakeId: stakeId
    });
    amount = _stakeEnd({
      stakeIndex: stakeIndex,
      stakeId: stakeId,
      stakeCountAfter: _getStakeCount({
        staker: address(this)
      }) - ONE
    });
    _withdrawTokenTo({
      token: TARGET,
      to: payable(msg.sender),
      amount: amount
    });
  }
  /**
   * end your own stake which is custodied by the stake manager. skips tip computing
   * @param stakeId the stake id from the underlying contract to end stake
   * @notice this is not payable to match the underlying contract
   * @notice this moves funds back to the sender to make behavior match underlying token
   * @notice this method only checks that the sender owns the stake it does not care
   * if it is managed in a created contract and externally endable by this contract (1)
   * or requires that the staker send start and end methods (0)
   */
  function stakeEndById(uint256 stakeId) external virtual returns(uint256 amount) {
    (uint256 stakeIndex, ) = _stakeIdToInfo({
      stakeId: stakeId
    });
    return _stakeEndByIndexAndId(stakeIndex, stakeId);
  }
  function _getStakeInfo(uint256 stakeId) internal view virtual returns(
    bool valid,
    address staker,
    uint256 stakeIndex,
    UnderlyingStakeable.StakeStore memory stake
  ) {
    (stakeIndex, staker) = _stakeIdToInfo(stakeId);
    if (staker == address(0)) {
      return (valid, staker, stakeIndex, stake);
    }
    stake = _getStake({
      custodian: address(this),
      index: stakeIndex
    });
    valid = stake.stakeId == stakeId;
  }
  /**
   * given ownership over a stake, end the stake
   * and restart all of the proceeds
   * @param stakeId the stake id to restart
   * @return amount the amount ended and re-staked
   * @return newStakeId the newly recreated stake id
   */
  function _stakeRestartById(uint256 stakeId) internal returns(
    uint256 amount, uint256 newStakeId
  ) {
    (
      bool valid, address staker, uint256 stakeIndex,
      UnderlyingStakeable.StakeStore memory stake
    ) = _getStakeInfo(stakeId);
    if (!valid) {
      return (ZERO, ZERO);
    }
    // move to after valid check since this should happen less often
    if (staker != msg.sender) {
      revert StakeNotOwned(msg.sender, staker);
    }
    uint256 stakeCountAfter = _getStakeCount({
      staker: address(this)
    }) - ONE;
    // at this point, we can guarantee that we own the stake
    amount = _stakeEnd({
      stakeIndex: stakeIndex,
      stakeId: stakeId,
      stakeCountAfter: stakeCountAfter
    });
    newStakeId = _stakeStartFor({
      owner: staker,
      amount: amount,
      newStakedDays: stake.stakedDays,
      index: stakeCountAfter
    });
  }
  /**
   * given ownership over a stake, stop and restart a stake with all proceeds
   * @param stakeId the stake id to restart
   * @return amount the number of tokens that were ended and added to new stake
   * @return newStakeId the newly created stake id
   */
  function stakeRestartById(uint256 stakeId) external returns(
    uint256 amount, uint256 newStakeId
  ) {
    return _stakeRestartById({
      stakeId: stakeId
    });
  }
  /**
   * given ownership over a list of ids of stakes, restart a list of stakes
   * @param stakeIds the list of stake ids to iterate over and restart
   */
  function stakeRestartManyById(uint256[] calldata stakeIds) external {
    unchecked {
      uint256 i;
      uint256 len = stakeIds.length;
      do {
        _stakeRestartById({
          stakeId: stakeIds[i]
        });
        ++i;
      } while (i < len);
    }
  }
}
