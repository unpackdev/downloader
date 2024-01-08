// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Create2.sol";
import "./AccessControl.sol";

import "./IControlDeployer.sol";

import "./Registry.sol";
import "./ProtocolControl.sol";

contract ControlDeployer is AccessControl, IControlDeployer {
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Deploys an instance of `ProtocolControl`
    function deployControl(
        uint256 nonce,
        address deployer,
        string memory uri
    ) external override returns (address control) {
        // Get registry address.
        address registry = _msgSender();

        require(hasRole(REGISTRY_ROLE, registry), "invalid registry");

        // Deploy `ProtocolControl`
        bytes memory controlBytecode = abi.encodePacked(
            type(ProtocolControl).creationCode,
            abi.encode(registry, deployer, uri)
        );

        // CREATE2: new_address = hash(0xFF, sender, salt, bytecode)
        bytes32 salt = keccak256(abi.encodePacked(registry, deployer, nonce));
        control = Create2.deploy(0, salt, controlBytecode);

        emit DeployedControl(registry, deployer, control);
    }
}
