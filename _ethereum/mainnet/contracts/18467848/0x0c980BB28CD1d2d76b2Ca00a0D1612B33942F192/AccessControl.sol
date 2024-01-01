// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAccessControl.sol";

contract AccessControl is IAccessControl {
    using RolesRepo for RolesRepo.Repo;

    bytes32 private constant _ATTORNEYS = bytes32("Attorneys");

    RolesRepo.Repo private _roles;

    address private _dk;
    IRegCenter internal _rc;
    IGeneralKeeper internal _gk;

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyOwner {
        require(
            _roles.getOwner() == msg.sender,
            "AC.onlyOwner: NOT"
        );
        _;
    }

    modifier onlyDK {
        require(
            _dk == msg.sender,
            "AC.onlyDK: NOT"
        );
        _;
    }

    modifier onlyGC {
        require(
            _roles.getRoleAdmin(_ATTORNEYS) == msg.sender,
            "AC.onlyGC: NOT"
        );
        _;
    }

    modifier onlyKeeper {
        require(
            _gk.isKeeper(msg.sender) || 
            _dk == msg.sender, 
            "AC.onlyKeeper: NOT"
        );
        _;
    }

    modifier onlyAttorney {
        require(
            _roles.hasRole(_ATTORNEYS, msg.sender),
            "AC.onlyAttorney: NOT"
        );
        _;
    }

    modifier attorneyOrKeeper {
        require(
            _roles.hasRole(_ATTORNEYS, msg.sender) ||
            _gk.isKeeper(msg.sender),
            "AC.md.attorneyOrKeeper: NOT"
        );
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external {
        _roles.initDoc(owner);
        _dk = directKeeper;
        _rc = IRegCenter(regCenter);
        _gk = IGeneralKeeper(generalKeeper);
        emit Init(owner, directKeeper, regCenter, generalKeeper);
    }

    function setOwner(address acct) external {
        _roles.setOwner(acct, msg.sender);
        emit SetOwner(acct);
    }

    function setDirectKeeper(address acct) external onlyDK {
        _dk = acct;
        emit SetDirectKeeper(acct);
    }

    function takeBackKeys (address target) external onlyDK {
        IAccessControl(target).setDirectKeeper(msg.sender);
    }

    function setRoleAdmin(bytes32 role, address acct) external {
        _roles.setRoleAdmin(role, acct, msg.sender);
        emit SetRoleAdmin(role, acct);
    }

    function grantRole(bytes32 role, address acct) external {
        _roles.grantRole(role, acct, msg.sender);
    }

    function revokeRole(bytes32 role, address acct) external {
        _roles.revokeRole(role, acct, msg.sender);
    }

    function renounceRole(bytes32 role) external {
        _roles.renounceRole(role, msg.sender);
    }

    function abandonRole(bytes32 role) external {
        _roles.abandonRole(role, msg.sender);
    }

    function lockContents() public {
        require(_roles.state == 1, "AC.lockContents: wrong state");

        address owner = msg.sender;

        _roles.abandonRole(_ATTORNEYS, owner);
        _roles.setOwner(address(0), owner);
        _roles.state = 2;

        emit LockContents();
    }

    // ##############
    // ##   Read   ##
    // ##############

    function getOwner() public view returns (address) {
        return _roles.getOwner();
    }

    function getDK() external view returns (address) {
        return _dk;
    }

    function isFinalized() public view returns (bool) {
        return _roles.state == 2;
    }

    function getRoleAdmin(bytes32 role) public view returns (address) {
        return _roles.getRoleAdmin(role);
    }

    function hasRole(bytes32 role, address acct) public view returns (bool) {
        return _roles.hasRole(role, acct);
    }

}
