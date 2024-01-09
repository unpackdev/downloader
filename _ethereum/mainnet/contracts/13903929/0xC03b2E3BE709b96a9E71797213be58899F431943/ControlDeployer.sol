// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Create2.sol";
import "./Clones.sol";
import "./AccessControl.sol";

import "./IControlDeployer.sol";

import "./Registry.sol";
import "./ProtocolControl.sol";

contract ControlDeployer is AccessControl, IControlDeployer {
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    ProtocolControl public immutable implementation;

    constructor() {
        implementation = new ProtocolControl();
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

        // CREATE2: new_address = hash(0xFF, sender, salt, bytecode)
        bytes32 salt = keccak256(abi.encodePacked(registry, deployer, nonce));
        control = Clones.cloneDeterministic(address(implementation), salt);
        ProtocolControl(payable(control)).initialize(registry, deployer, uri);

        emit DeployedControl(registry, deployer, control);
    }
}
