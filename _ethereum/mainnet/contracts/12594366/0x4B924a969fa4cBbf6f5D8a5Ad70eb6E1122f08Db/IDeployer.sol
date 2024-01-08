// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IPoolDeployment.sol";
import "./IDerivativeDeployment.sol";
import "./ISelfMintingDerivativeDeployment.sol";
import "./EnumerableSet.sol";

/**
 * @title Provides interface with functions of Synthereum deployer
 */
interface ISynthereumDeployer {
  /**
   * @notice Deploys derivative and pool linking the contracts together
   * @param derivativeVersion Version of derivative contract
   * @param poolVersion Version of the pool contract
   * @param derivativeParamsData Input params of derivative constructor
   * @param poolParamsData Input params of pool constructor
   * @return derivative Derivative contract deployed
   * @return pool Pool contract deployed
   */
  function deployPoolAndDerivative(
    uint8 derivativeVersion,
    uint8 poolVersion,
    bytes calldata derivativeParamsData,
    bytes calldata poolParamsData
  )
    external
    returns (IDerivativeDeployment derivative, ISynthereumPoolDeployment pool);

  /**
   * @notice Deploys a pool and links it with an already existing derivative
   * @param poolVersion Version of the pool contract
   * @param poolParamsData Input params of pool constructor
   * @param derivative Existing derivative contract to link with the new pool
   * @return pool Pool contract deployed
   */
  function deployOnlyPool(
    uint8 poolVersion,
    bytes calldata poolParamsData,
    IDerivativeDeployment derivative
  ) external returns (ISynthereumPoolDeployment pool);

  /**
   * @notice Deploys a derivative and option to links it with an already existing pool
   * @param derivativeVersion Version of the derivative contract
   * @param derivativeParamsData Input params of derivative constructor
   * @param pool Existing pool contract to link with the new derivative
   * @return derivative Derivative contract deployed
   */
  function deployOnlyDerivative(
    uint8 derivativeVersion,
    bytes calldata derivativeParamsData,
    ISynthereumPoolDeployment pool
  ) external returns (IDerivativeDeployment derivative);

  function deployOnlySelfMintingDerivative(
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  ) external returns (ISelfMintingDerivativeDeployment selfMintingDerivative);
}
