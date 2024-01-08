// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./WadRayMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ICToken.sol";
import "./IWETH.sol";
import "./IPoolToken.sol";
import "./IDerivedToken.sol";
import "./DelegatedStrategyCompoundBase.sol";

contract DelegatedStrategyCompoundEth is DelegatedStrategyCompoundBase {
  using SafeERC20 for IERC20;

  IWETH private immutable _weth;

  constructor(
    string memory name,
    address addressProvider,
    address weth
  ) DelegatedStrategyBase(name, addressProvider) {
    _weth = IWETH(weth);
  }

  function getUnderlying(address) external view override returns (address) {
    return address(_weth);
  }

  function internalWithdrawUnderlying(
    address asset,
    uint256 amount,
    address to
  ) internal override returns (uint256) {
    uint256 balanceBefore = address(this).balance;
    amount = internalRedeem(asset, amount);
    require(address(this).balance >= balanceBefore + amount, 'CToken: redeem inconsistent');

    if (amount == 0) {
      return 0;
    }

    _weth.deposit{value: amount}();
    if (to != address(this)) {
      IERC20(address(_weth)).safeTransfer(to, amount);
    }

    return amount;
  }
}
