// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import "./Ownable.sol";

interface IVaultCommon {

    function token0() external returns(address);

    function token1() external returns(address);

}

contract UniverseResolver is Ownable {

    /// @dev Status of Universe Vault
    enum Status { unRegistered, working, abandon }

    /// @dev Have been Registered Vault Address
    address[] public vaultLists;
    /// @dev Status of Universe Vault
    mapping(address => Status) private vaultStatus;
    /// @dev Binding Vaults of UniverseVault and otherVault （Same Token0 and Token1）
    mapping(address => mapping(address => bool)) private bindingVault;

    /* ========== VIEW ========== */

    function checkUniverseVault(address universeVault) external view returns(bool status){
        if (vaultStatus[universeVault] == Status.working) {
            status = true;
        }
    }

    /// @dev Check Relationship of two vault
    function checkBindingStatus(address universeVault, address vault) external view returns(bool status){
        if (vaultStatus[universeVault] == Status.working && bindingVault[universeVault][vault]) {
            status = true;
        }
    }

    /// @dev Get All Official Vaults List
    function getAllVaultAddress() external view returns(address[] memory workingVaults) {
        address[] memory vaults = vaultLists;
        uint256 length = vaults.length;
        bool[] memory status = new bool[](length);
        // get abandon Vaults status
        uint256 workNumber;
        for (uint256 i; i < length; i++) {
            if (vaultStatus[vaults[i]] == Status.working) {
                status[i] = true;
                workNumber++;
            }
        }
        if(workNumber > 0){
            // get working vaults list
            workingVaults = new address[](workNumber);
            uint256 idx;
            for (uint256 i; i < length; i++) {
                if (status[i]) {
                    workingVaults[idx] = vaults[i];
                    idx += 1;
                }
            }
        }
    }

    /* ========== INTERNAL ========== */

    function _addVault(address universeVault) internal {
        Status oldStatus = vaultStatus[universeVault];
        if (oldStatus != Status.working) {
            vaultStatus[universeVault] = Status.working;
        }
        if (oldStatus == Status.unRegistered) {
            vaultLists.push(universeVault);
            emit AddVault(universeVault);
        }
    }

    function _removeVault(address universeVault) internal {
        if (vaultStatus[universeVault] == Status.working) {
            vaultStatus[universeVault] = Status.abandon;
            emit RemoveVault(universeVault);
        }
    }

    function _addBinding(address universeVault, address bonding) internal {
        if (!bindingVault[universeVault][bonding]) {
            if (   IVaultCommon(universeVault).token0() == IVaultCommon(bonding).token0()
                && IVaultCommon(universeVault).token1() == IVaultCommon(bonding).token1()
            ){
                bindingVault[universeVault][bonding] = true;
                emit AddBinding(universeVault, bonding);
            }
        }
    }

    function _removeBinding(address universeVault, address bonding) internal {
        bindingVault[universeVault][bonding] = false;
        emit RemoveBinding(universeVault, bonding);
    }

    /* ========== EXTERNAL ========== */

    function addVault(address[] memory universeVaults) external onlyOwner {
        for (uint256 i; i < universeVaults.length; i++) {
            _addVault(universeVaults[i]);
        }
    }

    function removeVault(address[] memory universeVaults) external onlyOwner {
        for (uint256 i; i < universeVaults.length; i++) {
            _removeVault(universeVaults[i]);
        }
    }

    function addBinding(address universeVault, address[] memory bindings) external onlyOwner {
        require(vaultStatus[universeVault] == Status.working, 'universeVault is not Working!');
        for (uint256 i; i < bindings.length; i++) {
            _addBinding(universeVault, bindings[i]);
        }
    }

    function removeBinding(address universeVault, address[] memory bindings) external onlyOwner {
        for (uint256 i; i < bindings.length; i++) {
            _removeBinding(universeVault, bindings[i]);
        }
    }

    /* ========== EVENT ========== */

    /// @dev Add Vault to the Vault List
    event AddVault(address indexed vault);
    /// @dev Set Status From Working to Abandon
    event RemoveVault(address indexed vault);
    /// @dev Binding RelationShip
    event AddBinding(address indexed vault, address bonding);
    /// @dev Remove RelationShip
    event RemoveBinding(address indexed vault, address bonding);

}
