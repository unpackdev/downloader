// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./BarnPrizePool.sol";
import "./ProxyFactory.sol";

/// @title Barn Prize Pool Proxy Factory
/// @notice Minimal proxy pattern for creating new Barn Prize Pools
contract BarnPrizePoolProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied Prize Pools
  BarnPrizePool public instance;

  /// @notice Initializes the Factory with an instance of the Barn Prize Pool
  constructor () public {
    instance = new BarnPrizePool();
  }

  /// @notice Creates a new Barn Prize Pool as a proxy of the template instance
  /// @return A reference to the new proxied Barn Prize Pool
  function create() external returns (BarnPrizePool) {
    return BarnPrizePool(deployMinimal(address(instance), ""));
  }
}
