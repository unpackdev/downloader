// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

import "./StorageSlot.sol";
import "./Initializable.sol";
import "./AccessControl.sol";


contract ArrayRolesStorage is Initializable {

    bytes32 internal constant _STORAGE_SLOT = 0x7a90f6c545a08ef8e125aa088f88bee6937d2426935a3bd35718900e7e0b18b7;

    modifier onlyDev() {

        require(IAccessControl(getRoles()).hasRole(keccak256('DEVELOPER'), msg.sender));
        _;
    }
    modifier onlyGov() {
        require(IAccessControl(getRoles()).hasRole(keccak256('GOVERNANCE'), msg.sender));
        _;
    }

    modifier onlyDAOMSIG() {
        require(IAccessControl(getRoles()).hasRole(keccak256('DAO_MULTISIG'), msg.sender));
        _;
    }

    modifier onlyDEVMSIG() {
        require(IAccessControl(getRoles()).hasRole(keccak256('DEV_MULTISIG'), msg.sender));
        _;
    }

    modifier onlyTimelock() {
        require(IAccessControl(getRoles()).hasRole(keccak256('TIMELOCK'), msg.sender));
        _;
    }

    function initialize(address _access)
    public
    initializer
    {
        assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.accesscontrol.storage")) - 1));
        StorageSlot.getAddressSlot(_STORAGE_SLOT).value = _access;

    }

    function getRoles()
    internal
    view
    returns (address)
    {
        return StorageSlot.getAddressSlot(_STORAGE_SLOT).value;
    }
}
