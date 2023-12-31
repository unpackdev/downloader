// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IStakedUSDe.sol";

struct UserCooldown {
  uint104 cooldownEnd;
  uint256 underlyingAmount;
}

interface IStakedUSDeCooldown is IStakedUSDe {
  function cooldownAssets(uint256 assets, address owner) external returns (uint256 shares);

  function cooldownShares(uint256 shares, address owner) external returns (uint256 assets);

  function unstake(address receiver) external;

  function setCooldownDuration(uint104 duration) external;

  event CooldownDurationUpdated(uint104 previousDuration, uint104 newDuration);
  event SiloUpdated(address previousSilo, address newSilo);
}
