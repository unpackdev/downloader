// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./Strings.sol";

abstract contract RoleControl is AccessControl {

    bytes32 public constant OPERATOR = keccak256("MINTER_OPERATOR");

    function isAdmin(address account) public view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isOperator(address account) public view returns(bool) {
        return hasRole(OPERATOR, account);
    }

    function grantAdminRole(address account) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function grantOperatorRole(address account) public onlyAdmin {
        grantRole(OPERATOR, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}

