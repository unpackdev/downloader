// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library RolesRepo {

    struct Role {
        address admin;
        mapping(address => bool) isMember;
    }

    struct Repo {
        address owner;
        uint8 state; // 0-pending; 1-initiated; 2-finalized
        mapping(bytes32 => Role) roles;
    }

    // ##################
    // ##    Modifier  ##
    // ##################

    modifier isOwner(Repo storage repo, address caller) {
        require(
            repo.owner == caller,
            "RR.isOwner: not owner"
        );
        _;
    }

    modifier isRoleAdmin(Repo storage repo, bytes32 role, 
        address caller) 
    {
        require(
            repo.roles[role].admin == caller, 
            "RR.isRoleAdmin: not admin"
        );
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    function initDoc(Repo storage repo, address owner) public 
    {
        require(repo.state == 0, "already initiated");
        repo.state = 1;
        repo.owner = owner;
    }

    function setOwner(
        Repo storage repo, 
        address acct,
        address caller
    ) public isOwner(repo, caller){
        repo.owner = acct;
    }

    // ==== role ====

    function setRoleAdmin(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public isOwner(repo, caller) {
        repo.roles[role].admin = acct;
        repo.roles[role].isMember[acct] = true;
    }

    function quitRoleAdmin(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public isRoleAdmin(repo, role, caller) {
        delete repo.roles[role].admin;
        delete repo.roles[role].isMember[caller];
    }
    
    function grantRole(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public isRoleAdmin(repo, role, caller) {
        repo.roles[role].isMember[acct] = true;
    }

    function revokeRole(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public isRoleAdmin(repo, role, caller) {
        delete repo.roles[role].isMember[acct];
    }

    function renounceRole(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public {
        delete repo.roles[role].isMember[caller];
    }

    function abandonRole(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public isOwner(repo, caller) {
        delete repo.roles[role];
    }

    // ###############
    // ##   Read    ##
    // ###############

    function getOwner(
        Repo storage repo
    ) public view returns (address) {
        return repo.owner;
    }

    function getRoleAdmin(Repo storage repo, bytes32 role)
        public view returns (address)
    {
        return repo.roles[role].admin;
    }

    function hasRole(
        Repo storage repo,
        bytes32 role,
        address acct
    ) public view returns (bool) {
        return repo.roles[role].isMember[acct];
    }
}
