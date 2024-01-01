// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./BallotsBox.sol";
import "./MotionsRepo.sol";
import "./RulesParser.sol";
import "./DelegateMap.sol";

interface IMeetingMinutes {

    //##################
    //##    events    ##
    //##################

    event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);

    event ProposeMotionToGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed proposer);

    event ProposeMotionToBoard(uint256 indexed seqOfMotion, uint256 indexed proposer);

    event EntrustDelegate(uint256 indexed seqOfMotion, uint256 indexed delegate, uint256 indexed principal);

    event CastVoteInGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, uint indexed attitude, bytes32 sigHash);    

    event CastVoteInBoardMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, uint indexed attitude, bytes32 sigHash);    

    event VoteCounting(uint256 indexed seqOfMotion, uint8 indexed result);            

    event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

    //#################
    //##  Write I/O  ##
    //#################

    // function addMotion(
    //     MotionsRepo.Head memory head,
    //     uint256 contents
    // ) external returns (uint64);

    function nominateOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint canidate,
        uint nominator
    ) external returns(uint64);

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint nominator    
    ) external returns(uint64);

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer    
    ) external returns(uint64);

    function createMotionToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external returns (uint64);

    function createMotionToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external returns (uint64);

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external returns(uint64);

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint proposer
    ) external;

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external;

    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate, 
        uint principal
    ) external;

    // ==== Vote ====

    function castVoteInGeneralMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function castVoteInBoardMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    // ==== UpdateVoteResult ====

    function voteCounting(bool flag0, uint256 seqOfMotion, MotionsRepo.VoteCalBase memory base) 
        external returns(uint8);

    // ==== ExecResolution ====

    function execResolution(uint256 seqOfMotion, uint256 contents, uint caller)
        external;

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external;

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external;

    function execAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns(uint contents);

    //################
    //##    Read    ##
    //################


    // ==== Motions ====

    function isProposed(uint256 seqOfMotion) external view returns (bool);

    function voteStarted(uint256 seqOfMotion) external view returns (bool);

    function voteEnded(uint256 seqOfMotion) external view returns (bool);

    // ==== Delegate ====

    function getVoterOfDelegateMap(uint256 seqOfMotion, uint256 acct)
        external view returns (DelegateMap.Voter memory);

    function getDelegateOf(uint256 seqOfMotion, uint acct)
        external view returns (uint);

    // function getLeavesWeightAtDate(
    //     uint256 seqOfMotion, 
    //     uint caller,
    //     uint baseDate
    // ) external view returns(DelegateMap.LeavesInfo memory info);

    // function getLeavesHeadcountOfDirectors(
    //     uint256 seqOfMotion, 
    //     uint caller
    // ) external view returns(uint32 head);

    // ==== motion ====

    function getMotion(uint256 seqOfMotion)
        external view returns (MotionsRepo.Motion memory motion);

    // ==== voting ====

    function isVoted(uint256 seqOfMotion, uint256 acct) external view returns (bool);

    function isVotedFor(
        uint256 seqOfMotion,
        uint256 acct,
        uint atti
    ) external view returns (bool);

    function getCaseOfAttitude(uint256 seqOfMotion, uint atti)
        external view returns (BallotsBox.Case memory );

    function getBallot(uint256 seqOfMotion, uint256 acct)
        external view returns (BallotsBox.Ballot memory);

    function isPassed(uint256 seqOfMotion) external view returns (bool);

    function getSeqList() external view returns (uint[] memory);

}
