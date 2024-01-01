// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./BallotsBox.sol";
import "./DelegateMap.sol";
import "./EnumerableSet.sol";
import "./RulesParser.sol";

import "./IShareholdersAgreement.sol";

library MotionsRepo {
    using BallotsBox for BallotsBox.Box;
    using DelegateMap for DelegateMap.Map;
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    enum TypeOfMotion {
        ZeroPoint,
        ElectOfficer,
        RemoveOfficer,
        ApproveDoc,
        ApproveAction,
        TransferFund,
        DistributeProfits
    }

    enum StateOfMotion {
        ZeroPoint,          // 0
        Created,            // 1
        Proposed,           // 2
        Passed,             // 3
        Rejected,           // 4
        Rejected_NotToBuy,  // 5
        Rejected_ToBuy,     // 6
        Executed            // 7
    }

    struct Head {
        uint16 typeOfMotion;
        uint64 seqOfMotion;
        uint16 seqOfVR;
        uint40 creator;
        uint40 executor;
        uint48 createDate;        
        uint32 data;
    }

    struct Body {
        uint40 proposer;
        uint48 proposeDate;
        uint48 shareRegDate;
        uint48 voteStartDate;
        uint48 voteEndDate;
        uint16 para;
        uint8 state;
    }

    struct Motion {
        Head head;
        Body body;
        RulesParser.VotingRule votingRule;
        uint contents;
    }

    struct Record {
        DelegateMap.Map map;
        BallotsBox.Box box;        
    }

    struct VoteCalBase {
        uint32 totalHead;
        uint64 totalWeight;
        uint32 supportHead;
        uint64 supportWeight;
        uint16 attendHeadRatio;
        uint16 attendWeightRatio;
        uint16 para;
        uint8 state;            
        bool unaniConsent;
    }

    struct Repo {
        mapping(uint256 => Motion) motions;
        mapping(uint256 => Record) records;
        EnumerableSet.UintSet seqList;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== snParser ====

    function snParser (bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfMotion: uint16(_sn >> 240),
            seqOfMotion: uint64(_sn >> 176),
            seqOfVR: uint16(_sn >> 160),
            creator: uint40(_sn >> 120),
            executor: uint40(_sn >> 80),
            createDate: uint48(_sn >> 32),
            data: uint32(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfMotion,
                            head.seqOfMotion,
                            head.seqOfVR,
                            head.creator,
                            head.executor,
                            head.createDate,
                            head.data);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    } 
    
    // ==== addMotion ====

    function addMotion(
        Repo storage repo,
        Head memory head,
        uint256 contents
    ) public returns (Head memory) {

        require(head.typeOfMotion > 0, "MR.CM: zero typeOfMotion");
        require(head.seqOfVR > 0, "MR.CM: zero seqOfVR");
        require(head.creator > 0, "MR.CM: zero caller");

        if (!repo.seqList.contains(head.seqOfMotion)) {
            head.seqOfMotion = _increaseCounterOfMotion(repo);
            head.createDate = uint48(block.timestamp);
            repo.seqList.add(head.seqOfMotion);
        }
    
        Motion storage m = repo.motions[head.seqOfMotion];

        m.head = head;
        m.contents = contents;
        m.body.state = uint8(StateOfMotion.Created);

        return head;
    } 

    function _increaseCounterOfMotion (Repo storage repo) private returns (uint64 seq) {
        repo.motions[0].head.seqOfMotion++;
        seq = repo.motions[0].head.seqOfMotion;
    }

    // ==== entrustDelegate ====

    function entrustDelegate(
        Repo storage repo,
        uint256 seqOfMotion,
        uint delegate,
        uint principal,
        IRegisterOfMembers _rom,
        IRegisterOfDirectors _rod
    ) public returns (bool flag) {
        Motion storage m = repo.motions[seqOfMotion];

        require(m.body.state == uint8(StateOfMotion.Created) ||
            m.body.state == uint8(StateOfMotion.Proposed) , 
            "MR.EntrustDelegate: wrong state");

        if (_rom.isMember(delegate) && _rom.isMember(principal)) {
            uint64 weight;
            if (m.body.shareRegDate > 0 && block.timestamp >= m.body.shareRegDate) 
                weight = _rom.votesAtDate(principal, m.body.shareRegDate);    
            return repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, weight);
        } else if (_rod.isDirector(delegate) && _rod.isDirector(principal)) {
            return repo.records[seqOfMotion].map.entrustDelegate(principal, delegate, 0);
        } else revert ("MR.entrustDelegate: not both Members or Directors");        
    }

    // ==== propose ====

    function proposeMotionToGeneralMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        IShareholdersAgreement _sha,
        IRegisterOfMembers _rom,
        IRegisterOfDirectors _rod,
        uint caller
    ) public {

        RulesParser.GovernanceRule memory gr =
            _sha.getRule(0).governanceRuleParser();

        require(_memberProposalRightCheck(repo, seqOfMotion, gr, caller, _rom) ||
            _directorProposalRightCheck(repo, seqOfMotion, caller, gr.proposeHeadRatioOfDirectorsInGM, _rod),
            "MR.PMTGM: has no proposalRight");

        _proposeMotion(repo, seqOfMotion, _sha, caller);
    } 

    function _proposeMotion(
        Repo storage repo,
        uint seqOfMotion,
        IShareholdersAgreement _sha,
        uint caller
    ) private {

        require(caller > 0, "MR.PM: zero caller");

        require(repo.records[seqOfMotion].map.voters[caller].delegate == 0,
            "MR.PM: entrused delegate");

        Motion storage m = repo.motions[seqOfMotion];
        require(m.body.state == uint8(StateOfMotion.Created), 
            "MR.PM: wrong state");

        RulesParser.VotingRule memory vr = 
            _sha.getRule(m.head.seqOfVR).votingRuleParser();

        uint48 timestamp = uint48(block.timestamp);

        Body memory body = Body({
            proposer: uint40(caller),
            proposeDate: timestamp,
            shareRegDate: timestamp + uint48(vr.invExitDays) * 86400,
            voteStartDate: timestamp + uint48(vr.invExitDays + vr.votePrepareDays) * 86400,
            voteEndDate: timestamp + uint48(vr.invExitDays + vr.votePrepareDays + vr.votingDays) * 86400,
            para: 0,
            state: uint8(StateOfMotion.Proposed)
        });

        m.body = body;
        m.votingRule = vr;
    }

    function _memberProposalRightCheck(
        Repo storage repo,
        uint seqOfMotion,
        RulesParser.GovernanceRule memory gr,
        uint caller,
        IRegisterOfMembers _rom
    ) private returns(bool) {
        if (!_rom.isMember(caller)) return false;

        Motion memory motion = repo.motions[seqOfMotion];
        if (motion.head.typeOfMotion == uint8(TypeOfMotion.ApproveDoc) ||
            motion.head.typeOfMotion == uint8(TypeOfMotion.ElectOfficer))
            return true;

        uint totalVotes = _rom.totalVotes();

        if (gr.proposeWeightRatioOfGM > 0 &&
            _rom.votesInHand(caller) * 10000 / totalVotes >= gr.proposeWeightRatioOfGM)
                return true;

        Record storage r = repo.records[seqOfMotion];
        r.map.updateLeavesWeightAtDate(caller, uint48(block.timestamp), _rom);

        DelegateMap.Voter memory voter = r.map.voters[caller];


        if (gr.proposeWeightRatioOfGM > 0 && 
            (voter.weight + voter.repWeight) * 10000 / totalVotes >= gr.proposeWeightRatioOfGM)
                return true;

        if (gr.proposeHeadRatioOfMembers > 0 &&
            (voter.repHead + 1) * 10000 / _rom.qtyOfMembers() >= 
                gr.proposeHeadRatioOfMembers)
                    return true;
        
        return false;
    }

    function _directorProposalRightCheck(
        Repo storage repo,
        uint seqOfMotion,
        uint caller,
        uint16 proposalThreshold,
        IRegisterOfDirectors _rod
    ) private returns (bool) {
        if (!_rod.isDirector(caller)) return false;

        uint totalHead = _rod.getNumOfDirectors();
        repo.records[seqOfMotion].map.updateLeavesHeadcountOfDirectors(caller, _rod);

        if (proposalThreshold > 0 &&
            (repo.records[seqOfMotion].map.voters[caller].repHead + 1) * 10000 / totalHead >=
                proposalThreshold)
                    return true;

        return false;
    } 

    function proposeMotionToBoard(
        Repo storage repo,
        uint256 seqOfMotion,
        IShareholdersAgreement _sha,
        IRegisterOfDirectors _rod,
        uint caller
    ) public {

        RulesParser.GovernanceRule memory gr = 
            _sha.getRule(0).governanceRuleParser();

        require(
            _directorProposalRightCheck(
                repo, seqOfMotion, caller, 
                gr.proposeHeadRatioOfDirectorsInBoard, 
                _rod
            ),
            "MR.PMTB: has no proposalRight");

        _proposeMotion(repo, seqOfMotion, _sha, caller);
    } 

    // ==== vote ====

    function castVoteInGeneralMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfMembers _rom
    ) public {

        require(_rom.isMember(acct), "MR.castVoteInGM: not Member");

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        r.map.updateLeavesWeightAtDate(acct, m.body.shareRegDate, _rom);

        _castVote(repo, seqOfMotion, acct, attitude, voter.repHead + 1, voter.weight + voter.repWeight, sigHash);
    }

    function castVoteInBoardMeeting(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        bytes32 sigHash,
        IRegisterOfDirectors _rod
    ) public {
        require(_rod.isDirector(acct), "MR.CVBM: not Director");

        Record storage r = repo.records[seqOfMotion];

        DelegateMap.Voter storage voter = r.map.voters[acct];

        r.map.updateLeavesHeadcountOfDirectors(acct, _rod);

        _castVote(repo, seqOfMotion, acct, attitude, voter.repHead + 1, 0, sigHash);
    }

    function _castVote(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint attitude,
        uint headcount,
        uint weight,
        bytes32 sigHash
    ) private {
        require(seqOfMotion > 0, "MR.CV: zero seqOfMotion");
        require(voteStarted(repo, seqOfMotion), "MR.CV: vote not started");
        require(!voteEnded(repo, seqOfMotion), "MR.CV: vote is Ended");

        Record storage r = repo.records[seqOfMotion];
        DelegateMap.Voter storage voter = r.map.voters[acct];

        require(voter.delegate == 0, 
            "MR.CV: entrusted delegate");

        r.box.castVote(acct, attitude, headcount, weight, sigHash, voter.principals);
    }


    // ==== counting ====

    function voteCounting(
        Repo storage repo,
        bool flag0,
        uint256 seqOfMotion,
        VoteCalBase memory base
    ) public returns (uint8) {

        Motion storage m = repo.motions[seqOfMotion];
        Record storage r = repo.records[seqOfMotion];

        require (m.body.state == uint8(StateOfMotion.Proposed) , "MR.VT: wrong state");
        require (voteEnded(repo, seqOfMotion), "MR.VT: vote not ended yet");

        bool flag1 = m.votingRule.headRatio == 0;
        bool flag2 = m.votingRule.amountRatio == 0;

        bool flag = (flag1 && flag2);

        if (!flag && flag0 && !_isVetoed(r, m.votingRule.vetoers[0]) &&
            !_isVetoed(r, m.votingRule.vetoers[1])) {
            flag1 = flag1 ? true : base.totalHead > 0
                ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                    .sumOfHead + base.supportHead) * 10000) /
                    base.totalHead >
                    m.votingRule.headRatio
                : base.unaniConsent 
                    ? true
                    : false;

            flag2 = flag2 ? true : base.totalWeight > 0
                ? ((r.box.cases[uint8(BallotsBox.AttitudeOfVote.Support)]
                    .sumOfWeight + base.supportWeight) * 10000) /
                    base.totalWeight >
                    m.votingRule.amountRatio
                : base.unaniConsent
                    ? true
                    : false;
        }

        m.body.state =  flag || (flag0 && flag1 && flag2) 
                ? uint8(MotionsRepo.StateOfMotion.Passed) 
                : m.votingRule.againstShallBuy 
                    ? uint8(MotionsRepo.StateOfMotion.Rejected_ToBuy)
                    : uint8(MotionsRepo.StateOfMotion.Rejected_NotToBuy);

        return m.body.state;
    }

    function _isVetoed(Record storage r, uint256 vetoer)
        private
        view
        returns (bool)
    {
        return vetoer > 0 && (r.box.ballots[vetoer].sigDate == 0 ||
            r.box.ballots[vetoer].attitude != uint8(BallotsBox.AttitudeOfVote.Support));
    }

    // ==== ExecResolution ====

    function execResolution(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 contents,
        uint executor
    ) public {
        Motion storage m = repo.motions[seqOfMotion];
        require (m.contents == contents, 
            "MR.execResolution: wrong contents");
        require (m.body.state == uint8(StateOfMotion.Passed), 
            "MR.execResolution: wrong state");
        require (m.head.executor == uint40(executor), "MR.ER: not executor");

        m.body.state = uint8(StateOfMotion.Executed);
    }
    
    //#################
    //##    Read     ##
    //#################

    // ==== VoteState ====

    function isProposed(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return repo.motions[seqOfMotion].body.state == uint8(StateOfMotion.Proposed);
    }

    function voteStarted(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteStartDate <= block.timestamp;
    }

    function voteEnded(Repo storage repo, uint256 seqOfMotion)
        public view returns (bool)
    {
        return isProposed(repo, seqOfMotion) && 
            repo.motions[seqOfMotion].body.voteEndDate <= block.timestamp;
    }

    // ==== Delegate ====

    function getVoterOfDelegateMap(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (DelegateMap.Voter memory)
    {
        return repo.records[seqOfMotion].map.voters[acct];
    }

    function getDelegateOf(Repo storage repo, uint256 seqOfMotion, uint acct)
        public view returns (uint)
    {
        return repo.records[seqOfMotion].map.getDelegateOf(acct);
    }

    // function getLeavesWeightAtDate(
    //     Repo storage repo, 
    //     uint256 seqOfMotion, 
    //     uint acct,
    //     uint baseDate, 
    //     IRegisterOfMembers _rom
    // ) public view returns(uint64 weight)
    // {
    //     repo.records[seqOfMotion].map.updateLeavesWeightAtDate(acct, baseDate, _rom);

    //     DelegateMap.Voter storage voter = repo.records[seqOfMotion].map.voters[acct];

    //     weight = voter.weight + voter.repWeight;
    // }

    // function getLeavesHeadcountOfDirectors(
    //     Repo storage repo, 
    //     uint256 seqOfMotion, 
    //     uint acct,
    //     IRegisterOfDirectors _rod
    // ) public view returns(uint32 head)
    // {
    //     repo.records[seqOfMotion].map.updateLeavesHeadcountOfDirectors(acct, _rod);

    //     DelegateMap.Voter storage voter = repo.records[seqOfMotion].map.voters[acct];

    //     head = voter.repHead + 1;
    // }


    // ==== motion ====

    function getMotion(Repo storage repo, uint256 seqOfMotion)
        public view returns (Motion memory motion)
    {
        motion = repo.motions[seqOfMotion];
    }

    // ==== voting ====

    function isVoted(Repo storage repo, uint256 seqOfMotion, uint256 acct) 
        public view returns (bool) 
    {
        return repo.records[seqOfMotion].box.isVoted(acct);
    }

    function isVotedFor(
        Repo storage repo,
        uint256 seqOfMotion,
        uint256 acct,
        uint256 atti
    ) public view returns (bool) {
        return repo.records[seqOfMotion].box.isVotedFor(acct, atti);
    }

    function getCaseOfAttitude(Repo storage repo, uint256 seqOfMotion, uint256 atti)
        public view returns (BallotsBox.Case memory )
    {
        return repo.records[seqOfMotion].box.getCaseOfAttitude(atti);
    }

    function getBallot(Repo storage repo, uint256 seqOfMotion, uint256 acct)
        public view returns (BallotsBox.Ballot memory)
    {
        return repo.records[seqOfMotion].box.getBallot(acct);
    }

    function isPassed(Repo storage repo, uint256 seqOfMotion) public view returns (bool) {
        return repo.motions[seqOfMotion].body.state == uint8(MotionsRepo.StateOfMotion.Passed);
    }

    // ==== snList ====

    function getSeqList(Repo storage repo) public view returns (uint[] memory) {
        return repo.seqList.values();
    }

}
