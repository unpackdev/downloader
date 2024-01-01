// Copyright (c) 2023 Scale Labs Ltd. All rights reserved.
// Scale Labs licenses this file to you under the Apache 2.0 license.

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./CREATE3.sol";
import "./Nameable.sol";

// Deployed at 0x88a801002f494a98e1D0710a1210c283B2B1bfae

contract HalfBakedHeroesDeployer is Ownable {
    string public constant ENS_NAME = "deployer.hbhart.eth";

    constructor() payable {
        _initializeOwner(msg.sender);
        Nameable.setName(ENS_NAME);
    }

    function create3(bytes32 salt, bytes memory creationCode) external payable onlyOwner returns (address addr) {
        addr = CREATE3.deploy(salt, creationCode, 0);
        Ownable(addr).transferOwnership(msg.sender);
    }

    function reregisterName() external payable onlyOwner returns (bytes32 node) {
        return Nameable.setName(ENS_NAME);
    }

    function addressOf(bytes32 salt) external view returns (address) {
        return CREATE3.getDeployed(salt);
    }
}
