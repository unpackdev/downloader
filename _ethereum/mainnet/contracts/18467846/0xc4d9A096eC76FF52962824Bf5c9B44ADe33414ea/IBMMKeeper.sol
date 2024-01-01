// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfDirectors.sol";
import "./RulesParser.sol";

interface IBMMKeeper {
    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external;

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint nominator
    ) external;

    // ---- Docs ----

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external;

    // ---- TransferFund ----

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external;

    // ---- Action ----

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external;

    // ==== Cast Vote ====

    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external;

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external;

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    // ==== Vote Counting ====

    function voteCounting(uint256 seqOfMotion) external;

    // ==== Exec Motion ====

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external;

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns (uint);
}
