// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./IHegicPoolProtocolParameters.sol";

abstract
contract HegicPoolProtocolParameters is IHegicPoolProtocolParameters {

  uint256 public WITHDRAW_MAX_COOLDOWN = 2 weeks;
  uint256 public WITHDRAW_FEE_PRECISION = 10000; // 4 decimals
  uint256 public WITHDRAW_MAX_FEE = 5 * WITHDRAW_FEE_PRECISION; // 5 %

  uint256 public minTokenReserves = 100000 * 1e18;
  uint256 public withdrawCooldown = 0;
  uint256 public withdrawFee = 0; // 0.1% 1 * WITHDRAW_FEE_PRECISION / 10

  constructor (
    uint256 _minTokenReserves,
    uint256 _withdrawCooldown,
    uint256 _withdrawFee
  ) public {
    _setMinTokenReserves(_minTokenReserves);
    _setWithdrawCooldown(_withdrawCooldown);
    _setWithdrawFee(_withdrawFee);
  }

  function _setMinTokenReserves(uint256 _minTokenReserves) internal {
    minTokenReserves = _minTokenReserves;
    emit MinTokenReservesSet(_minTokenReserves);
  }

  function _setWithdrawCooldown(uint256 _withdrawCooldown) internal {
    require(_withdrawCooldown <= WITHDRAW_MAX_COOLDOWN, 'hegic-pool-protocol-parameters/max-withdraw-cooldown');
    withdrawCooldown = _withdrawCooldown;
    emit WithdrawCooldownSet(_withdrawCooldown);
  }

  function _setWithdrawFee(uint256 _withdrawFee) internal {
    require(_withdrawFee <= WITHDRAW_MAX_FEE, 'hegic-pool-protocol-parameters/max-withdraw-fee');
    withdrawFee = _withdrawFee;
    emit WidthawFeeSet(_withdrawFee);
  }
}