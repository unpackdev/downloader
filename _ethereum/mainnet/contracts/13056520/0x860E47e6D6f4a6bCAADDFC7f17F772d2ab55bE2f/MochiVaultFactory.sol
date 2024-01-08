// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Beacon.sol";
import "./BeaconProxyDeployer.sol";
import "./IMochiEngine.sol";
import "./IMochiVaultFactory.sol";

contract MochiVaultFactory is IMochiVaultFactory {
    IMochiEngine public immutable engine;
    Beacon public immutable beacon;
    address public template;

    constructor(address _engine) {
        beacon = new Beacon(address(0));
        engine = IMochiEngine(_engine);
    }

    function updateTemplate(address _newTemplate) external override {
        require(msg.sender == engine.governance(), "!gov");
        address(beacon).call(abi.encode(_newTemplate));
        template = _newTemplate;
    }

    function deployVault(address _asset)
        external
        override
        returns (IMochiVault)
    {
        bytes memory initCode = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address)")),
            _asset
        );
        return
            IMochiVault(BeaconProxyDeployer.deploy(address(beacon), initCode));
    }

    function getVault(address _asset)
        external
        view
        override
        returns (IMochiVault)
    {
        bytes memory initCode = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address)")),
            _asset
        );
        return
            IMochiVault(
                BeaconProxyDeployer.calculateAddress(
                    address(this),
                    address(beacon),
                    initCode
                )
            );
    }
}
