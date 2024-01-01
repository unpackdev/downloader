// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./RulesParser.sol";

library FilesRepo {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum StateOfFile {
        ZeroPoint,  // 0
        Created,    // 1
        Circulated, // 2
        Proposed,   // 3
        Approved,   // 4
        Rejected,   // 5
        Closed,     // 6
        Revoked     // 7
    }

    struct Head {
        uint48 circulateDate;
        uint8 signingDays;
        uint8 closingDays;
        uint16 seqOfVR;
        uint8 frExecDays;
        uint8 dtExecDays;
        uint8 dtConfirmDays;
        uint48 proposeDate;
        uint8 invExitDays;
        uint8 votePrepareDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint64 seqOfMotion;
        uint8 state;
    }

    struct Ref {
        bytes32 docUrl;
        bytes32 docHash;
    }

    struct File {
        bytes32 snOfDoc;
        Head head;
        Ref ref;
    }

    struct Repo {
        mapping(address => File) files;
        EnumerableSet.AddressSet filesList;
    }

    //####################
    //##    modifier    ##
    //####################

    modifier onlyRegistered(Repo storage repo, address body) {
        require(repo.filesList.contains(body),
            "FR.md.OR: doc NOT registered");
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function regFile(Repo storage repo, bytes32 snOfDoc, address body) 
        public returns (bool flag)
    {
        if (repo.filesList.add(body)) {

            File storage file = repo.files[body];
            
            file.snOfDoc = snOfDoc;
            file.head.state = uint8(StateOfFile.Created);
            flag = true;
        }
    }

    function circulateFile(
        Repo storage repo,
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyRegistered(repo, body) returns (Head memory head){

        require(
            repo.files[body].head.state == uint8(StateOfFile.Created),
            "FR.CF: Doc not pending"
        );

        head = Head({
            circulateDate: uint48(block.timestamp),
            signingDays: uint8(signingDays),
            closingDays: uint8(closingDays),
            seqOfVR: vr.seqOfRule,
            frExecDays: vr.frExecDays,
            dtExecDays: vr.dtExecDays,
            dtConfirmDays: vr.dtConfirmDays,
            proposeDate: 0,
            invExitDays: vr.invExitDays,
            votePrepareDays: vr.votePrepareDays,
            votingDays: vr.votingDays,
            execDaysForPutOpt: vr.execDaysForPutOpt,
            seqOfMotion: 0,
            state: uint8(StateOfFile.Circulated)
        });

        require(head.signingDays > 0, "FR.CF: zero signingDays");

        require(head.closingDays >= signingDays + vr.frExecDays + vr.dtExecDays + vr.dtConfirmDays + 
                vr.invExitDays + vr.votePrepareDays + vr.votingDays,
            "FR.CF: insufficient closingDays");

        File storage file = repo.files[body];

        file.head = head;

        if (docUrl != bytes32(0) || docHash != bytes32(0)){
            file.ref = Ref({
                docUrl: docUrl,
                docHash: docHash
            });   
        }
        return file.head;
    }

    function proposeFile(
        Repo storage repo,
        address body,
        uint64 seqOfMotion
    ) public onlyRegistered(repo, body) returns(Head memory){

        require(repo.files[body].head.state == uint8(StateOfFile.Circulated),
            "FR.PF: Doc not circulated");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp >= dtExecDeadline(repo, body), 
            "FR.proposeFile: still in dtExecPeriod");

        File storage file = repo.files[body];

        require(timestamp < terminateStartpoint(repo, body) || (file.head.frExecDays
             + file.head.dtExecDays + file.head.dtConfirmDays) == 0, 
            "FR.proposeFile: missed proposeDeadline");

        file.head.proposeDate = timestamp;
        file.head.seqOfMotion = seqOfMotion;
        file.head.state = uint8(StateOfFile.Proposed);

        return file.head;
    }

    function voteCountingForFile(
        Repo storage repo,
        address body,
        bool approved
    ) public onlyRegistered(repo, body) {

        require(repo.files[body].head.state == uint8(StateOfFile.Proposed),
            "FR.VCFF: Doc not proposed");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp >= votingDeadline(repo, body), 
            "FR.voteCounting: still in votingPeriod");

        File storage file = repo.files[body];

        file.head.state = approved ? 
            uint8(StateOfFile.Approved) : uint8(StateOfFile.Rejected);
    }

    function execFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        File storage file = repo.files[body];

        require(file.head.state == uint8(StateOfFile.Approved),
            "FR.EF: Doc not approved");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp < closingDeadline(repo, body), 
            "FR.EF: missed closingDeadline");

        file.head.state = uint8(StateOfFile.Closed);
    }

    function terminateFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        File storage file = repo.files[body];

        require(file.head.state != uint8(StateOfFile.Closed),
            "FR.terminateFile: Doc is closed");

        file.head.state = uint8(StateOfFile.Revoked);
    }

    function setStateOfFile(Repo storage repo, address body, uint state) 
        public onlyRegistered(repo, body)
    {
        repo.files[body].head.state = uint8(state);
    }

    //##################
    //##   read I/O   ##
    //##################

    function signingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays) * 86400;
    }

    function closingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.closingDays) * 86400;
    }

    function frExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays + 
            file.head.frExecDays) * 86400;
    }

    function dtExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays + 
            file.head.frExecDays + file.head.dtExecDays) * 86400;
    }

    function terminateStartpoint(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + (uint48(file.head.signingDays + 
            file.head.frExecDays + file.head.dtExecDays + file.head.dtConfirmDays)) * 86400;
    }

    function votingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.proposeDate + (uint48(file.head.invExitDays + 
            file.head.votePrepareDays + file.head.votingDays)) * 86400;
    }    

    function isRegistered(Repo storage repo, address body) public view returns (bool) {
        return repo.filesList.contains(body);
    }

    function qtyOfFiles(Repo storage repo) public view returns (uint256) {
        return repo.filesList.length();
    }

    function getFilesList(Repo storage repo) public view returns (address[] memory) {
        return repo.filesList.values();
    }

    function getFile(Repo storage repo, address body) public view returns (File memory) {
        return repo.files[body];
    }

    function getHeadOfFile(Repo storage repo, address body)
        public view onlyRegistered(repo, body) returns (Head memory)
    {
        return repo.files[body].head;
    }

}
