// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "SafeMath.sol";
import { IERC20 } from  "IERC20.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";
import { ICandidate } from "ICandidate.sol";
import { LibAgenda } from "LibAgenda.sol";
import "Ownable.sol";

contract DAOAgendaManager is Ownable, IDAOAgendaManager {
    using SafeMath for uint256;
    using LibAgenda for *;

    enum VoteChoice { ABSTAIN, YES, NO, MAX }

    IDAOCommittee public override committee;
    
    uint256 public override createAgendaFees; // 아젠다생성비용(TON)
    
    uint256 public override minimumNoticePeriodSeconds;
    uint256 public override minimumVotingPeriodSeconds;
    uint256 public override executingPeriodSeconds;
    
    LibAgenda.Agenda[] internal _agendas;
    mapping(uint256 => mapping(address => LibAgenda.Voter)) internal _voterInfos;
    mapping(uint256 => LibAgenda.AgendaExecutionInfo) internal _executionInfos;
    
    event AgendaStatusChanged(
        uint256 indexed agendaID,
        uint256 prevStatus,
        uint256 newStatus
    );

    event AgendaResultChanged(
        uint256 indexed agendaID,
        uint256 result
    );

    event CreatingAgendaFeeChanged(
        uint256 newFee
    );

    event MinimumNoticePeriodChanged(
        uint256 newPeriod
    );

    event MinimumVotingPeriodChanged(
        uint256 newPeriod
    );

    event ExecutingPeriodChanged(
        uint256 newPeriod
    );

    modifier validAgenda(uint256 _agendaID) {
        require(_agendaID < _agendas.length, "DAOAgendaManager: invalid agenda id");
        _;
    }
    
    constructor() {
        /*minimumNoticePeriodSeconds = 16 days;
        minimumVotingPeriodSeconds = 2 days;
        executingPeriodSeconds = 7 days;*/
        minimumNoticePeriodSeconds = 300;
        minimumVotingPeriodSeconds = 300;
        executingPeriodSeconds = 300;
        
        createAgendaFees = 100000000000000000000; // 100 TON
    }

    function getStatus(uint256 _status) public pure override returns (LibAgenda.AgendaStatus emnustatus) {
        require(_status < 6, "DAOAgendaManager: invalid status value");
        if (_status == uint256(LibAgenda.AgendaStatus.NOTICE))
            return LibAgenda.AgendaStatus.NOTICE;
        else if (_status == uint256(LibAgenda.AgendaStatus.VOTING))
            return LibAgenda.AgendaStatus.VOTING;
        else if (_status == uint256(LibAgenda.AgendaStatus.EXECUTED))
            return LibAgenda.AgendaStatus.EXECUTED;
        else if (_status == uint256(LibAgenda.AgendaStatus.ENDED))
            return LibAgenda.AgendaStatus.ENDED;
        else
            return LibAgenda.AgendaStatus.NONE;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @param _committee New DAOCommitteeProxy contract address
    function setCommittee(address _committee) external override onlyOwner {
        require(_committee != address(0), "DAOAgendaManager: address is zero");
        committee = IDAOCommittee(_committee);
    }

    /// @notice Set status of the agenda
    /// @param _agendaID agenda ID
    /// @param _status New status of the agenda
    /*function setStatus(uint256 _agendaID, uint256 _status) public override onlyOwner {
        require(_agendaID < _agendas.length, "DAOAgendaManager: Not a valid Proposal Id");

        emit AgendaStatusChanged(_agendaID, uint256(_agendas[_agendaID].status), _status);
        _agendas[_agendaID].status = getStatus(_status);
    }*/

    /// @notice Set the fee(TON) of creating an agenda
    /// @param _createAgendaFees New fee(TON)
    function setCreateAgendaFees(uint256 _createAgendaFees) external override onlyOwner {
        createAgendaFees = _createAgendaFees;
        emit CreatingAgendaFeeChanged(_createAgendaFees);
    }

    /// @notice Set the minimum notice period in seconds
    /// @param _minimumNoticePeriodSeconds New minimum notice period in seconds
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external override onlyOwner {
        minimumNoticePeriodSeconds = _minimumNoticePeriodSeconds;
        emit MinimumNoticePeriodChanged(_minimumNoticePeriodSeconds);
    }

    /// @notice Set the executing period in seconds
    /// @param _executingPeriodSeconds New executing period in seconds
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external override onlyOwner {
        executingPeriodSeconds = _executingPeriodSeconds;
        emit ExecutingPeriodChanged(_executingPeriodSeconds);
    }

    /// @notice Set the minimum voting period in seconds
    /// @param _minimumVotingPeriodSeconds New minimum voting period in seconds
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external override onlyOwner {
        minimumVotingPeriodSeconds = _minimumVotingPeriodSeconds;
        emit MinimumVotingPeriodChanged(_minimumVotingPeriodSeconds);
    }
      
    /// @notice Creates an agenda
    /// @param _targets Target addresses for executions of the agenda
    /// @param _noticePeriodSeconds Notice period in seconds
    /// @param _votingPeriodSeconds Voting period in seconds
    /// @param _functionBytecodes RLP-Encoded parameters for executions of the agenda
    /// @return agendaID Created agenda ID
    function newAgenda(
        address[] calldata _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        override
        onlyOwner
        returns (uint256 agendaID)
    {
        require(
            _noticePeriodSeconds >= minimumNoticePeriodSeconds,
            "DAOAgendaManager: minimumNoticePeriod is short"
        );

        agendaID = _agendas.length;
         
        address[] memory emptyArray;
        _agendas.push(LibAgenda.Agenda({
            status: LibAgenda.AgendaStatus.NOTICE,
            result: LibAgenda.AgendaResult.PENDING,
            executed: false,
            createdTimestamp: block.timestamp,
            noticeEndTimestamp: block.timestamp + _noticePeriodSeconds,
            votingPeriodInSeconds: _votingPeriodSeconds,
            votingStartedTimestamp: 0,
            votingEndTimestamp: 0,
            executableLimitTimestamp: 0,
            executedTimestamp: 0,
            countingYes: 0,
            countingNo: 0,
            countingAbstain: 0,
            voters: emptyArray
        }));

        LibAgenda.AgendaExecutionInfo storage executionInfo = _executionInfos[agendaID];
        executionInfo.atomicExecute = _atomicExecute;
        executionInfo.executeStartFrom = 0;
        for (uint256 i = 0; i < _targets.length; i++) {
            executionInfo.targets.push(_targets[i]);
            executionInfo.functionBytecodes.push(_functionBytecodes[i]);
        }
    }

    /// @notice Casts vote for an agenda
    /// @param _agendaID Agenda ID
    /// @param _voter Voter
    /// @param _vote Voting type
    /// @return Whether or not the execution succeeded
    function castVote(
        uint256 _agendaID,
        address _voter,
        uint256 _vote
    )
        external
        override
        onlyOwner
        validAgenda(_agendaID)
        returns (bool)
    {
        require(_vote < uint256(VoteChoice.MAX), "DAOAgendaManager: invalid vote");

        require(
            isVotableStatus(_agendaID),
            "DAOAgendaManager: invalid status"
        );

        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        if (agenda.status == LibAgenda.AgendaStatus.NOTICE) {
            _startVoting(_agendaID);
        }

        require(isVoter(_agendaID, _voter), "DAOAgendaManager: not a voter");
        require(!hasVoted(_agendaID, _voter), "DAOAgendaManager: already voted");

        require(
            block.timestamp <= agenda.votingEndTimestamp,
            "DAOAgendaManager: for this agenda, the voting time expired"
        );
        
        LibAgenda.Voter storage voter = _voterInfos[_agendaID][_voter];
        voter.hasVoted = true;
        voter.vote = _vote;
             
        // counting 0:abstainVotes 1:yesVotes 2:noVotes
        if (_vote == uint256(VoteChoice.ABSTAIN))
            agenda.countingAbstain = agenda.countingAbstain.add(1);
        else if (_vote == uint256(VoteChoice.YES))
            agenda.countingYes = agenda.countingYes.add(1);
        else if (_vote == uint256(VoteChoice.NO))
            agenda.countingNo = agenda.countingNo.add(1);
        else
            revert("DAOAgendaManager: invalid voting");
        
        return true;
    }
    
    /// @notice Set the agenda status as executed
    /// @param _agendaID Agenda ID
    function setExecutedAgenda(uint256 _agendaID)
        external
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        agenda.executed = true;
        agenda.executedTimestamp = block.timestamp;

        uint256 prevStatus = uint256(agenda.status);
        agenda.status = LibAgenda.AgendaStatus.EXECUTED;
        emit AgendaStatusChanged(_agendaID, prevStatus, uint256(LibAgenda.AgendaStatus.EXECUTED));
    }

    /// @notice Set the agenda result
    /// @param _agendaID Agenda ID
    /// @param _result New result
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result)
        public
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        agenda.result = _result;

        emit AgendaResultChanged(_agendaID, uint256(_result));
    }
     
    /// @notice Set the agenda status
    /// @param _agendaID Agenda ID
    /// @param _status New status
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status)
        public
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        uint256 prevStatus = uint256(agenda.status);
        agenda.status = _status;
        emit AgendaStatusChanged(_agendaID, prevStatus, uint256(_status));
    }

    /// @notice Set the agenda status as ended(denied or dismissed)
    /// @param _agendaID Agenda ID
    function endAgendaVoting(uint256 _agendaID)
        external
        override
        onlyOwner
        validAgenda(_agendaID)
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        require(
            agenda.status == LibAgenda.AgendaStatus.VOTING,
            "DAOAgendaManager: agenda status is not changable"
        );

        require(
            agenda.votingEndTimestamp <= block.timestamp,
            "DAOAgendaManager: voting is not ended yet"
        );

        setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
    }
     
    function _startVoting(uint256 _agendaID) internal validAgenda(_agendaID) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        agenda.votingStartedTimestamp = block.timestamp;
        agenda.votingEndTimestamp = block.timestamp.add(agenda.votingPeriodInSeconds);
        agenda.executableLimitTimestamp = agenda.votingEndTimestamp.add(executingPeriodSeconds);
        agenda.status = LibAgenda.AgendaStatus.VOTING;

        uint256 memberCount = committee.maxMember();
        for (uint256 i = 0; i < memberCount; i++) {
            address voter = committee.members(i);
            agenda.voters.push(voter);
            _voterInfos[_agendaID][voter].isVoter = true;
        }

        emit AgendaStatusChanged(_agendaID, uint256(LibAgenda.AgendaStatus.NOTICE), uint256(LibAgenda.AgendaStatus.VOTING));
    }
    
    function isVoter(uint256 _agendaID, address _candidate) public view override validAgenda(_agendaID) returns (bool) {
        require(_candidate != address(0), "DAOAgendaManager: user address is zero");
        return _voterInfos[_agendaID][_candidate].isVoter;
    }
    
    function hasVoted(uint256 _agendaID, address _user) public view override validAgenda(_agendaID) returns (bool) {
        return _voterInfos[_agendaID][_user].hasVoted;
    }

    function getVoteStatus(uint256 _agendaID, address _user) external view override validAgenda(_agendaID) returns (bool, uint256) {
        LibAgenda.Voter storage voter = _voterInfos[_agendaID][_user];

        return (
            voter.hasVoted,
            voter.vote
        );
    }
    
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].noticeEndTimestamp;
    }
    
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].votingStartedTimestamp;
    }

    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256) {
        return _agendas[_agendaID].votingEndTimestamp;
    }

    function canExecuteAgenda(uint256 _agendaID) external view override validAgenda(_agendaID) returns (bool) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        return agenda.status == LibAgenda.AgendaStatus.WAITING_EXEC &&
            block.timestamp <= agenda.executableLimitTimestamp &&
            agenda.result == LibAgenda.AgendaResult.ACCEPT &&
            agenda.votingEndTimestamp <= block.timestamp &&
            agenda.executed == false;
    }
    
    function getAgendaStatus(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256 status) {
        return uint256(_agendas[_agendaID].status);
    }

    function totalAgendas() external view override returns (uint256) {
        return _agendas.length;
    }

    function getAgendaResult(uint256 _agendaID) external view override validAgenda(_agendaID) returns (uint256 result, bool executed) {
        return (uint256(_agendas[_agendaID].result), _agendas[_agendaID].executed);
    }
   
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        override
        validAgenda(_agendaID)
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        )
    {
        LibAgenda.AgendaExecutionInfo storage agenda = _executionInfos[_agendaID];
        return (
            agenda.targets,
            agenda.functionBytecodes,
            agenda.atomicExecute,
            agenda.executeStartFrom
        );
    }

    function setExecutedCount(uint256 _agendaID, uint256 _count) external override {
        LibAgenda.AgendaExecutionInfo storage agenda = _executionInfos[_agendaID];
        agenda.executeStartFrom = agenda.executeStartFrom.add(_count);
    }

    function isVotableStatus(uint256 _agendaID) public view override validAgenda(_agendaID) returns (bool) {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];

        return block.timestamp <= agenda.votingEndTimestamp ||
            (agenda.status == LibAgenda.AgendaStatus.NOTICE &&
                agenda.noticeEndTimestamp <= block.timestamp);
    }

    function getVotingCount(uint256 _agendaID)
        external
        view
        override
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        )
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        return (
            agenda.countingYes,
            agenda.countingNo,
            agenda.countingAbstain
        );
    }

    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        override
        validAgenda(_agendaID)
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        )
    {
        LibAgenda.Agenda storage agenda = _agendas[_agendaID];
        return (
            agenda.createdTimestamp,
            agenda.noticeEndTimestamp,
            agenda.votingStartedTimestamp,
            agenda.votingEndTimestamp,
            agenda.executedTimestamp
        );
    }

    function numAgendas() external view override returns (uint256) {
        return _agendas.length;
    }

    function getVoters(uint256 _agendaID) external view override validAgenda(_agendaID) returns (address[] memory) {
        return _agendas[_agendaID].voters;
    }

    function agendas(uint256 _index) external view override validAgenda(_index) returns (LibAgenda.Agenda memory) {
        return _agendas[_index];
    }

    function voterInfos(uint256 _agendaID, address _voter) external view override validAgenda(_agendaID) returns (LibAgenda.Voter memory) {
        return _voterInfos[_agendaID][_voter];
    }
}
