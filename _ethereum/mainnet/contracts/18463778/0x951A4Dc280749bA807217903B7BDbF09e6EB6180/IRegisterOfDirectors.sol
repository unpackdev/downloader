// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IMeetingMinutes.sol";

import "./OfficersRepo.sol";

interface IRegisterOfDirectors {

    //###################
    //##    events    ##
    //##################

    event AddPosition(bytes32 indexed snOfPos);

    event RemovePosition(uint256 indexed seqOfPos);

    event TakePosition(uint256 indexed seqOfPos, uint256 indexed caller);

    event QuitPosition(uint256 indexed seqOfPos, uint256 indexed caller);

    event RemoveOfficer(uint256 indexed seqOfPos);

    // event ProposeMotionToBoard(uint256 indexed seqOfMotion, uint256 indexed caller);

    // event ExecAction(uint256 indexed contents, bool success);

    //##################
    //##  Write I/O  ##
    //##################

    function createPosition(bytes32 snOfPos) external;

    function updatePosition(OfficersRepo.Position memory pos) external;

    function removePosition(uint256 seqOfPos) external;

    function takePosition (uint256 seqOfPos, uint caller) external;

    function quitPosition (uint256 seqOfPos, uint caller) external; 

    function removeOfficer (uint256 seqOfPos) external;

    //##################
    //##    读接口    ##
    //##################
    
    // ==== Positions ====

    function posExist(uint256 seqOfPos) external view returns (bool);

    function isOccupied(uint256 seqOfPos) external view returns (bool);

    function getPosition(uint256 seqOfPos) external view 
        returns (OfficersRepo.Position memory);

    // ==== Managers ====

    function isManager(uint256 acct) external view returns (bool);

    function getNumOfManagers() external view returns (uint256);    

    function getManagersList() external view returns (uint256[] memory);

    function getManagersPosList() external view returns(uint[] memory);

    // function getManagersFullPosInfo() external view 
    //     returns(OfficersRepo.Position[] memory);

    // ==== Directors ====

    function isDirector(uint256 acct) external view returns (bool);

    function getNumOfDirectors() external view returns (uint256);

    function getDirectorsList() external view 
        returns (uint256[] memory);

    function getDirectorsPosList() external view 
        returns (uint256[] memory);

    // function getDirectorsFullPosInfo() external view 
    //     returns(OfficersRepo.Position[] memory);        

    // ==== Executives ====
    
    function hasPosition(uint256 acct, uint256 seqOfPos)
        external view returns(bool);

    function getPosInHand(uint256 acct) 
        external view returns (uint256[] memory);

    function getFullPosInfoInHand(uint acct) 
        external view returns (OfficersRepo.Position[] memory);

    function hasTitle(uint acct, uint title) 
        external returns (bool flag);

    function hasNominationRight(uint seqOfPos, uint acct) 
        external view returns (bool);

    // ==== seatsCalculator ====

    // function getBoardSeatsQuota(uint256 acct) external view 
    //     returns(uint256);

    function getBoardSeatsOccupied(uint acct) external view 
        returns (uint256);

}
