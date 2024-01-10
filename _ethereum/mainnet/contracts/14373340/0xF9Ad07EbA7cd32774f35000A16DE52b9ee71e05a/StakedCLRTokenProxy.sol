// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";

import "./ICLRDeployer.sol";

contract StakedCLRTokenProxy is TransparentUpgradeableProxy {
    ICLRDeployer clrDeployer;

    constructor(
        address _logic,
        address _proxyAdmin,
        address _clrDeployer
    ) TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {
        clrDeployer = ICLRDeployer(_clrDeployer);
    }

    function upgradeTo(address _implementation) external override ifAdmin {
        require(
            clrDeployer.sCLRTokenImplementation() == _implementation,
            "Can only upgrade to latest Staked CLR token implementation"
        );
        _upgradeTo(_implementation);
    }

    function upgradeToAndCall(address _implementation, bytes calldata data)
        external
        payable
        override
        ifAdmin
    {
        require(
            clrDeployer.sCLRTokenImplementation() == _implementation,
            "Can only upgrade to latest Staked CLR token implementation"
        );
        _upgradeTo(_implementation);
        Address.functionDelegateCall(_implementation, data);
    }
}
