// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

import "./IMeetingMinutes.sol";

contract MeetingMinutes is IMeetingMinutes, AccessControl {
    using MotionsRepo for MotionsRepo.Repo;
    using RulesParser for bytes32;

    MotionsRepo.Repo private _repo;

    //##################
    //##    Write     ##
    //##################

    function _addMotion(
        uint typeOfMotion,
        uint seqOfVR,
        uint creator,
        uint executor,
        uint contents
    ) private returns (uint64) {
        MotionsRepo.Head memory head = MotionsRepo.Head({
            typeOfMotion: uint8(typeOfMotion),
            seqOfMotion: 0,
            seqOfVR: uint16(seqOfVR),
            creator: uint40(creator),
            executor: uint40(executor),
            createDate: 0,
            data: 0
        });

        head = _repo.addMotion(head, contents);
        emit CreateMotion(MotionsRepo.codifyHead(head), contents);
        return head.seqOfMotion;
    }

    function nominateOfficer(
        uint seqOfPos,
        uint seqOfVR,
        uint candidate,
        uint nominator    
    ) external onlyDK returns(uint64) {

        return _addMotion(
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer),
            seqOfVR,
            nominator,
            candidate, 
            seqOfPos
        );
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint nominator    
    ) external onlyDK returns(uint64) {

        return _addMotion(
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer),
            seqOfVR,
            nominator,
            nominator,
            seqOfPos
        );
    }

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer    
    ) external onlyKeeper returns(uint64) {

        return _addMotion(
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc),
            seqOfVR,
            proposer,
            executor,
            doc
        );
    }

    function createMotionToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK returns (uint64) {
        uint contents = _hashPayment(address(0), false, amt, expireDate);
        return _addMotion(
            uint8(MotionsRepo.TypeOfMotion.DistributeProfits),
            seqOfVR,
            proposer,
            executor,
            contents
        );
    }

    function createMotionToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external onlyDK returns (uint64) {
        uint contents = _hashPayment(to, isCBP, amt, expireDate);
        return _addMotion(
            uint8(MotionsRepo.TypeOfMotion.TransferFund),
            seqOfVR,
            proposer,
            executor,
            contents
        );
    }

    function _hashPayment(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate
    ) private pure returns(uint) {
        return 
            uint256(
                keccak256(
                    abi.encode(to, isCBP, amt, expireDate)
                )
            );
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external onlyDK returns (uint64){

        uint256 contents = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        return _addMotion(
            uint8(MotionsRepo.TypeOfMotion.ApproveAction),
            seqOfVR,
            proposer,
            executor,
            contents
        );
    }

    function _hashAction(
        uint256 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(seqOfVR, targets, values, params, desHash)
                )
            );
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint proposer
    ) external onlyDK {
        
        IShareholdersAgreement _sha = _gk.getSHA();

        _repo.proposeMotionToGeneralMeeting(seqOfMotion, _sha, _gk.getROM(), _gk.getROD(), proposer);
        emit ProposeMotionToGeneralMeeting(seqOfMotion, proposer);
    }

    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external onlyDK {
        
        IShareholdersAgreement _sha = _gk.getSHA();

        _repo.proposeMotionToBoard(seqOfMotion, _sha, _gk.getROD(), caller);
        emit ProposeMotionToBoard(seqOfMotion, caller);
    }

    // ==== delegate ====

    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate, 
        uint principal
    ) external onlyDK {
        

        _repo.entrustDelegate(seqOfMotion, delegate, principal, _gk.getROM(), _gk.getROD());
        emit EntrustDelegate(seqOfMotion, delegate, principal);
    }

    // ==== Vote ====

    function castVoteInGeneralMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK {
        _repo.castVoteInGeneralMeeting(seqOfMotion, caller, attitude, sigHash, _gk.getROM());
        emit CastVoteInGeneralMeeting(seqOfMotion, caller, attitude, sigHash);
    }

    function castVoteInBoardMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDK {
        _repo.castVoteInBoardMeeting(seqOfMotion, caller, attitude, sigHash, _gk.getROD());
        emit CastVoteInBoardMeeting(seqOfMotion, caller, attitude, sigHash);
    }

    // ==== UpdateVoteResult ====

    function voteCounting(bool flag0, uint256 seqOfMotion, MotionsRepo.VoteCalBase memory base) 
        external onlyDK returns(uint8 result)
    {            
        result = _repo.voteCounting(flag0, seqOfMotion, base);
        emit VoteCounting(seqOfMotion, result);            
    }

    // ==== ExecResolution ====

    function execResolution(uint256 seqOfMotion, uint256 contents, uint caller)
        public onlyKeeper 
    {
        _repo.execResolution(seqOfMotion, contents, caller);
        emit ExecResolution(seqOfMotion, caller);
    }

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external onlyDK {

        require(block.timestamp < expireDate, 
            "MM.distrProf: missed deadline");

        require(_repo.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.DistributeProfits), 
            "MM.distrProf: wrong typeOfMotion");
        
        uint contents = _hashPayment(address(0), false, amt, expireDate);

        execResolution(seqOfMotion, contents, caller);
    }


    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external onlyDK {

        require(block.timestamp < expireDate, 
            "MM.TF: missed deadline");

        require(_repo.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.TransferFund), 
            "MM.TF: wrong typeOfMotion");
        
        uint contents = _hashPayment(to, isCBP, amt, expireDate);

        execResolution(seqOfMotion, contents, caller);
    }

    function execAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external onlyDK returns (uint contents) {

        MotionsRepo.Motion memory motion =  
            _repo.getMotion(seqOfMotion);

        require(motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveAction), 
            "MM.EA: wrong typeOfMotion");

        contents = _hashAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash
        );

        execResolution(seqOfMotion, contents, caller);
    }

    //################
    //##    Read    ##
    //################

    // ==== Motions ====

    function isProposed(uint256 seqOfMotion) public view returns (bool) {
        return _repo.isProposed(seqOfMotion);
    }

    function voteStarted(uint256 seqOfMotion) external view returns (bool) {
        return _repo.voteStarted(seqOfMotion);
    }

    function voteEnded(uint256 seqOfMotion) external view returns (bool){
        return _repo.voteEnded(seqOfMotion);
    }

    // ==== Delegate ====

    function getVoterOfDelegateMap(uint256 seqOfMotion, uint256 acct)
        external view returns (DelegateMap.Voter memory)
    {
        return _repo.getVoterOfDelegateMap(seqOfMotion, acct);
    }

    function getDelegateOf(uint256 seqOfMotion, uint acct)
        external view returns (uint)
    {
        return _repo.getDelegateOf(seqOfMotion, acct);
    }

    // ==== motion ====

    function getMotion(uint256 seqOfMotion)
        external view returns (MotionsRepo.Motion memory motion)
    {
        motion = _repo.getMotion(seqOfMotion);
    }

    // ==== voting ====

    function isVoted(uint256 seqOfMotion, uint256 acct) external view returns (bool) 
    {
        return _repo.isVoted(seqOfMotion, acct);
    }

    function isVotedFor(
        uint256 seqOfMotion,
        uint256 acct,
        uint atti
    ) external view returns (bool) {
        return _repo.isVotedFor(seqOfMotion, acct, atti);
    }

    function getCaseOfAttitude(uint256 seqOfMotion, uint atti)
        external view returns (BallotsBox.Case memory )
    {
        return _repo.getCaseOfAttitude(seqOfMotion, atti);
    }

    function getBallot(uint256 seqOfMotion, uint256 acct)
        external view returns (BallotsBox.Ballot memory)
    {
        return _repo.getBallot(seqOfMotion, acct);
    }

    function isPassed(uint256 seqOfMotion) external view returns (bool) {
        return _repo.isPassed(seqOfMotion);
    }

    // ==== SeqList ====

    function getSeqList() external view returns (uint[] memory) {
        return _repo.getSeqList();
    }
    
}
