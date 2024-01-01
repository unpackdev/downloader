// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "./FilesRepo.sol";
import "./RulesParser.sol";

interface IFilesFolder {

    //#############
    //##  Event  ##
    //#############

    event UpdateStateOfFile(address indexed body, uint indexed state);

    //#################
    //##  Write I/O  ##
    //#################

    function regFile(bytes32 snOfDoc, address body) external;

    function circulateFile(
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    function proposeFile(address body, uint64 seqOfMotion) external;

    function voteCountingForFile(address body, bool approved) external;

    function execFile(address body) external;

    function terminateFile(address body) external;

    function setStateOfFile(address body, uint state) external;

    //##################
    //##   read I/O   ##
    //##################

    function signingDeadline(address body) external view returns (uint48);

    function closingDeadline(address body) external view returns (uint48);

    function frExecDeadline(address body) external view returns (uint48);

    function dtExecDeadline(address body) external view returns (uint48);

    function terminateStartpoint(address body) external view returns (uint48);

    function votingDeadline(address body) external view returns (uint48);

    function isRegistered(address body) external view 
        returns (bool);

    function qtyOfFiles() external view 
        returns (uint256);

    function getFilesList() external view 
        returns (address[] memory);

    function getFile(address body) external view 
        returns (FilesRepo.File memory);

    function getHeadOfFile(address body) external view 
        returns (FilesRepo.Head memory head);
}
