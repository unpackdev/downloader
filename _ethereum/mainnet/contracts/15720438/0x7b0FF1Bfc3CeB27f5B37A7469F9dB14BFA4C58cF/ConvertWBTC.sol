// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseConvert.sol";
import "./ICurveInt128.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract ConvertWBTCMainnet is BaseConvert {
  using SafeMath for *;
  using SafeERC20 for IERC20;
  uint256 constant _maxBurnGas = 10000;
  uint256 constant _maxLoanGas = 10000;
  uint256 constant _maxRepayGas = 10000;

  address constant renCrv = (0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
  IERC20 constant wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

  constructor(address asset) BaseConvert(asset) {}

  function initialize() public override {
    IERC20(asset).approve(address(renCrv), ~uint256(1) << 2);
  }

  function swap(ConvertLocals memory locals) internal override returns (uint256 amountOut) {
    amountOut = wbtc.balanceOf(address(this));
    (bool success, ) = renCrv.call(abi.encodeWithSelector(ICurveInt128.exchange.selector, 0, 1, locals.amount, 1));
    require(success, "!curve");
    amountOut = wbtc.balanceOf(address(this)) - amountOut;
  }

  function swapBack(ConvertLocals memory locals) internal override returns (uint256 amountOut) {
    //no-op
  }

  function transfer(address to, uint256 amount) internal override {
    wbtc.transfer(to, amount);
  }
}
