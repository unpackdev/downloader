// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./IERC20Upgradeable.sol";

import "./PrizePool.sol";

contract StakePrizePool is PrizePool {

  IERC20Upgradeable private stakeToken;

  event StakePrizePoolInitialized(address indexed stakeToken);

  function initialize (
    RegistryInterface _reserveRegistry,
    ControlledTokenInterface[] memory _controlledTokens,
    uint256 _maxExitFeeMantissa,
    uint256 _maxTimelockDuration,
    IERC20Upgradeable _stakeToken
  )
    public
    initializer
  {
    PrizePool.initialize(
      _reserveRegistry,
      _controlledTokens,
      _maxExitFeeMantissa,
      _maxTimelockDuration
    );
    stakeToken = _stakeToken;

    emit StakePrizePoolInitialized(address(stakeToken));
  }

  function _canAwardExternal(address _externalToken) internal override view returns (bool) {
    return address(stakeToken) != _externalToken;
  }

  function _balance() internal override returns (uint256) {
    return stakeToken.balanceOf(address(this));
  }

  function _token() internal override view returns (IERC20Upgradeable) {
    return stakeToken;
  }

  function _supply(uint256 mintAmount) internal override {
  }

  function _redeem(uint256 redeemAmount) internal override returns (uint256) {
    return redeemAmount;
  }
}