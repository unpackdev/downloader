// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IERC20.sol";

interface ISynthereumPoolRegistry {
  function registerPool(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 poolVersion,
    address pool
  ) external;

  function isPoolDeployed(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion,
    address pool
  ) external view returns (bool isDeployed);

  function getPools(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion
  ) external view returns (address[] memory);

  function getCollaterals() external view returns (address[] memory);
}
