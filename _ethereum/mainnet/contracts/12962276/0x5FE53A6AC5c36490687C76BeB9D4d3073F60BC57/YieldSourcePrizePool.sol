// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IYieldSource.sol";
import "./PrizePool.sol";

contract YieldSourcePrizePool is PrizePool {

  using SafeERC20Upgradeable for IERC20Upgradeable;

  IYieldSource public yieldSource;

  event YieldSourcePrizePoolInitialized(address indexed yieldSource);

  function initializeYieldSourcePrizePool (
    RegistryInterface _reserveRegistry,
    ControlledTokenInterface _ticket,
    uint256 _maxExitFeeMantissa,
    uint256 _maxTimelockDuration,
    IYieldSource _yieldSource
  )
    public
    initializer
  {
    require(address(_yieldSource) != address(0), "YIELDSOURCEPRIZEPOOL: YIELD_SOURCE_ZERO");
    PrizePool.initialize(
      _reserveRegistry,
      _ticket,
      _maxExitFeeMantissa,
      _maxTimelockDuration
    );
    yieldSource = _yieldSource;

    (bool succeeded,) = address(_yieldSource).staticcall(abi.encode(_yieldSource.depositToken.selector));
    require(succeeded, "YIELDSOURCEPRIZEPOOL: INVALID_YIELD_SOURCE");

    emit YieldSourcePrizePoolInitialized(address(_yieldSource));
  }

  function _canAwardExternal(address _externalToken) internal override view returns (bool) {
    return _externalToken != address(yieldSource);
  }

  function _balance() internal override returns (uint256) {
    return yieldSource.balanceOfToken(address(this));
  }

  function _token() internal override view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(yieldSource.depositToken());
  }

  function _supply(uint256 mintAmount) internal override {
    _token().safeApprove(address(yieldSource), mintAmount);
    yieldSource.supplyTokenTo(mintAmount, address(this));
  }

  function _redeem(uint256 redeemAmount) internal override returns (uint256) {
    return yieldSource.redeemToken(redeemAmount);
  }
}