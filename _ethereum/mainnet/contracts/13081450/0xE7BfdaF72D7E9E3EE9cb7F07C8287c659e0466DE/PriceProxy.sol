pragma solidity 0.7.3;

import "./TransparentUpgradeableProxy.sol";

contract PriceProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin) public TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}
}
