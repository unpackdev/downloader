// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./CREATE3.sol";

import "./ICREATE3Factory.sol";

import "./Ownable.sol";

/// @title Factory for deploying contracts to deterministic addresses via CREATE3
/// @author zefram.eth
/// @author dinngo

contract CREATE3Factory is ICREATE3Factory, Ownable {
    constructor(address deployer) {
        transferOwnership(deployer);
    }

    /// @inheritdoc	ICREATE3Factory
    function deploy(
        bytes32 salt,
        bytes memory creationCode
    ) external payable override onlyOwner returns (address deployed) {
        return CREATE3.deploy(salt, creationCode, msg.value);
    }

    /// @inheritdoc	ICREATE3Factory
    function getDeployed(
        bytes32 salt
    ) external view override returns (address deployed) {
        return CREATE3.getDeployed(salt);
    }
}
