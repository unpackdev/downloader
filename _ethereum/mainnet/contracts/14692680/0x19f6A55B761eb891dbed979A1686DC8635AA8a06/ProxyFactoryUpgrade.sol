// SPDX-License-Identifier: MIT

import "./TransparentUpgradeableProxy.sol";

pragma solidity 0.8.12;

contract ProxyFactoryUpgrade {
    /// @dev function call to upgrade a koop.  This factory can only upgrade contracts that they're the admin of
    function upgradeKoop(address _newLogic, bytes calldata _data) external {
        TransparentUpgradeableProxy proxyToUpgrade = TransparentUpgradeableProxy(payable(msg.sender));
        if(_data.length > 0) {
            proxyToUpgrade.upgradeToAndCall(_newLogic, _data);
        } else {
            proxyToUpgrade.upgradeTo(_newLogic);
        }
    }
}
