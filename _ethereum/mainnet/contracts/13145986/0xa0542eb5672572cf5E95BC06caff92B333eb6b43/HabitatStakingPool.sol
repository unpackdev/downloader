// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatBase.sol";
import "./HabitatWallet.sol";

/// @notice Takes care of transferring value to a operator minus a few that goes to the staking pool.
// Audit-1: ok
contract HabitatStakingPool is HabitatBase, HabitatWallet {
  event ClaimedStakingReward(address indexed account, address indexed token, uint256 indexed epoch, uint256 amount);

  /// @dev Like `_getStorage` but with some additional conditions.
  function _specialLoad (uint256 oldValue, uint256 key) internal returns (uint256) {
    uint256 newValue = HabitatBase._getStorage(key);

    // 0 means no record / no change
    if (newValue == 0) {
      return oldValue;
    }

    // -1 means drained (no balance)
    if (newValue == uint256(-1)) {
      return 0;
    }

    // default to newValue
    return newValue;
  }

  /// @notice Claims staking rewards for `epoch`.
  function onClaimStakingReward (address msgSender, uint256 nonce, address token, uint256 sinceEpoch) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // we ignore untilEpoch wrapping around because this is not a practical problem
    uint256 untilEpoch = sinceEpoch + 10;
    {
      // assuming getCurrentEpoch never returns 0
      uint256 max = getCurrentEpoch();
      // clamp
      if (untilEpoch > max) {
        untilEpoch = max;
      }
    }
    // checks if the account can claim rewards, starting from `sinceEpoch`
    require(
      sinceEpoch != 0
      && untilEpoch > sinceEpoch
      && sinceEpoch > HabitatBase._getStorage(_STAKING_EPOCH_LAST_CLAIMED_KEY(token, msgSender)),
      'OCSR1'
    );

    // update last claimed epoch
    HabitatBase._setStorage(_STAKING_EPOCH_LAST_CLAIMED_KEY(token, msgSender), untilEpoch - 1);

    // this is the total user balance for `token` in any given epoch
    uint256 historicTotalUserBalance;

    for (uint256 epoch = sinceEpoch; epoch < untilEpoch; epoch++) {
      uint256 reward = 0;
      // special pool address
      address pool = address(epoch);
      uint256 poolBalance = getBalance(token, pool);
      // total value locked after the end of each epoch.
      // tvl being zero should imply that `historicPoolBalance` must also be zero
      uint256 historicTVL = HabitatBase._getStorage(_STAKING_EPOCH_TVL_KEY(epoch, token));
      // returns the last 'known' user balance up to `epoch`
      historicTotalUserBalance = _specialLoad(historicTotalUserBalance, _STAKING_EPOCH_TUB_KEY(epoch, token, msgSender));

      if (
        poolBalance != 0
        && historicTVL != 0
        && historicTotalUserBalance != 0
        // `historicTotalUserBalance` should always be less than `historicTVL`
        && historicTotalUserBalance < historicTVL
      ) {
        // deduct pool balance from tvl
        // assuming `historicPoolBalance` must be less than `historicTVL`
        uint256 historicPoolBalance = HabitatBase._getStorage(_STAKING_EPOCH_TUB_KEY(epoch, token, pool));
        uint256 tvl = historicTVL - historicPoolBalance;

        reward = historicPoolBalance / (tvl / historicTotalUserBalance);

        if (reward != 0) {
          // this can happen
          if (reward > poolBalance) {
            reward = poolBalance;
          }
          _transferToken(token, pool, msgSender, reward);
        }
      }

      if (_shouldEmitEvents()) {
        emit ClaimedStakingReward(msgSender, token, epoch, reward);
      }
    }

    // store the tub for the user but do not overwrite if there is already
    // a non-zero entry
    uint256 key = _STAKING_EPOCH_TUB_KEY(untilEpoch, token, msgSender);
    if (HabitatBase._getStorage(key) == 0) {
      _setStorageInfinityIfZero(key, historicTotalUserBalance);
    }
  }

  /// @notice Transfers funds to a (trusted) operator.
  /// A fraction `STAKING_POOL_FEE_DIVISOR` of the funds goes to the staking pool.
  function onTributeForOperator (
    address msgSender,
    uint256 nonce,
    address operator,
    address token,
    uint256 amount
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // fee can be zero
    uint256 fee = amount / STAKING_POOL_FEE_DIVISOR();
    // epoch is greater than zero
    uint256 currentEpoch = getCurrentEpoch();
    address pool = address(currentEpoch);
    // zero-value transfers are not a problem
    _transferToken(token, msgSender, pool, fee);
    _transferToken(token, msgSender, operator, amount - fee);
  }
}
