pragma solidity ^0.5.2;

import "./UpgradableProxy.sol";

contract StakeManagerProxy is UpgradableProxy {
    constructor(address _proxyTo) public UpgradableProxy(_proxyTo) {}
}
