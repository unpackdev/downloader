// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IDepositToken.sol";
import "./IInitializableRewardPool.sol";
import "./CalcLinearWeightedReward.sol";
import "./ControlledRewardPool.sol";
import "./IERC20Extended.sol";
import "./ERC20DetailsBase.sol";
import "./ERC20AllowanceBase.sol";
import "./ERC20TransferBase.sol";
import "./ERC20PermitBase.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./Errors.sol";
import "./UnderlyingHelper.sol";
import "./StakeTokenConfig.sol";
import "./IInitializableStakeToken.sol";
import "./RewardedStakeBase.sol";

abstract contract DepositStakeBase is RewardedStakeBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  function exchangeRate() public view override returns (uint256) {
    return super.exchangeRate().rayMul(getScaleIndex());
  }

  function internalExchangeRate() internal view override returns (uint256, uint256 index) {
    index = getScaleIndex();
    return (super.exchangeRate().rayMul(index), index);
  }

  function getScaleIndex() public view returns (uint256) {
    return IDepositToken(super.getUnderlying()).getScaleIndex();
  }

  function slashUnderlying(
    address destination,
    uint256 minAmount,
    uint256 maxAmount
  ) external override onlyLiquidityController returns (uint256 amount, bool erc20Transfer) {
    uint256 index = getScaleIndex();
    uint256 totalSupply;
    (amount, totalSupply) = internalSlash(minAmount.rayDiv(index), maxAmount.rayDiv(index));
    if (amount > 0) {
      amount = amount.rayMul(index);
      erc20Transfer = internalTransferSlashedUnderlying(destination, amount.rayMul(index));
      emit Slashed(destination, amount, totalSupply);
    }
    return (amount, erc20Transfer);
  }

  function internalTransferUnderlyingFrom(
    address from,
    uint256 underlyingAmount,
    uint256 index
  ) internal override {
    address token = super.getUnderlying();
    IERC20Extended(token).useAllowance(from, underlyingAmount);
    IDepositToken(token).lockSubBalance(from, underlyingAmount.rayDiv(index));
  }

  function internalTransferUnderlyingTo(
    address from,
    address to,
    uint256 underlyingAmount,
    uint256 index
  ) internal override {
    IDepositToken(super.getUnderlying()).unlockSubBalance(from, underlyingAmount.rayDiv(index), to);
  }

  function internalTransferSlashedUnderlying(address destination, uint256)
    internal
    view
    override
    returns (bool erc20Transfer)
  {
    require(destination == super.getUnderlying(), Errors.AT_INVALID_SLASH_DESTINATION);
    return false;
  }

  function transferBalance(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super.transferBalance(from, to, amount);
    IDepositToken(super.getUnderlying()).transferLockedBalance(from, to, amount);
  }
}
