// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
pragma abicoder v2;

import "./TransparentUpgradeableProxy.sol";

contract StakingRewardsProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin)
        TransparentUpgradeableProxy(_logic, _proxyAdmin, "")
    {}
}