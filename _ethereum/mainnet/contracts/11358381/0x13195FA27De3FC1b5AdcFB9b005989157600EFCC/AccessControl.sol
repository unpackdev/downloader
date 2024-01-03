// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

contract AccessControl {
    event GrantRole(bytes32 indexed role, address indexed addr);
    event RevokeRole(bytes32 indexed role, address indexed addr);

    mapping(bytes32 => mapping(address => bool)) public hasRole;

    modifier onlyAuthorized(bytes32 _role) {
        require(hasRole[_role][msg.sender], "!authorized");
        _;
    }

    function _grantRole(bytes32 _role, address _addr) internal {
        require(_addr != address(0), "address = zero");

        hasRole[_role][_addr] = true;

        emit GrantRole(_role, _addr);
    }

    function _revokeRole(bytes32 _role, address _addr) internal {
        require(_addr != address(0), "address = zero");

        hasRole[_role][_addr] = false;

        emit RevokeRole(_role, _addr);
    }
}
