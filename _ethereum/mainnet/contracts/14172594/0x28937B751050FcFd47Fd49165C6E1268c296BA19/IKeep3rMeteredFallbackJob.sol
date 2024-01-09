// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IKeep3rMeteredJob.sol";

interface IKeep3rMeteredFallbackJob is IKeep3rMeteredJob {
  // Events

  event FallbackGasBonusSet(uint256 gasBonus);
  event FallbackTokenAddressSet(address fallbackToken);
  event FallbackTokenWETHPoolSet(address fallbackTokenWETHPool);
  event TwapTimeSet(uint256 twapTime);

  // Variables

  function fallbackToken() external view returns (address _fallbackToken);

  function fallbackTokenWETHPool() external view returns (address _fallbackTokenWETHPool);

  function twapTime() external view returns (uint32 _twapTime);

  function fallbackGasBonus() external view returns (uint256 _fallBackGasBonus);

  // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
  function WETH() external view returns (address _WETH);

  // Methods

  function setFallbackGasBonus(uint256 _fallbackGasBonus) external;

  function setFallbackTokenWETHPool(address _fallbackTokenWETHPool) external;

  function setFallbackToken(address _fallbackToken) external;

  function setTwapTime(uint32 _twapTime) external;
}
