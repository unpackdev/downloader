// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./RolesRepo.sol";

import "./IRegCenter.sol";
import "./IGeneralKeeper.sol";

interface IAccessControl {

    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        address indexed owner,
        address indexed directKeeper,
        address regCenter,
        address indexed generalKeeper
    );

    event SetOwner(address indexed acct);

    event SetDirectKeeper(address indexed keeper);

    event SetRoleAdmin(bytes32 indexed role, address indexed acct);

    event LockContents();

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external;

    function setOwner(address acct) external;

    function setDirectKeeper(address keeper) external;

    function takeBackKeys(address target) external;

    function setRoleAdmin(bytes32 role, address acct) external;

    function grantRole(bytes32 role, address acct) external;

    function revokeRole(bytes32 role, address acct) external;

    function renounceRole(bytes32 role) external;

    function abandonRole(bytes32 role) external;

    function lockContents() external;

    // ##################
    // ##   查询端口    ##
    // ##################

    function getOwner() external view returns (address);

    function getDK() external view returns (address);

    function isFinalized() external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (address);

    function hasRole(bytes32 role, address acct) external view returns (bool);

}
