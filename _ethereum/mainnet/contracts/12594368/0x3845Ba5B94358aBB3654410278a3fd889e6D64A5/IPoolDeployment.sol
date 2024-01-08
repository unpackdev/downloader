// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IFinder.sol";
import "./IRole.sol";
import "./IDerivative.sol";

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumPoolDeployment {
  /**
   * @notice Get Synthereum finder of the pool
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of this Synthereum pool
   */
  function version() external view returns (uint8 poolVersion);

  /**
   * @notice Get the collateral token
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);

  function isDerivativeAdmitted(address derivative)
    external
    view
    returns (bool isAdmitted);
}
