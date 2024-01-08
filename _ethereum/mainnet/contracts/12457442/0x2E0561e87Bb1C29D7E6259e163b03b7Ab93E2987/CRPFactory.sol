// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ConfigurableRightsPool.sol";
import "./RightsManager.sol";


abstract contract CRPFactory {
  function newCrp(address factoryAddress, ConfigurableRightsPool.PoolParams calldata params, RightsManager.Rights calldata rights) external virtual returns (ConfigurableRightsPool);
}