pragma solidity 0.7.3;

import "./TransparentUpgradeableProxy.sol";

contract MarketProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin) public TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}
}
