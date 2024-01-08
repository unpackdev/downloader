// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./OwnableUpgradeable.sol";

abstract contract AdminableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) public isAdmin;

    event SetAdminPermission(address indexed admin, bool permission);

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Only admin can call");
        _;
    }

    modifier onlyOwnerOrAdmin {
        require((owner() == msg.sender) || isAdmin[msg.sender], "Only owner or admin can call");
        _;
    }

    function __Adminable_init() internal initializer {
        __Ownable_init();
    }


    // ** ONLY OWNER functions **

    function setAdminPermission(address _user, bool _permission) external onlyOwner {
        isAdmin[_user] = _permission;

        emit SetAdminPermission(_user, _permission);
    }
}
