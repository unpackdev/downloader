// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";

contract RewardEscrowProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin)
        TransparentUpgradeableProxy(_logic, _proxyAdmin, "")
    {}
}
