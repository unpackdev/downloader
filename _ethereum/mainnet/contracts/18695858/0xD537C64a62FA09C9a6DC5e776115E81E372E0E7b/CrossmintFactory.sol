// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ICrossmintFactory.sol";
import "./CREATE3.sol";
import "./Address.sol";

/// @title Factory for deploying contracts to deterministic addresses via CREATE3
/// @notice HEAVILY inspired by zefram.eth's create3 factory, ty!
contract CrossmintFactory is ICrossmintFactory {
    using Address for address;

    /// @inheritdoc	ICrossmintFactory
    function deploy(bytes32 salt, bytes memory creationCode) external payable override returns (address deployed) {
        salt = keccak256(abi.encodePacked(msg.sender, salt));
        return CREATE3.deploy(salt, creationCode, msg.value);
    }

    /// @inheritdoc	ICrossmintFactory
    function deployAndCall(bytes32 salt, bytes memory creationCode, bytes memory data)
        external
        payable
        override
        returns (address deployed)
    {
        salt = keccak256(abi.encodePacked(msg.sender, salt));
        deployed = CREATE3.deploy(salt, creationCode, msg.value);
        deployed.functionCall(data);
    }

    /// @inheritdoc	ICrossmintFactory
    function getDeployed(address deployer, bytes32 salt) external view override returns (address deployed) {
        salt = keccak256(abi.encodePacked(deployer, salt));
        return CREATE3.getDeployed(salt);
    }
}
