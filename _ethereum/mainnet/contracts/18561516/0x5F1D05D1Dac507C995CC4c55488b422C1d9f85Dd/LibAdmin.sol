// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibMeta.sol";
import "./LibAdminStorage.sol";
import "./LibAppStorage.sol";

library LibAdmin {
    event NewAdminApproved(
        address indexed _newAdmin,
        address indexed _addByAdmin,
        uint8 indexed _key
    );
    event NewAdminApprovedByAll(
        address indexed _newAdmin,
        LibAdminStorage.AdminAccess _adminAccess
    );
    event AdminRemovedByAll(
        address indexed _admin,
        address indexed _removedByAdmin
    );
    event AdminEditedApprovedByAll(
        address indexed _admin,
        LibAdminStorage.AdminAccess _adminAccess
    );
    event AdminRejected(
        uint256 indexed _key,
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event SuperAdminOwnershipTransfer(
        address indexed _superAdmin,
        LibAdminStorage.AdminAccess _adminAccess
    );

    /// @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
    /// @param _newAdmin Address of the new admin
    /// @param _by Address of the existing admin that may have approved/edited/removed _newAdmin already.
    /// @param _key Address of the existing admin that may have approved/edited/removed _newAdmin already.
    /// @return bool returns true or false value

    function _isAdminAvailable(
        address _newAdmin,
        address _by,
        uint8 _key
    ) internal view returns (bool) {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        uint256 pendingKeyslength = s.PENDING_KEYS.length;
        for (uint256 k = 0; k < pendingKeyslength; k++) {
            if (_key == s.PENDING_KEYS[k]) {
                uint256 approveByAdminsLength = s
                .areByAdmins[_key][_newAdmin].length;
                for (uint256 i = 0; i < approveByAdminsLength; i++) {
                    if (s.areByAdmins[_key][_newAdmin][i] == _by) {
                        return false; //approved/edited/removed
                    }
                }
            }
        }
        return true; //not approved/edited/removed
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeDefaultApproved(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //no need for approved by admin for the new  admin anymore.
        delete s.areByAdmins[s.PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        s.approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        s.allApprovedAdmins.push(_newAdmin);
    }

    /// @dev makes _newAdmin an approved admin and emits the event
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makeApproved(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //no need for approved by admin for the new  admin anymore.
        delete s.areByAdmins[s.PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        s.approvedAdminRoles[_newAdmin] = _adminAccess;
        require(
            s.allApprovedAdmins.length + 1 <= LibAppStorage.arrayMaxSize,
            "add admin: array max size reached"
        );
        //new key for mapping approvedAdminRoles
        s.allApprovedAdmins.push(_newAdmin);
        delete s.pendingAdmin[s.PENDING_ADD_ADMIN_KEY];
    }

    /// @dev makes _newAdmin a pending admin for approval to be given by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function _makePendingForAddEdit(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess,
        uint8 _key
    ) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //the admin who is adding the new admin is approving _newAdmin by default
        s.areByAdmins[_key][_newAdmin].push(LibMeta._msgSender());
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        s.pendingAdminRoles[_key][_newAdmin] = _adminAccess;
        s.pendingAdmin[_key] = _newAdmin;
    }

    /// @dev remove _admin by the approved admins
    /// @param _admin Address of the approved admin

    function _removeAdmin(address _admin) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        // _admin is now a removed admin.
        delete s.approvedAdminRoles[_admin];
        delete s.areByAdmins[s.PENDING_REMOVE_ADMIN_KEY][_admin];
        delete s.areByAdmins[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.areByAdmins[s.PENDING_ADD_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_ADD_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_REMOVE_ADMIN_KEY][_admin];

        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, s.allApprovedAdmins));
        delete s.pendingAdmin[s.PENDING_REMOVE_ADMIN_KEY];
    }

    /// @dev edit admin roles of the approved admin
    /// @param _admin address which is going to be edited

    function _editAdmin(address _admin) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        s.approvedAdminRoles[_admin] = s.pendingAdminRoles[
            s.PENDING_EDIT_ADMIN_KEY
        ][_admin];

        delete s.areByAdmins[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.pendingAdminRoles[s.PENDING_EDIT_ADMIN_KEY][_admin];
        delete s.pendingAdmin[s.PENDING_EDIT_ADMIN_KEY];
    }

    /// @dev remove the index of the approved admin address
    function _removeIndex(uint256 index) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        uint256 length = s.allApprovedAdmins.length;

        // Swap the element to remove with the last element
        uint256 lastIndex = length - 1;
        if (index != lastIndex) {
            s.allApprovedAdmins[index] = s.allApprovedAdmins[lastIndex];
        }

        s.allApprovedAdmins.pop();
    }

    /// @dev makes _admin a pending admin for approval to be given by
    /// @dev all current admins for removing this admnin.
    /// @param _admin address of the new admin which is going pending for remove

    function _makePendingForRemove(address _admin, uint8 _key) internal {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();

        //the admin who is adding the new admin is approving _newAdmin by default
        s.areByAdmins[_key][_admin].push(LibMeta._msgSender());
        s.pendingAdmin[_key] = _admin;
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        s.pendingAdminRoles[_key][_admin] = s.approvedAdminRoles[_admin];
    }

    function _getIndex(
        address _valueToFindAndRemove,
        address[] memory from
    ) internal pure returns (uint256 index) {
        uint256 length = from.length;
        for (uint256 i = 0; i < length; i++) {
            if (from[i] == _valueToFindAndRemove) {
                return i;
            }
        }
    }

    /// @dev check if the address exist in the pending admins array
    function _addressExists(
        address _valueToFind,
        address[] memory from
    ) internal pure returns (bool) {
        uint256 length = from.length;
        for (uint256 i = 0; i < length; i++) {
            if (from[i] == _valueToFind) {
                return true;
            }
        }
        return false;
    }
}
