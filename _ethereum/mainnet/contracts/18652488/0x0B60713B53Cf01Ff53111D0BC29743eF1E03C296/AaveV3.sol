// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./DataTypes.sol";
import "./Errors.sol";
import "./ConfiguratorInputTypes.sol";
import "./IPoolAddressesProvider.sol";
import "./IAToken.sol";
import "./IPool.sol";
import "./IPoolConfigurator.sol";
import "./IPriceOracleGetter.sol";
import "./IAaveOracle.sol";
import "./IACLManager.sol";
import "./IPoolDataProvider.sol";
import "./IDefaultInterestRateStrategy.sol";
import "./IReserveInterestRateStrategy.sol";
import "./IPoolDataProvider.sol";
import "./AggregatorInterface.sol";

interface IACLManager is BasicIACLManager {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

  function renounceRole(bytes32 role, address account) external;

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;
}
