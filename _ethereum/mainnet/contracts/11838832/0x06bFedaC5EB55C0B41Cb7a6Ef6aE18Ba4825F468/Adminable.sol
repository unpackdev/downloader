// SPDX-License-Identifier: None
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./AccessControl.sol";
import "./Initializable.sol";

 /// @title   Admin Role Contract
 /// @author  DEXAG, Inc.
 /// @notice  This contract is a utility for an admin role access.
abstract contract Adminable is Initializable, AccessControl {
    bytes32 public constant SLINGSHOT_ADMIN_ROLE = keccak256("SLINGSHOT_ADMIN_ROLE");

    function initializeAdmin(address _admin) internal {
        _setRoleAdmin(SLINGSHOT_ADMIN_ROLE, SLINGSHOT_ADMIN_ROLE);
        _setupRole(SLINGSHOT_ADMIN_ROLE, _admin);
    }

    modifier onlyAdmin() {
        require(hasRole(SLINGSHOT_ADMIN_ROLE, _msgSender()), "Adminable: not an admin");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "Adminable: not a role");
        _;
    }

    modifier onlyAdminIfInitialized() {
        if (isInitialized()) {
            if(getRoleMemberCount(SLINGSHOT_ADMIN_ROLE) > 0) {
                require(hasRole(SLINGSHOT_ADMIN_ROLE, _msgSender()), "Adminable: not an admin");
                _;
            }
        } else {
            _;
        }
    }
}
