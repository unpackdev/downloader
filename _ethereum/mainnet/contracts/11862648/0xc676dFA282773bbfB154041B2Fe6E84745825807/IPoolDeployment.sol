// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IFinder.sol";

interface ISynthereumPoolDeployment {
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  function version() external view returns (uint8 poolVersion);

  function collateralToken() external view returns (IERC20 collateralCurrency);

  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  function syntheticTokenSymbol() external view returns (string memory symbol);
}
