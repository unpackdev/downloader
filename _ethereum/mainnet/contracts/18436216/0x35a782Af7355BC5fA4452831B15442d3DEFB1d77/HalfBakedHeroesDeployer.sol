// Copyright (c) 2023 Scale Labs Ltd. All rights reserved.
// Scale Labs licenses this file to you under the Apache 2.0 license.

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./CREATE3.sol";

// Deployed at 0x35a782Af7355BC5fA4452831B15442d3DEFB1d77

contract HalfBakedHeroesDeployer is Ownable {
    string public constant ENS_NAME = "deployer.hbhart.eth";

    constructor() payable {
        _initializeOwner(msg.sender);
    }

    function create3(bytes32 salt, bytes memory creationCode) external payable onlyOwner returns (address addr) {
        addr = CREATE3.deploy(salt, creationCode, 0);
    }

    function addressOf(bytes32 salt) external view returns (address) {
        return CREATE3.getDeployed(salt);
    }
}
