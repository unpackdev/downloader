pragma solidity 0.5.16;

import "./IStrategyFactory.sol";
import "./StrategyProxy.sol";
import "./OwnableWhitelist.sol";

interface IInitializableStrategy {
  function initializeStrategy(address _storage, address _vault) external;
}

contract UpgradableStrategyFactory is OwnableWhitelist, IStrategyFactory {
  function deploy(address actualStorage, address vault, address upgradableStrategyImplementation)  external onlyWhitelisted returns (address) {
    StrategyProxy proxy = new StrategyProxy(upgradableStrategyImplementation);
    IInitializableStrategy strategy = IInitializableStrategy(address(proxy));
    strategy.initializeStrategy(actualStorage, vault);
    return address(proxy);
  }
}
