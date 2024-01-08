// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";

contract CustomStakingRewardUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }
}
