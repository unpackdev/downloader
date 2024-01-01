// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IGMMKeeper.sol";

import "./AccessControl.sol";

contract GMMKeeper is IGMMKeeper, AccessControl {
    using RulesParser for bytes32;

    modifier memberExist(uint256 acct) {
        require(_gk.getROM().isMember(acct), 
            "BOGK.mf: NOT Member");
        _;
    }

    modifier memberOrDirector(uint256 acct) {
        

        require(_gk.getROM().isMember(acct) ||
            _gk.getROD().isDirector(acct), 
            "BOGK.mf: not Member or Director");
        _;
    }

    // ################
    // ##   Motion   ##
    // ################

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external onlyDK {
        
        IRegisterOfDirectors _rod = _gk.getROD();

        require(_rod.hasNominationRight(seqOfPos, nominator),
            "RODKeeper.nominateOfficer: has no nominationRight");

        _gk.getGMM().nominateOfficer(
            seqOfPos, 
            _rod.getPosition(seqOfPos).seqOfVR, 
            candidate, 
            nominator
        );
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos,
        uint caller
    ) external onlyDK {
        

        IRegisterOfDirectors _rod = _gk.getROD();

        require(_rod.hasNominationRight(seqOfPos, caller),
            "RODKeeper.nominateOfficer: has no nominationRight");

        _gk.getGMM().createMotionToRemoveOfficer(
            seqOfPos, 
            _rod.getPosition(seqOfPos).seqOfVR, 
            caller
        );
    }

    function proposeDocOfGM(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK memberExist(proposer) {
        
        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToApproveDoc(doc, seqOfVR, executor, proposer);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, proposer);            

        if (seqOfVR < 9) {

            address addr = address(uint160(doc));

            require(ISigPage(addr).isSigner(proposer), 
                "GMMK.proposeDoc: not signer");

            require(ISigPage(addr).established(),
                "GMMK.proposeDoc: not established");

            if (seqOfVR == 8) {
                _gk.getROC().proposeFile(addr, seqOfMotion);
            } else {
                require(_gk.getROA().allClaimsAccepted(addr),
                    "GMMK.proposeDoc: Claims outstanding");
                _gk.getROA().proposeFile(addr, seqOfMotion);
            }
        }
    }

    function proposeToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external memberOrDirector(proposer){

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToDistributeProfits(amt, expireDate, seqOfVR, executor, proposer);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, proposer);
    }

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external memberOrDirector(proposer){

        
        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToTransferFund(to, isCBP, amt, expireDate, seqOfVR, executor, proposer);

        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, proposer);            
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDK memberOrDirector(proposer) {
        _gk.getGMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            proposer
        );
    }

    // ==== ProposeMotion ====

    function entrustDelegaterForGeneralMeeting(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external onlyDK {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getGMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint caller
    ) external onlyKeeper {
        _gk.getGMM().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK {
        _avoidanceCheck(seqOfMotion, caller);
        _gk.getGMM().castVoteInGeneralMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint256 caller) private view {
        MotionsRepo.Motion memory motion = _gk.getGMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            address doc = address(uint160(motion.contents));
            require (!ISigPage(doc).isSigner(caller),
                "BOGK.AC: is related party");
        }
    }

    // ==== VoteCounting ====

    function voteCountingOfGM(uint256 seqOfMotion) external onlyDK {
        
        IRegisterOfMembers _rom = _gk.getROM();
        IMeetingMinutes _gmm = _gk.getGMM();

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _gmm.getCaseOfAttitude(seqOfMotion, 0);
        BallotsBox.Case memory case3 = _gmm.getCaseOfAttitude(seqOfMotion, 3);

        uint64 votesOfMembers = _rom.totalVotes();

        base.attendWeightRatio = uint16(case0.sumOfWeight * 10000 / votesOfMembers);

        if (motion.votingRule.onlyAttendance) {

            base.totalHead = (case0.sumOfHead - case3.sumOfHead);
            base.totalWeight = (case0.sumOfWeight - case3.sumOfWeight);

        } else {

            base.totalHead = uint32(_rom.qtyOfMembers());
            base.totalWeight = votesOfMembers; 

            if (motion.votingRule.impliedConsent) {

                base.supportHead = base.totalHead - case0.sumOfHead;                
                base.supportWeight = base.totalWeight > case0.sumOfWeight
                        ? (base.totalWeight - case0.sumOfWeight)
                        : 0;
                base.attendWeightRatio = 10000;
            }

            base.totalHead -= case3.sumOfHead;
            base.totalWeight = base.totalWeight > case3.sumOfWeight
                    ? base.totalWeight - case3.sumOfWeight
                    : 0 ;
            if (motion.head.typeOfMotion == 
                    uint8(MotionsRepo.TypeOfMotion.ApproveDoc))
            {
                uint256[] memory parties = 
                    ISigPage(address(uint160(motion.contents))).getParties();
                uint256 len = parties.length;

                while (len > 0) {
                    uint64 votesAtDate = 
                        _rom.votesAtDate(parties[len - 1], motion.body.shareRegDate);

                    if (votesAtDate > 0) {
                        if (motion.votingRule.partyAsConsent) {
                            if (!motion.votingRule.impliedConsent) {
                                base.supportHead ++;
                                base.supportWeight += votesAtDate;

                                base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                            }
                        } else {
                            base.totalHead --;

                            base.totalWeight = base.totalWeight > votesAtDate
                                    ? base.totalWeight - votesAtDate
                                    : 0;

                            if (motion.votingRule.impliedConsent) {
                                base.supportHead --;

                                base.supportWeight = base.supportWeight > votesAtDate
                                        ? base.supportWeight - votesAtDate
                                        : 0;
                            } else {
                                base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                            }

                            if (base.totalHead == 0)
                                base.unaniConsent = true;
                        }
                    }

                    len--;
                }                
            }
        }

        bool quorumFlag = (address(_gk.getSHA()) == address(0)|| 
            base.attendWeightRatio >= 
            _gk.getSHA().getRule(0).governanceRuleParser().quorumOfGM);

        bool approved = _gmm.voteCounting(quorumFlag, seqOfMotion, base) == 
            uint8(MotionsRepo.StateOfMotion.Passed);

        if (motion.head.seqOfVR < 9) {

            address doc = address(uint160(motion.contents));

            if (motion.head.seqOfVR == 8)
                _gk.getROC().voteCountingForFile(doc, approved);
            else _gk.getROA().voteCountingForFile(doc, approved);
        }
    }

    // ==== execute ====

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external onlyDK {

        IRegisterOfMembers _rom = _gk.getROM();

        _gk.getGMM().distributeProfits(
            amt,
            expireDate,
            seqOfMotion,
            caller
        );

        uint[] memory members = _rom.membersList();
        uint len = members.length;

        uint totalEquity = _rom.basedOnPar()
            ? _rom.ownersEquity().par
            : _rom.ownersEquity().paid ;

        while (len > 0) {
            uint member = members[len - 1];
            uint equityOfMember = _rom.basedOnPar()
                ? _rom.equityOfMember(member).par
                : _rom.equityOfMember(member).paid;

            _gk.saveToCoffer(member, equityOfMember * amt / totalEquity);

            len--;
        }
    }

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external onlyDK {
        _gk.getGMM().transferFund(
            to,
            isCBP,
            amt,
            expireDate,
            seqOfMotion,
            caller
        );
    }

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns (uint){
        return _gk.getGMM().execAction(
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
