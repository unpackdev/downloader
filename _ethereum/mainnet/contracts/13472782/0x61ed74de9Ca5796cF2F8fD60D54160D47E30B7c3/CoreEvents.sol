// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./AccessControl.sol";

import "./ICore.sol";
import "./IAgToken.sol";
import "./IStableMaster.sol";

/// @title CoreEvents
/// @author Angle Core Team
/// @notice All the events used in the `Core` contract
contract CoreEvents {
    event StableMasterDeployed(address indexed _stableMaster, address indexed _agToken);

    event StableMasterRevoked(address indexed _stableMaster);

    event GovernorRoleGranted(address indexed governor);

    event GovernorRoleRevoked(address indexed governor);

    event GuardianRoleChanged(address indexed oldGuardian, address indexed newGuardian);

    event CoreChanged(address indexed newCore);
}
