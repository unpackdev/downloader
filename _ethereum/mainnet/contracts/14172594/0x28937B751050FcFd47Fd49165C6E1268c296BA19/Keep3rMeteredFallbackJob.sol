// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rMeteredJob.sol";
import "./IKeep3rMeteredFallbackJob.sol";
import "./OracleLibrary.sol";

abstract contract Keep3rMeteredFallbackJob is Keep3rMeteredJob, IKeep3rMeteredFallbackJob {
  address public override fallbackToken;
  address public override fallbackTokenWETHPool;
  /// @dev Fixed bonus to pay for unaccounted gas in fallback payment transactions
  uint256 public override fallbackGasBonus = 77_000;
  uint32 public override twapTime = 300;

  // solhint-disable-next-line var-name-mixedcase
  address public override WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  constructor(address _fallbackToken, address _fallbackTokenWETHPool) {
    fallbackToken = _fallbackToken;
    fallbackTokenWETHPool = _fallbackTokenWETHPool;
  }

  function setFallbackGasBonus(uint256 _fallbackGasBonus) external override onlyGovernor {
    fallbackGasBonus = _fallbackGasBonus;
    emit FallbackGasBonusSet(fallbackGasBonus);
  }

  function setFallbackTokenWETHPool(address _fallbackTokenWETHPool) external override onlyGovernor {
    fallbackTokenWETHPool = _fallbackTokenWETHPool;
    emit FallbackTokenWETHPoolSet(fallbackTokenWETHPool);
  }

  function setFallbackToken(address _fallbackToken) external override onlyGovernor {
    fallbackToken = _fallbackToken;
    emit FallbackTokenAddressSet(fallbackToken);
  }

  function setTwapTime(uint32 _twapTime) external override onlyGovernor {
    twapTime = _twapTime;
    emit TwapTimeSet(twapTime);
  }

  modifier upkeepFallbackMetered() {
    uint256 _initialGas = gasleft();
    _isValidKeeper(msg.sender);
    _;
    uint256 _bonus = gasBonus;
    uint256 _gasAfterWork = gasleft();
    uint256 _reward = (_calculateGas(_initialGas - _gasAfterWork + _bonus) * gasMultiplier) / BASE;
    uint256 _payment = IKeep3rHelper(keep3rHelper).quote(_reward);
    bool _fallback;
    try IKeep3rV2(keep3r).bondedPayment(msg.sender, _payment) {} catch {
      _fallback = true;
      int24 _twapTick = OracleLibrary.consult(fallbackTokenWETHPool, twapTime);
      _bonus = fallbackGasBonus;
      _gasAfterWork = gasleft();
      _reward = (_calculateGas(_initialGas - _gasAfterWork + _bonus) * gasMultiplier) / BASE;
      uint256 _amount = OracleLibrary.getQuoteAtTick(_twapTick, uint128(_reward), WETH, fallbackToken);
      IKeep3rV2(keep3r).directTokenPayment(fallbackToken, msg.sender, _amount);
    }
    /// @dev Using revert strings to interact with CLI simulation
    require(_fallback || _initialGas - _gasAfterWork <= gasMaximum, 'GasMeteredMaximum');
    emit GasMetered(_initialGas, _gasAfterWork, _bonus);
  }
}
