// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./CVNX.sol";
import "./ICVNXGovernance.sol";

/// @notice Governance contract for CVNX token.
contract CVNXGovernance is ICVNXGovernance, Ownable {
    CVNX private cvnx;

    /// @notice Emit when new poll created.
    event PollCreated(uint256 indexed pollNum);

    /// @notice Emit when address vote in poll.
    event PollVoted(address voterAddress, VoteType indexed voteType, uint256 indexed voteWeight);

    /// @notice Emit when poll stopped.
    event PollStop(uint256 indexed pollNum, uint256 indexed stopTimestamp);

    /// @notice Contain all polls. Index - poll number.
    Poll[] public polls;

    /// @notice Contain Vote for addresses that vote in poll.
    mapping(uint256 => mapping(address => Vote)) public voted;

    /// @notice Shows whether tokens are locked for a certain pool at a certain address.
    mapping(uint256 => mapping(address => bool)) public isTokenLockedInPoll;

    /// @notice List of verified addresses for PRIVATE poll.
    mapping(uint256 => mapping(address => bool)) public verifiedToVote;

    /// @param _cvnxTokenAddress CVNX token address.
    constructor(address _cvnxTokenAddress) {
        cvnx = CVNX(_cvnxTokenAddress);
    }

    /// @notice Modifier check minimal CVNX token balance before method call.
    /// @param _minimalBalance Minimal balance on address (Wei)
    modifier onlyWithBalanceNoLess(uint256 _minimalBalance) {
        require(cvnx.balanceOf(msg.sender) > _minimalBalance, "[E-34] - Your balance is too low.");
        _;
    }

    /// @notice Create PROPOSAL poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createProposalPoll(uint64 _pollDeadline, string memory _pollInfo) external override {
        _createPoll(PollType.PROPOSAL, _pollDeadline, _pollInfo);
    }

    /// @notice Create EXECUTIVE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createExecutivePoll(uint64 _pollDeadline, string memory _pollInfo) external override onlyOwner {
        _createPoll(PollType.EXECUTIVE, _pollDeadline, _pollInfo);
    }

    /// @notice Create EVENT poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createEventPoll(uint64 _pollDeadline, string memory _pollInfo) external override onlyOwner {
        _createPoll(PollType.EVENT, _pollDeadline, _pollInfo);
    }

    /// @notice Create PRIVATE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    /// @param _verifiedAddresses Array of verified addresses for poll
    function createPrivatePoll(
        uint64 _pollDeadline,
        string memory _pollInfo,
        address[] memory _verifiedAddresses
    ) external override onlyOwner {
        uint256 _verifiedAddressesCount = _verifiedAddresses.length;
        require(_verifiedAddressesCount > 1, "[E-35] - Verified addresses not set.");

        uint256 _pollNum = _createPoll(PollType.PRIVATE, _pollDeadline, _pollInfo);

        for (uint256 i = 0; i < _verifiedAddressesCount; i++) {
            verifiedToVote[_pollNum][_verifiedAddresses[i]] = true;
        }
    }

    /// @notice Send tokens as vote in poll. Tokens will be lock.
    /// @param _pollNum Poll number
    /// @param _voteType Vote type (FOR, AGAINST)
    /// @param _voteWeight Vote weight in CVNX tokens
    function vote(
        uint256 _pollNum,
        VoteType _voteType,
        uint256 _voteWeight
    ) external override onlyWithBalanceNoLess(1000000) {
        require(polls[_pollNum].pollStopped > block.timestamp, "[E-37] - Poll ended.");

        if (polls[_pollNum].pollType == PollType.PRIVATE) {
            require(verifiedToVote[_pollNum][msg.sender] == true, "[E-38] - You are not verify to vote in this poll.");
        }

        // Lock tokens
        cvnx.lock(msg.sender, _voteWeight);
        isTokenLockedInPoll[_pollNum][msg.sender] = true;

        uint256 _voterVoteWeightBefore = voted[_pollNum][msg.sender].voteWeight;

        // Set vote type
        if (_voterVoteWeightBefore > 0) {
            require(
                voted[_pollNum][msg.sender].voteType == _voteType,
                "[E-39] - The voice type does not match the first one."
            );
        } else {
            voted[_pollNum][msg.sender].voteType = _voteType;
        }

        // Increase vote weight for voter
        voted[_pollNum][msg.sender].voteWeight = _voterVoteWeightBefore + _voteWeight;

        // Increase vote weight in poll
        if (_voteType == VoteType.FOR) {
            polls[_pollNum].forWeight += _voteWeight;
        } else {
            polls[_pollNum].againstWeight += _voteWeight;
        }

        emit PollVoted(msg.sender, _voteType, _voteWeight);
    }

    /// @notice Unlock tokens for poll. Poll should be ended.
    /// @param _pollNum Poll number
    function unlockTokensInPoll(uint256 _pollNum) external override {
        require(polls[_pollNum].pollStopped <= block.timestamp, "[E-81] - Poll is not ended.");
        require(isTokenLockedInPoll[_pollNum][msg.sender] == true, "[E-82] - Tokens not locked for this poll.");

        isTokenLockedInPoll[_pollNum][msg.sender] = false;

        // Unlock tokens
        cvnx.unlock(msg.sender, voted[_pollNum][msg.sender].voteWeight);
    }

    /// @notice Stop poll before deadline.
    /// @param _pollNum Poll number
    function stopPoll(uint256 _pollNum) external override {
        require(
            owner() == msg.sender || polls[_pollNum].pollOwner == msg.sender,
            "[E-91] - Not a contract or poll owner."
        );
        require(block.timestamp < polls[_pollNum].pollDeadline, "[E-92] - Poll ended.");

        polls[_pollNum].pollStopped = uint64(block.timestamp);

        emit PollStop(_pollNum, block.timestamp);
    }

    /// @notice Return poll status (PENDING, APPROVED, REJECTED, DRAW).
    /// @param _pollNum Poll number
    /// @return Poll number and status
    function getPollStatus(uint256 _pollNum) external view override returns (uint256, PollStatus) {
        if (polls[_pollNum].pollStopped > block.timestamp) {
            return (_pollNum, PollStatus.PENDING);
        }

        uint256 _forWeight = polls[_pollNum].forWeight;
        uint256 _againstWeight = polls[_pollNum].againstWeight;

        if (_forWeight > _againstWeight) {
            return (_pollNum, PollStatus.APPROVED);
        } else if (_forWeight < _againstWeight) {
            return (_pollNum, PollStatus.REJECTED);
        } else {
            return (_pollNum, PollStatus.DRAW);
        }
    }

    /// @notice Return the poll expiration timestamp.
    /// @param _pollNum Poll number
    /// @return Poll deadline
    function getPollExpirationTime(uint256 _pollNum) external view override returns (uint64) {
        return polls[_pollNum].pollDeadline;
    }

    /// @notice Return the poll stop timestamp.
    /// @param _pollNum Poll number
    /// @return Poll stop time
    function getPollStopTime(uint256 _pollNum) external view override returns (uint64) {
        return polls[_pollNum].pollStopped;
    }

    /// @notice Return the complete list of polls an address has voted in.
    /// @param _voter Voter address
    /// @return Index - poll number. True - if address voted in poll
    function getPollHistory(address _voter) external view override returns (bool[] memory) {
        uint256 _pollsCount = polls.length;
        bool[] memory _pollNums = new bool[](_pollsCount);

        for (uint256 i = 0; i < _pollsCount; i++) {
            if (voted[i][_voter].voteWeight > 0) {
                _pollNums[i] = true;
            }
        }

        return _pollNums;
    }

    /// @notice Return the vote info for a given poll for an address.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Info about voter vote
    function getPollInfoForVoter(uint256 _pollNum, address _voter) external view override returns (Vote memory) {
        return voted[_pollNum][_voter];
    }

    /// @notice Checks if a user address has voted for a specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return True if address voted in poll
    function getIfUserHasVoted(uint256 _pollNum, address _voter) external view override returns (bool) {
        return voted[_pollNum][_voter].voteWeight > 0;
    }

    /// @notice Return the amount of tokens that are locked for a given voter address.
    /// @param _voter Voter address
    /// @return Poll number
    function getLockedAmount(address _voter) external view override returns (uint256) {
        return cvnx.lockedAmount(_voter);
    }

    /// @notice Return the amount of locked tokens of the specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Locked tokens amount for specific poll
    function getPollLockedAmount(uint256 _pollNum, address _voter) external view override returns (uint256) {
        if (isTokenLockedInPoll[_pollNum][_voter]) {
            return voted[_pollNum][_voter].voteWeight;
        } else {
            return 0;
        }
    }

    /// @notice Create poll process.
    /// @param _pollType Poll type
    /// @param _pollDeadline Poll deadline adn stop timestamp
    /// @param _pollInfo Poll info
    /// @return Poll number
    function _createPoll(
        PollType _pollType,
        uint64 _pollDeadline,
        string memory _pollInfo
    ) private onlyWithBalanceNoLess(0) returns (uint256) {
        require(_pollDeadline > block.timestamp, "[E-41] - The deadline must be longer than the current time.");

        Poll memory _poll = Poll(_pollDeadline, _pollDeadline, _pollType, msg.sender, _pollInfo, 0, 0);

        uint256 _pollNum = polls.length;
        polls.push(_poll);

        emit PollCreated(_pollNum);

        return _pollNum;
    }
}
