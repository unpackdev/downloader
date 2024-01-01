// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
import "./LibAdmin.sol";
import "./LibMeta.sol";
import "./LibDiamond.sol";

/// @title GovWorld Admin Registry Contract
/// @dev using this contract for all the access controls in Gov Loan Builder

contract AdminRegistryFacet {
    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();
        require(
            s.approvedAdminRoles[_admin].addGovAdmin,
            "GAR: not add or edit admin role"
        );
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        LibAdminStorage.AdminStorage storage s = LibAdminStorage
            .adminRegistryStorage();
        require(
            s.approvedAdminRoles[_admin].editGovAdmin,
            "GAR: not edit admin role"
        );
        _;
    }

    /// @dev initializing the admin facet to add superadmin and three other admins as a default approved
    /// @param _superAdmin the superAdmin control all the setter functions like Platform Fee, AutoSell Fee
    /// @param _admin1 default admin 1
    /// @param _admin2 default admin 2
    /// @param _admin3 default admin 3
    function adminRegistryInit(
        address _superAdmin,
        address _admin1,
        address _admin2,
        address _admin3
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            LibMeta._msgSender() == ds.contractOwner,
            "Must own the contract."
        );

        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.allApprovedAdmins.length == 0, "Already Initialized Admins");
        require(
            _superAdmin != address(0) &&
                _admin1 != address(0) &&
                _admin2 != address(0) &&
                _admin3 != address(0),
            "GAR: Invalid address"
        );
        require(
            _superAdmin != _admin1 &&
                _superAdmin != _admin2 &&
                _superAdmin != _admin3 &&
                _admin1 != _admin2 &&
                _admin1 != _admin3 &&
                _admin2 != _admin3,
            "cannot add same addresses"
        );
        //owner becomes the default admin.
        LibAdmin._makeDefaultApproved(
            _superAdmin,
            LibAdminStorage.AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );

        LibAdmin._makeDefaultApproved(
            _admin1,
            LibAdminStorage.AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        LibAdmin._makeDefaultApproved(
            _admin2,
            LibAdminStorage.AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        LibAdmin._makeDefaultApproved(
            _admin3,
            LibAdminStorage.AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        es.superAdmin = _superAdmin;

        es.PENDING_ADD_ADMIN_KEY = 0;
        es.PENDING_EDIT_ADMIN_KEY = 1;
        es.PENDING_REMOVE_ADMIN_KEY = 2;
        //  ADD,EDIT,REMOVE
        es.PENDING_KEYS = [0, 1, 2];

        emit LibAdmin.NewAdminApprovedByAll(
            _superAdmin,
            es.approvedAdminRoles[_superAdmin]
        );
        emit LibAdmin.NewAdminApprovedByAll(
            _admin1,
            es.approvedAdminRoles[_admin1]
        );
        emit LibAdmin.NewAdminApprovedByAll(
            _admin2,
            es.approvedAdminRoles[_admin2]
        );
        emit LibAdmin.NewAdminApprovedByAll(
            _admin3,
            es.approvedAdminRoles[_admin3]
        );
    }

    /// @dev function to transfer super admin roles to the other new admin
    /// @param _newSuperAdmin address from the existing approved admins
    function transferSuperAdmin(
        address _newSuperAdmin
    ) external returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(_newSuperAdmin != address(0), "invalid address");
        require(_newSuperAdmin != es.superAdmin, "already designated");
        require(LibMeta._msgSender() == es.superAdmin, "not super admin");

        es.approvedAdminRoles[_newSuperAdmin] = es.approvedAdminRoles[
            es.superAdmin
        ];

        uint256 lengthofApprovedAdmins = es.allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthofApprovedAdmins; i++) {
            if (es.allApprovedAdmins[i] == _newSuperAdmin) {
                es.approvedAdminRoles[_newSuperAdmin].superAdmin = true;
                es.approvedAdminRoles[es.superAdmin].superAdmin = false;
                es.superAdmin = _newSuperAdmin;

                emit LibAdmin.SuperAdminOwnershipTransfer(
                    _newSuperAdmin,
                    es.approvedAdminRoles[_newSuperAdmin]
                );
                return true;
            }
        }
        revert("Only admin can become super admin");
    }

    /// @dev Checks if a given _newAdmin is approved by all other already approved admins
    /// @param _newAdmin Address of the new admin
    /// @param _key specify the add, edit or remove key

    function isDoneByAll(
        address _newAdmin,
        uint8 _key
    ) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _areByAdmins = es.areByAdmins[_key][_newAdmin];

        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        uint256 lengthAllApprovedAdmins = es.allApprovedAdmins.length;
        for (uint256 i = 0; i < lengthAllApprovedAdmins; i++) {
            bool checkApprovedAdmins = es.allApprovedAdmins[i] != _newAdmin;
            if (
                _key == es.PENDING_ADD_ADMIN_KEY &&
                es.approvedAdminRoles[es.allApprovedAdmins[i]].addGovAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == es.allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == es.PENDING_REMOVE_ADMIN_KEY &&
                es.approvedAdminRoles[es.allApprovedAdmins[i]].editGovAdmin &&
                checkApprovedAdmins
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == es.allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == es.PENDING_EDIT_ADMIN_KEY &&
                es.approvedAdminRoles[es.allApprovedAdmins[i]].editGovAdmin &&
                checkApprovedAdmins //all but yourself.
            ) {
                allCount = allCount + 1;
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == es.allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
        }
        // standard multi-sig 51 % approvals needed to perform
        if (presentCount >= (allCount / 2) + 1) return true;
        else return false;
    }

    /// @dev makes _newAdmin an approved admin if there is only one curernt admin _newAdmin becomes
    /// @dev becomes approved as it is and if currently more then 1 admins then approveAddedAdmin needs to be
    /// @dev called  by all current admins
    /// @param _newAdmin Address of the new admin
    /// @param _adminAccess access variables for _newadmin

    function addAdmin(
        address _newAdmin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) external onlyAddGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            _adminAccess.addGovIntel ||
                _adminAccess.editGovIntel ||
                _adminAccess.addToken ||
                _adminAccess.editToken ||
                _adminAccess.addSp ||
                _adminAccess.editSp ||
                _adminAccess.addGovAdmin ||
                _adminAccess.editGovAdmin ||
                _adminAccess.addBridge ||
                _adminAccess.editBridge ||
                _adminAccess.addPool ||
                _adminAccess.editPool,
            "GAR: admin roles error"
        );
        require(
            es.pendingAdmin[es.PENDING_ADD_ADMIN_KEY] == address(0) &&
                es.pendingAdmin[es.PENDING_EDIT_ADMIN_KEY] == address(0) &&
                es.pendingAdmin[es.PENDING_REMOVE_ADMIN_KEY] == address(0),
            "GAR: only one admin can be add, edit, remove at once"
        );
        require(_newAdmin != address(0), "invalid address");
        require(_newAdmin != LibMeta._msgSender(), "GAR: call for self"); //the GovAdmin cannot add himself as admin again

        require(
            !LibAdmin._addressExists(_newAdmin, es.allApprovedAdmins),
            "GAR: cannot add again"
        );
        require(!_adminAccess.superAdmin, "GAR: superadmin assign error");

        //this admin is now in the pending list.
        LibAdmin._makePendingForAddEdit(
            _newAdmin,
            _adminAccess,
            es.PENDING_ADD_ADMIN_KEY
        );

        if (this.isDoneByAll(_newAdmin, es.PENDING_ADD_ADMIN_KEY)) {
            // _admin is now been added
            LibAdmin._makeApproved(_newAdmin, _adminAccess);
            emit LibAdmin.NewAdminApprovedByAll(_newAdmin, _adminAccess);
        } else {
            emit LibAdmin.NewAdminApproved(
                _newAdmin,
                LibMeta._msgSender(),
                es.PENDING_ADD_ADMIN_KEY
            );
        }
    }

    /// @dev call approved the admin which is already added to pending by other admin
    /// @dev if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _newAdmin Address of the new admin

    function approveAddedAdmin(
        address _newAdmin
    ) external onlyAddGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        //the admin that is adding _newAdmin must not already have approved.
        require(
            LibAdmin._isAdminAvailable(
                _newAdmin,
                LibMeta._msgSender(),
                es.PENDING_ADD_ADMIN_KEY
            ),
            "GAR: already approved"
        );

        require(
            es.pendingAdmin[es.PENDING_ADD_ADMIN_KEY] == _newAdmin,
            "GAR: nonpending error"
        );

        es.areByAdmins[es.PENDING_ADD_ADMIN_KEY][_newAdmin].push(
            LibMeta._msgSender()
        );
        emit LibAdmin.NewAdminApproved(
            _newAdmin,
            LibMeta._msgSender(),
            es.PENDING_ADD_ADMIN_KEY
        );

        //if the _newAdmin is approved by all other admins
        if (this.isDoneByAll(_newAdmin, es.PENDING_ADD_ADMIN_KEY)) {
            //making this admin approved.
            LibAdmin._makeApproved(
                _newAdmin,
                es.pendingAdminRoles[es.PENDING_ADD_ADMIN_KEY][_newAdmin]
            );
            //no  need  for pending  role now
            delete es.pendingAdminRoles[es.PENDING_ADD_ADMIN_KEY][_newAdmin];

            emit LibAdmin.NewAdminApprovedByAll(
                _newAdmin,
                es.approvedAdminRoles[_newAdmin]
            );
        }
    }

    /// @dev any admin can reject the pending admin during the approval process and one rejection means
    //  not pending anymore.
    /// @param _admin Address of the new admin

    function rejectAdmin(
        address _admin,
        uint8 _key
    ) external onlyEditGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(_admin != LibMeta._msgSender(), "GAR: call for self");
        require(
            _key == es.PENDING_ADD_ADMIN_KEY ||
                _key == es.PENDING_EDIT_ADMIN_KEY ||
                _key == es.PENDING_REMOVE_ADMIN_KEY,
            "GAR: wrong key inserted"
        );
        require(es.pendingAdmin[_key] == _admin, "GAR: nonpending error");

        //the admin that is adding _newAdmin must not already have approved.
        require(
            LibAdmin._isAdminAvailable(_admin, LibMeta._msgSender(), _key),
            "GAR: already approved"
        );
        //only with the reject of one admin call delete roles from mapping
        delete es.pendingAdminRoles[_key][_admin];
        uint256 length = es.areByAdmins[_key][_admin].length;
        for (uint256 i = 0; i < length; i++) {
            es.areByAdmins[_key][_admin].pop();
        }

        delete es.pendingAdmin[_key];
        //delete admin roles from approved mapping
        delete es.areByAdmins[_key][_admin];
        emit LibAdmin.AdminRejected(_key, _admin, LibMeta._msgSender());
    }

    /// @dev Get all Approved Admins
    /// @return address[] returns the all approved admins
    function getAllApproved() external view returns (address[] memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.allApprovedAdmins;
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _addedAdmin address of the approved/proposed added admin.
    /// @return address[] address array of the admin which approved the added admin
    function getApprovedByAdmins(
        address _addedAdmin
    ) external view returns (address[] memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.areByAdmins[es.PENDING_ADD_ADMIN_KEY][_addedAdmin];
    }

    /// @dev Get all edit by admins addresses
    /// @param _editAdminAddress address of the edit admin
    /// @return address[] address array of the admin which approved the edit admin
    function getEditbyAdmins(
        address _editAdminAddress
    ) external view returns (address[] memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.areByAdmins[es.PENDING_EDIT_ADMIN_KEY][_editAdminAddress];
    }

    /// @dev Get all admin addresses which approved the address in the parameter
    /// @param _removedAdmin address of the approved/proposed added admin.
    /// @return address[] returns the array of the admins which approved the removed admin request
    function getRemovedByAdmins(
        address _removedAdmin
    ) external view returns (address[] memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.areByAdmins[es.PENDING_REMOVE_ADMIN_KEY][_removedAdmin];
    }

    /// @dev Get pending add admin roles
    /// @param _addAdmin address of the pending added admin
    /// @return AdminAccess roles of the pending added admin
    function getpendingAddedAdminRoles(
        address _addAdmin
    ) external view returns (LibAdminStorage.AdminAccess memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminRoles[es.PENDING_ADD_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending edit admin roles
    /// @param _addAdmin address of the pending edit admin
    /// @return AdminAccess roles of the pending edit admin

    function getpendingEditedAdminRoles(
        address _addAdmin
    ) external view returns (LibAdminStorage.AdminAccess memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminRoles[es.PENDING_EDIT_ADMIN_KEY][_addAdmin];
    }

    /// @dev Get pending remove admin roles
    /// @param _addAdmin address of the pending removed admin
    /// @return AdminAccess returns the roles of the pending removed admin
    function getpendingRemovedAdminRoles(
        address _addAdmin
    ) external view returns (LibAdminStorage.AdminAccess memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.pendingAdminRoles[es.PENDING_REMOVE_ADMIN_KEY][_addAdmin];
    }

    /// @dev Initiate process of removal of admin,
    // in case there is only one admin removal is done instantly.
    // If there are more then one admin all must call removePendingAdmin.
    /// @param _admin Address of the admin requested to be removed

    function removeAdmin(
        address _admin
    ) external onlyEditGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.pendingAdmin[es.PENDING_ADD_ADMIN_KEY] == address(0) &&
                es.pendingAdmin[es.PENDING_EDIT_ADMIN_KEY] == address(0) &&
                es.pendingAdmin[es.PENDING_REMOVE_ADMIN_KEY] == address(0),
            "GAR: only one admin can be add, edit, remove at once"
        );

        require(_admin != address(0), "GAR: invalid address");
        require(_admin != es.superAdmin, "GAR: cannot remove superadmin");
        require(_admin != LibMeta._msgSender(), "GAR: call for self");

        require(
            LibAdmin._addressExists(_admin, es.allApprovedAdmins),
            "GAR: not an admin"
        );

        //this admin is now in the pending list.
        LibAdmin._makePendingForRemove(_admin, es.PENDING_REMOVE_ADMIN_KEY);

        if (this.isDoneByAll(_admin, es.PENDING_REMOVE_ADMIN_KEY)) {
            // _admin is now been removed
            LibAdmin._removeAdmin(_admin);
            emit LibAdmin.AdminRemovedByAll(_admin, LibMeta._msgSender());
        } else {
            emit LibAdmin.NewAdminApproved(
                _admin,
                LibMeta._msgSender(),
                es.PENDING_REMOVE_ADMIN_KEY
            );
        }
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
    /// @param _admin Address of the new admin

    function approveRemovedAdmin(
        address _admin
    ) external onlyEditGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(_admin != LibMeta._msgSender(), "GAR: cannot call for self");
        //the admin that is adding _admin must not already have approved.
        require(
            LibAdmin._isAdminAvailable(
                _admin,
                LibMeta._msgSender(),
                es.PENDING_REMOVE_ADMIN_KEY
            ),
            "GAR: already approved"
        );
        require(
            es.pendingAdmin[es.PENDING_REMOVE_ADMIN_KEY] == _admin,
            "GAR: nonpending admin error"
        );

        es.areByAdmins[es.PENDING_REMOVE_ADMIN_KEY][_admin].push(
            LibMeta._msgSender()
        );

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, es.PENDING_REMOVE_ADMIN_KEY)) {
            // _admin is now been removed
            LibAdmin._removeAdmin(_admin);
            emit LibAdmin.AdminRemovedByAll(_admin, LibMeta._msgSender());
        } else {
            emit LibAdmin.NewAdminApproved(
                _admin,
                LibMeta._msgSender(),
                es.PENDING_REMOVE_ADMIN_KEY
            );
        }
    }

    /// @dev Initiate process of edit of an admin,
    // If there are more then one admin all must call approveEditAdmin
    /// @param _admin Address of the admin requested to be removed

    function editAdmin(
        address _admin,
        LibAdminStorage.AdminAccess memory _adminAccess
    ) external onlyEditGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            _adminAccess.addGovIntel ||
                _adminAccess.editGovIntel ||
                _adminAccess.addToken ||
                _adminAccess.editToken ||
                _adminAccess.addSp ||
                _adminAccess.editSp ||
                _adminAccess.addGovAdmin ||
                _adminAccess.editGovAdmin ||
                _adminAccess.addBridge ||
                _adminAccess.editBridge ||
                _adminAccess.addPool ||
                _adminAccess.editPool,
            "GAR: admin right error"
        );
        require(
            es.pendingAdmin[es.PENDING_ADD_ADMIN_KEY] == address(0) &&
                es.pendingAdmin[es.PENDING_EDIT_ADMIN_KEY] == address(0) &&
                es.pendingAdmin[es.PENDING_REMOVE_ADMIN_KEY] == address(0),
            "GAR: only one admin can be add, edit, remove at once"
        );
        require(_admin != LibMeta._msgSender(), "GAR: self edit error");
        require(_admin != es.superAdmin, "GAR: superadmin error");

        require(
            LibAdmin._addressExists(_admin, es.allApprovedAdmins),
            "GAR: not admin"
        );

        require(!_adminAccess.superAdmin, "GAR: cannot assign super admin");

        //this admin is now in the pending list.
        LibAdmin._makePendingForAddEdit(
            _admin,
            _adminAccess,
            es.PENDING_EDIT_ADMIN_KEY
        );

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, es.PENDING_EDIT_ADMIN_KEY)) {
            // _admin is now an approved admin.
            LibAdmin._editAdmin(_admin);
            emit LibAdmin.AdminEditedApprovedByAll(
                _admin,
                es.approvedAdminRoles[_admin]
            );
        } else {
            emit LibAdmin.NewAdminApproved(
                _admin,
                LibMeta._msgSender(),
                es.PENDING_EDIT_ADMIN_KEY
            );
        }
    }

    /// @dev call approved the admin which is already added to pending by other admin
    // if all current admins call approveEditAdmin are complete the admin edits become active
    /// @param _admin Address of the new admin

    function approveEditAdmin(
        address _admin
    ) external onlyEditGovAdminRole(LibMeta._msgSender()) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(_admin != LibMeta._msgSender(), "GAR: call for self");

        //the admin that is adding _admin must not already have approved.
        require(
            LibAdmin._isAdminAvailable(
                _admin,
                LibMeta._msgSender(),
                es.PENDING_EDIT_ADMIN_KEY
            ),
            "GAR: already approved"
        );
        require(
            es.pendingAdmin[es.PENDING_EDIT_ADMIN_KEY] == _admin,
            "GAR: nonpending admin error"
        );

        es.areByAdmins[es.PENDING_EDIT_ADMIN_KEY][_admin].push(
            LibMeta._msgSender()
        );

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, es.PENDING_EDIT_ADMIN_KEY)) {
            // _admin is now an approved admin.
            LibAdmin._editAdmin(_admin);
            emit LibAdmin.AdminEditedApprovedByAll(
                _admin,
                es.approvedAdminRoles[_admin]
            );
        } else {
            emit LibAdmin.NewAdminApproved(
                _admin,
                LibMeta._msgSender(),
                es.PENDING_EDIT_ADMIN_KEY
            );
        }
    }

    function isAddGovAdminRole(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].addGovAdmin;
    }

    /// @dev using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(
        address admin
    ) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].editGovAdmin;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].addToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].editToken;
    }

    /// @dev using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].addSp;
    }

    /// @dev using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].editSp;
    }

    /// @dev using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[admin].superAdmin;
    }

    /// @dev Get approved admin roles
    /// @param _approvedAdmin address of the approved admin
    /// @return AdminAccess returns the roles of the approved admin
    function getApprovedAdminRoles(
        address _approvedAdmin
    ) external view returns (LibAdminStorage.AdminAccess memory) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        return es.approvedAdminRoles[_approvedAdmin];
    }

    function getPendingAdmin(uint8 _key) external view returns (address) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        return es.pendingAdmin[_key];
    }
}
