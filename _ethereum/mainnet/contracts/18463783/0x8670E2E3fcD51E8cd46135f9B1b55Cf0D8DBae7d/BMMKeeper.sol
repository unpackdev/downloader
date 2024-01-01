// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./IRODKeeper.sol";

contract BMMKeeper is IBMMKeeper, AccessControl {
    using RulesParser for bytes32;

    

    //##################
    //##   Modifier   ##
    //##################

    modifier directorExist(uint256 acct) {
        require(_gk.getROD().isDirector(acct), 
            "BODK.DE: not director");
        _;
    }

    //###############
    //##   Write   ##
    //###############

    // ==== CreateMotion ====

    // ---- Officers ----

    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external onlyDK {
        
        IRegisterOfDirectors _rod = _gk.getROD();
        
        require(_rod.hasNominationRight(seqOfPos, nominator),
            "BMMKeeper.nominateOfficer: no rights");
     
        _gk.getBMM().nominateOfficer(seqOfPos, _rod.getPosition(seqOfPos).seqOfVR, candidate, nominator);
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint nominator
    ) external onlyDK directorExist(nominator) {
        
        IRegisterOfDirectors _rod = _gk.getROD();
        
        require(_rod.hasNominationRight(seqOfPos, nominator),
            "BODK.createMotionToRemoveOfficer: no rights");

        _gk.getBMM().createMotionToRemoveOfficer(seqOfPos, _rod.getPosition(seqOfPos).seqOfVR, nominator);
    }

    // ---- Docs ----

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK directorExist(proposer) {
        _gk.getBMM().createMotionToApproveDoc(doc, seqOfVR, executor, proposer);
    }

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK directorExist(proposer) {

        
        IMeetingMinutes _bmm = _gk.getBMM();

        require (amt < _gk.getSHA().getRule(0).governanceRuleParser().fundApprovalThreshold * 10 ** 9,
            "BMMK.transferFund: amt overflow");

        uint64 seqOfMotion = 
            _bmm.createMotionToTransferFund(to, isCBP, amt, expireDate, seqOfVR, executor, proposer);
        _bmm.proposeMotionToGeneralMeeting(seqOfMotion, proposer);            
    }

    // ---- Actions ----

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDK directorExist(proposer){
        _gk.getBMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            proposer
        );
    }

    // ==== Cast Vote ====

    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external onlyDK directorExist(caller) {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external onlyDK directorExist(caller) {
        _gk.getBMM().proposeMotionToBoard(seqOfMotion, caller);
    }

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBMM().castVoteInBoardMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint256 caller) private view {
        

        MotionsRepo.Motion memory motion = _gk.getBMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
                uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            address doc = address(uint160(motion.contents));
            
            OfficersRepo.Position[] memory poses = 
                _gk.getROD().getFullPosInfoInHand(caller);
            uint256 len = poses.length;            
            while (len > 0) {
                require (!ISigPage(doc).isSigner(poses[len-1].nominator), 
                    "BODK.RPC: is related party");
                len --;
            }
            require (!ISigPage(doc).isSigner(caller), 
                "BODK.RPC: is related party");

        }
    }

    // ==== Vote Counting ====

    function voteCounting(uint256 seqOfMotion)
        external onlyDK
    {
        

        IRegisterOfDirectors _rod = _gk.getROD();
        IMeetingMinutes _bmm = _gk.getBMM();
        
        MotionsRepo.Motion memory motion = 
            _bmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _bmm.getCaseOfAttitude(seqOfMotion, 0);
        BallotsBox.Case memory case3 = _bmm.getCaseOfAttitude(seqOfMotion, 3);

        uint32 numOfDirectors = uint32(_rod.getNumOfDirectors());
        base.attendHeadRatio = uint16(case0.sumOfHead * 10000 / numOfDirectors);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = case0.sumOfHead - case3.sumOfHead;
        } else {
            base.totalHead = numOfDirectors - case3.sumOfHead;
            if (motion.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead - case0.sumOfHead);

                base.attendHeadRatio = 10000;                
            }

            if (motion.head.typeOfMotion == 
                uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
            {
                uint256[] memory parties = 
                    ISigPage((address(uint160(motion.contents)))).getParties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint32 voteHead = 
                        uint32(_rod.getBoardSeatsOccupied(uint40(parties[len - 1])));

                    if (voteHead > 0) {
                        if (motion.votingRule.partyAsConsent) {
                            if (!motion.votingRule.impliedConsent) {
                                base.supportHead += voteHead;

                                base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                            }
                        } else {
                            base.totalHead -= voteHead;
                            if (motion.votingRule.impliedConsent) {
                                base.supportHead -= voteHead;
                            } else {
                                base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                            }

                            if (base.totalHead == 0)
                                base.unaniConsent = true;
                        }
                    }

                    len--;
                }                
            }
        }

        IShareholdersAgreement _sha = _gk.getSHA();

        bool quorumFlag = (address(_sha) == address(0) || 
            base.attendHeadRatio >= 
            _sha.getRule(0).governanceRuleParser().quorumOfBoardMeeting);

        _bmm.voteCounting(quorumFlag, seqOfMotion, base);
    }

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external onlyDK {
        _gk.getBMM().transferFund(
            to,
            isCBP,
            amt,
            expireDate,
            seqOfMotion,
            caller
        );
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns (uint) {
        return _gk.getBMM().execAction(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            caller
        );
    }
}
