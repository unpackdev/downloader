// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IVotingEscrow.sol";
import "./IFeeDistributor.sol";

import "./console.sol";

contract FeeDistributorAgent is Initializable, OwnableUpgradeable {
  uint256 public constant WEEK = 7 * 86400;
  /**
   * @dev The fee distributor contract
   */
  IFeeDistributor feeDistributor;

  /**
   * @dev The voting escrow contract
   */
  IVotingEscrow ve;

  // ========== Initializer ============ //
  function initialize(address _ve, address _feeDistributor) public initializer {
    __Ownable_init_unchained();
    ve = IVotingEscrow(_ve);
    feeDistributor = IFeeDistributor(_feeDistributor);
  }

  // ========== View Function ============ //
  /**
   * @dev Finds a epoch value for `user` by doing the initial binary search
   * @param account - The address you're going to get the epoch value for
   */
  function find_timestamp_user_epoch(address account)
    public
    view
    returns (uint256)
  {
    uint256 _min = 0;
    uint256 _max = ve.user_point_epoch(account);
    uint256 timestamp = feeDistributor.start_time();
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) break;
      uint256 _mid = (_min + _max + 2) / 2;
      IVotingEscrow.Point memory pt = ve.user_point_history(account, _mid);
      if (pt.ts <= timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    return _min;
  }

  function claimable(address account) external view returns (uint256) {
    uint256 last_token_time = feeDistributor.last_token_time();
    uint256 user_epoch = 0;
    uint256 to_distribute = 0;
    uint256 max_user_epoch = ve.user_point_epoch(account);
    if (max_user_epoch == 0) {
      // No lock = no fees
      return 0;
    }
    uint256 week_cursor = feeDistributor.time_cursor_of(account);
    if (week_cursor == 0) {
      user_epoch = find_timestamp_user_epoch(account);
    } else {
      user_epoch = feeDistributor.user_epoch_of(account);
    }

    if (user_epoch == 0) {
      user_epoch = 1;
    }

    IVotingEscrow.Point memory user_point = ve.user_point_history(
      account,
      user_epoch
    );

    if (week_cursor == 0) {
      week_cursor = ((user_point.ts + WEEK - 1) / WEEK) * WEEK;
    }

    if (week_cursor >= last_token_time) return 0;

    if (week_cursor < feeDistributor.start_time()) {
      week_cursor = feeDistributor.start_time();
    }

    IVotingEscrow.Point memory old_user_point;

    // Iterate over weeks
    for (uint256 i = 0; i < 50; i++) {
      if (week_cursor >= last_token_time) break;
      if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
        user_epoch++;
        old_user_point.bias = user_point.bias;
        old_user_point.slope = user_point.slope;
        old_user_point.ts = user_point.ts;
        old_user_point.blk = user_point.blk;
        if (user_epoch > max_user_epoch) {
          user_point.bias = 0;
          user_point.slope = 0;
          user_point.ts = 0;
          user_point.blk = 0;
        } else {
          user_point = ve.user_point_history(account, user_epoch);
        }
      } else {
        uint256 dt = week_cursor - old_user_point.ts;
        uint256 balance_of = old_user_point.bias >= dt * old_user_point.slope
          ? old_user_point.bias - dt * old_user_point.slope
          : 0;
        if (balance_of == 0 && user_epoch > max_user_epoch) break;
        if (balance_of > 0) {
          to_distribute +=
            (balance_of * feeDistributor.tokens_per_week(week_cursor)) /
            feeDistributor.ve_supply(week_cursor);
        }

        week_cursor += WEEK;
      }
    }
    return to_distribute;
  }

  // ========== Owner Function ============ //
  function setVE(address _ve) external onlyOwner {
    ve = IVotingEscrow(_ve);
  }

  function setFeeDistributor(address _feeDistributor) external onlyOwner {
    feeDistributor = IFeeDistributor(_feeDistributor);
  }
}
