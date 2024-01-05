// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./Executor.sol";
import "./IDependencyController.sol";

/// @title Provides a single point of reference to verify integrity
/// of the roles structure and facilitate governance actions
/// within our system as well as performing cache invalidation for
/// roles and inter-contract relationships
contract DependencyController is RoleAware, IDependencyController {
    constructor(address _roles) RoleAware(_roles) {}

    address public override currentExecutor;

    address[] public managedContracts;
    mapping(uint256 => bool) public knownCharacters;
    mapping(uint256 => bool) public knownRoles;

    uint256[] public allCharacters;
    uint256[] public allRoles;

    function executeAsOwner(address executor) external onlyOwnerExec {
        uint256[] memory requiredRoles = Executor(executor).requiredRoles();

        for (uint256 i = 0; requiredRoles.length > i; i++) {
            _giveRole(requiredRoles[i], executor);
        }

        updateCaches(executor);
        currentExecutor = executor;
        Executor(executor).execute();
        currentExecutor = address(0);

        uint256 len = requiredRoles.length;
        for (uint256 i = 0; len > i; i++) {
            _removeRole(requiredRoles[i], executor);
        }
    }

    /// Orchestrate roles and permission for contract
    function manageContract(
        address contr,
        uint256[] memory charactersPlayed,
        uint256[] memory rolesPlayed
    ) external onlyOwnerExec {
        managedContracts.push(contr);

        // set up all characters this contract plays
        uint256 len = charactersPlayed.length;
        for (uint256 i = 0; len > i; i++) {
            uint256 character = charactersPlayed[i];
            _setMainCharacter(character, contr);
        }

        // all roles this contract plays
        len = rolesPlayed.length;
        for (uint256 i = 0; len > i; i++) {
            uint256 role = rolesPlayed[i];
            _giveRole(role, contr);
        }

        updateCaches(contr);
    }

    ///  Remove roles and permissions for contract
    function disableContract(address contr) external onlyOwnerExecDisabler {
        _disableContract(contr);
    }

    function _disableContract(address contr) internal {
        uint256 len = allRoles.length;
        for (uint256 i = 0; len > i; i++) {
            if (roles.getRole(allRoles[i], contr)) {
                _removeRole(allRoles[i], contr);
            }
        }

        len = allCharacters.length;
        for (uint256 i = 0; len > i; i++) {
            if (roles.mainCharacters(allCharacters[i]) == contr) {
                _setMainCharacter(allCharacters[i], address(0));
            }
        }
    }

    /// Activate role
    function giveRole(uint256 role, address actor) external onlyOwnerExec {
        _giveRole(role, actor);
    }

    /// Disable role
    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDisabler
    {
        _removeRole(role, actor);
    }

    function _removeRole(uint256 role, address actor) internal {
        roles.removeRole(role, actor);
        updateRoleCache(role, actor);
    }

    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExec
    {
        _setMainCharacter(role, actor);
    }

    function _giveRole(uint256 role, address actor) internal {
        if (!knownRoles[role]) {
            knownRoles[role] = true;
            allRoles.push(role);
        }
        roles.giveRole(role, actor);
        updateRoleCache(role, actor);
    }

    function _setMainCharacter(uint256 character, address actor) internal {
        if (!knownCharacters[character]) {
            knownCharacters[character] = true;
            allCharacters.push(character);
        }
        roles.setMainCharacter(character, actor);
        updateMainCharacterCache(character);
    }

    function updateMainCharacterCache(uint256 character) public override {
        uint256 len = managedContracts.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(managedContracts[i]).updateMainCharacterCache(character);
        }
    }

    function updateRoleCache(uint256 role, address contr) public override {
        uint256 len = managedContracts.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(managedContracts[i]).updateRoleCache(role, contr);
        }
    }

    function updateCaches(address contr) public {
        // update this contract with all characters we know about
        uint256 len = allCharacters.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(contr).updateMainCharacterCache(allCharacters[i]);
        }

        // update this contract with all roles for all contracts we know about
        len = allRoles.length;
        for (uint256 i = 0; len > i; i++) {
            for (uint256 j = 0; managedContracts.length > j; j++) {
                RoleAware(contr).updateRoleCache(
                    allRoles[i],
                    managedContracts[j]
                );
            }
        }
    }

    function allManagedContracts() external view returns (address[] memory) {
        return managedContracts;
    }
}
