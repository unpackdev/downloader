// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./StakeEnder.sol";

contract StakeStarter is StakeEnder {
  /**
   * stake a given number of tokens for a given number of days
   * @param to the address that will own the staker
   * @param amount the number of tokens to stake
   * @param newStakedDays the number of days to stake for
   */
  function stakeStartFromBalanceFor(
    address to,
    uint256 amount,
    uint256 newStakedDays,
    uint256 settings
  ) external payable returns(uint256 stakeId) {
    _depositTokenFrom({
      token: TARGET,
      depositor: msg.sender,
      amount: amount
    });
    // tokens are essentially unattributed at this point
    stakeId = _stakeStartFor({
      owner: to,
      amount: amount,
      newStakedDays: newStakedDays,
      index: _stakeCount(address(this))
    });
    _logPreservedSettingsUpdate({
      stakeId: stakeId,
      settings: settings
    });
  }
  /**
   * start a numbeer of stakes for an address from the withdrawable
   * @param to the account to start a stake for
   * @param amount the number of tokens to start a stake for
   * @param newStakedDays the number of days to stake for
   */
  function stakeStartFromWithdrawableFor(
    address to,
    uint256 amount,
    uint256 newStakedDays,
    uint256 settings
  ) external payable returns(uint256 stakeId) {
    stakeId = _stakeStartFor({
      owner: to,
      amount: _deductWithdrawable({
        token: TARGET,
        account: msg.sender,
        amount: amount
      }),
      newStakedDays: newStakedDays,
      index: _stakeCount({
        staker: address(this)
      })
    });
    _logPreservedSettingsUpdate({
      stakeId: stakeId,
      settings: settings
    });
  }
  /**
   * stake a number of tokens for a given number of days, pulling from
   * the unattributed tokens in this contract
   * @param to the owner of the stake
   * @param amount the amount of tokens to stake
   * @param newStakedDays the number of days to stake
   */
  function stakeStartFromUnattributedFor(
    address to,
    uint256 amount,
    uint256 newStakedDays,
    uint256 settings
  ) external payable returns(uint256 stakeId) {
    stakeId = _stakeStartFor({
      owner: to,
      amount: _clamp(amount, _getUnattributed(TARGET)),
      newStakedDays: newStakedDays,
      index: _stakeCount(address(this))
    });
    _logPreservedSettingsUpdate({
      stakeId: stakeId,
      settings: settings
    });
  }
}
