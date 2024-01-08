// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatBase.sol";

/// @notice Functionality for user wallets and token accounting.
// Audit-1: ok
contract HabitatWallet is HabitatBase {
  event TokenTransfer(address indexed token, address indexed from, address indexed to, uint256 value, uint256 epoch);
  event DelegatedAmount(address indexed account, address indexed delegatee, address indexed token, uint256 value);

  /// @notice Returns the (free) balance (amount of `token`) for `account`.
  /// Free = balance of `token` for `account` - activeVotingStake & delegated stake for `account`.
  /// Supports ERC-20 and ERC-721 and takes staked balances into account.
  function getUnlockedBalance (address token, address account) public returns (uint256 ret) {
    uint256 locked =
      HabitatBase.getActiveVotingStake(token, account) +
      HabitatBase._getStorage(_DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY(account, token));
    ret = getBalance(token, account);
    // something must be wrong if this happens
    require(locked <= ret, 'GUB1');
    ret = ret - locked;
  }

  /// @dev State transition when a user transfers a token.
  /// Updates Total Value Locked and does accounting needed for staking rewards.
  function _transferToken (address token, address from, address to, uint256 value) internal virtual {
    bool isERC721 = _getTokenType(token) > 1;

    // update from
    if (isERC721) {
      require(HabitatBase.getErc721Owner(token, value) == from, 'OWNER');
      HabitatBase._setStorage(_ERC721_KEY(token, value), to);
    }

    uint256 currentEpoch = getCurrentEpoch();
    // both ERC-20 & ERC-721
    uint256 balanceDelta = isERC721 ? 1 : value;
    // update `from`
    if (from != address(0)) {
      // not a deposit - check stake
      {
        uint256 availableAmount = getUnlockedBalance(token, from);
        require(availableAmount >= balanceDelta, 'LOCK');
      }

      // can revert
      HabitatBase._decrementStorage(_ERC20_KEY(token, from), balanceDelta);

      // update historic total user balance
      HabitatBase._setStorageInfinityIfZero(
        _STAKING_EPOCH_TUB_KEY(currentEpoch, token, from),
        getBalance(token, from)
      );
    }
    // update `to`
    {
      if (to == address(0)) {
        // exit
        if (isERC721) {
          _setERC721Exit(token, from, value);
        } else {
          _incrementExit(token, from, value);
        }
      } else {
        // can throw
        HabitatBase._incrementStorage(_ERC20_KEY(token, to), balanceDelta);

        // update historic total user balance
        HabitatBase._setStorageInfinityIfZero(
          _STAKING_EPOCH_TUB_KEY(currentEpoch, token, to),
          getBalance(token, to)
        );
      }
    }

    // TVL
    {
      // from == address(0) = deposit
      // to == address(0) = exit
      // classify deposits and exits in the same way as vaults (exempt from TVL)
      bool fromVault = from == address(0) || HabitatBase._getStorage(_VAULT_CONDITION_KEY(from)) != 0;
      bool toVault = to == address(0) || HabitatBase._getStorage(_VAULT_CONDITION_KEY(to)) != 0;

      // considerations
      // - transfer from user to user, do nothing
      // - transfer from vault to vault, do nothing
      // - deposits (from = 0), increase if !toVault
      // - exits (to == 0), decrease if !fromVault
      // - transfer from user to vault, decrease
      // - transfer from vault to user, increase
      if (toVault && !fromVault) {
        HabitatBase._decrementStorage(_TOKEN_TVL_KEY(token), balanceDelta);
      }
      if (fromVault && !toVault) {
        HabitatBase._incrementStorage(_TOKEN_TVL_KEY(token), balanceDelta);
      }
    }

    {
      // update tvl for epoch - accounting for staking rewards
      HabitatBase._setStorage(
        _STAKING_EPOCH_TVL_KEY(currentEpoch, token),
        HabitatBase._getStorage(_TOKEN_TVL_KEY(token))
      );
    }

    if (_shouldEmitEvents()) {
      emit TokenTransfer(token, from, to, value, currentEpoch);
      // transactions should be submitted before the next epoch
      uint256 nextEpochTimestamp = EPOCH_GENESIS() + (SECONDS_PER_EPOCH() * (currentEpoch + 1));
      _emitTransactionDeadline(nextEpochTimestamp);
    }
  }

  /// @dev State transition when a user deposits a token.
  function onDeposit (address owner, address token, uint256 value, uint256 tokenType) external {
    HabitatBase._commonChecks();
    _setTokenType(token, tokenType);
    _transferToken(token, address(0), owner, value);
  }

  /// @dev State transition when a user transfers a token.
  function onTransferToken (address msgSender, uint256 nonce, address token, address to, uint256 value) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);
    _transferToken(token, msgSender, to, value);
  }

  /// @dev State transition when a user sets a delegate.
  function onDelegateAmount (address msgSender, uint256 nonce, address delegatee, address token, uint256 newAllowance) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    // can not delegate to self
    require(msgSender != delegatee, 'ODA1');

    uint256 oldAllowance = HabitatBase._getStorage(_DELEGATED_ACCOUNT_ALLOWANCE_KEY(msgSender, delegatee, token));

    // track the difference
    if (oldAllowance < newAllowance) {
      uint256 delta = newAllowance - oldAllowance;
      uint256 availableBalance = getUnlockedBalance(token, msgSender);
      // check
      require(availableBalance >= delta, 'ODA2');

      // increment new total delegated balance for delegatee
      HabitatBase._incrementStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token), delta);
      // increment new total delegated amount for msgSender
      HabitatBase._incrementStorage(_DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY(msgSender, token), delta);
    } else {
      uint256 delta = oldAllowance - newAllowance;
      uint256 currentlyStaked = HabitatBase._getStorage(_DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, delegatee));
      uint256 total = HabitatBase._getStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token));
      uint256 freeAmount = total - currentlyStaked;
      // check that delta is less or equal to the available balance
      require(delta <= freeAmount, 'ODA3');

      // decrement new total delegated balance for delegatee
      HabitatBase._decrementStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token), delta);
      // decrement new total delegated amount for msgSender
      HabitatBase._decrementStorage(_DELEGATED_ACCOUNT_TOTAL_ALLOWANCE_KEY(msgSender, token), delta);
    }

    // save the new allowance
    HabitatBase._setStorage(_DELEGATED_ACCOUNT_ALLOWANCE_KEY(msgSender, delegatee, token), newAllowance);

    if (_shouldEmitEvents()) {
      emit DelegatedAmount(msgSender, delegatee, token, newAllowance);
    }
  }
}
