// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./WadRayMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ICToken.sol";
import "./IPoolToken.sol";
import "./IDerivedToken.sol";
import "./DelegatedStrategyCompoundBase.sol";

contract DelegatedStrategyCompoundErc20 is DelegatedStrategyCompoundBase {
  using SafeERC20 for IERC20;

  constructor(string memory name, address addressProvider) DelegatedStrategyBase(name, addressProvider) {}

  function getUnderlying(address asset) external view override returns (address) {
    return ICTokenErc20(asset).underlying();
  }

  function internalWithdrawUnderlying(
    address asset,
    uint256 amount,
    address to
  ) internal override returns (uint256) {
    if (to == address(this)) {
      return internalRedeem(asset, amount);
    }

    // As CToken always does tansfers to the caller
    // we have to make sure that the funds were actually received,
    // otherwise this call can be cheated to transfer its own funds.
    address underlying = ICTokenErc20(asset).underlying();
    uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));

    amount = internalRedeem(asset, amount);

    require(IERC20(underlying).balanceOf(address(this)) >= amount + balanceBefore, 'CToken: redeem inconsistent');

    return amount;
  }
}
