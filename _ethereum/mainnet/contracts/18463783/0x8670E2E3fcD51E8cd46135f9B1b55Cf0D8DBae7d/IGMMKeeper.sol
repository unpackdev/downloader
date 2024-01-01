// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IInvestmentAgreement.sol";

import "./MotionsRepo.sol";
import "./OfficersRepo.sol";

import "./ISigPage.sol";

interface IGMMKeeper {

    // ################
    // ##   Motion   ##
    // ################

    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external;

    function createMotionToRemoveDirector(
        uint256 seqOfPos,
        uint caller
    ) external;

    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor,  uint proposer) external;

    function proposeToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint caller
    ) external;

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external;


    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external;

    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate, uint caller) external;

    function proposeMotionToGeneralMeeting(uint256 seqOfMotion,uint caller) external;

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function voteCountingOfGM(uint256 seqOfMotion) external;

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

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns(uint);

}
