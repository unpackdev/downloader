pragma solidity >=0.6.0 <0.7.0;

import "./BarnPrizePoolHarness.sol";
import "./ProxyFactory.sol";

/// @title Barn Prize Pool Proxy Factory
/// @notice Minimal proxy pattern for creating new Barn Prize Pools
contract BarnPrizePoolHarnessProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied Prize Pools
  BarnPrizePoolHarness public instance;

  /// @notice Initializes the Factory with an instance of the Barn Prize Pool
  constructor () public {
    instance = new BarnPrizePoolHarness();
  }

  /// @notice Creates a new Barn Prize Pool as a proxy of the template instance
  /// @return A reference to the new proxied Barn Prize Pool
  function create() external returns (BarnPrizePoolHarness) {
    return BarnPrizePoolHarness(deployMinimal(address(instance), ""));
  }
}
