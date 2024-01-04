//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.16;

pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./SafeDecimalMath.sol";

/**
@title A contract that allows for the dilution of Spartan Council voting weights
@author @andytcf
 */
contract CouncilDilution is Owned {
    using SafeDecimalMath for uint;

    /* SCCP configurable values */

    // @notice How many seats on the Spartan Council
    uint public numOfSeats;

    // @notice The length of a proposal (SCCP/SIP) voting period
    uint public proposalPeriod;

    /* Global variables */

    // @notice The ipfs hash of the latest Spartan Council election proposal
    string public latestElectionHash;

    struct ElectionLog {
        // @notice The ipfs hash of a particular Spartan Council election proposal
        string electionHash;
        // @notice A mapping of the votes allocated to each of the Spartan Council members
        mapping(address => uint) votesForMember;
        // @notice A mapping to check whether an address was an elected Council member in this election
        mapping(address => bool) councilMembers;
        // @notice The timestamp which the election log was stored
        uint created;
    }

    struct ProposalLog {
        // @notice The ipfs hash of a particular SCCP/SIP proposal
        string proposalHash;
        //  @notice The timestamp which the voting period begins
        uint start;
        // @notice The timestamp which the voting period of the proposal ends
        uint end;
        // @notice A boolean value to check whether a proposal log exists
        bool exist;
    }

    struct DilutionReceipt {
        // @notice The ipfs hash of the proposal which the dilution happened on
        string proposalHash;
        // @notice The address of the council member diluted
        address memberDiluted;
        // @notice The total amount in which the council member was diluted by
        uint totalDilutionValue;
        // @notice A list of dilutors
        address[] dilutors;
        // @notice A mapping to show the value of dilution per dilutor
        mapping(address => uint) voterDilutions;
        // @notice A flag value to check whether a dilution exist
        bool exist;
    }

    // @notice Given a election hash, return the ElectionLog struct associated
    mapping(string => ElectionLog) public electionHashToLog;

    // @notice Given a voter address and a council member address, return the delegated vote weight for the most recent Spartan Council election
    mapping(address => mapping(address => uint)) public latestDelegatedVoteWeight;

    // @notice Given a council member address, return the total delegated vote weight for the most recent Spartan Council election
    mapping(address => uint) public latestVotingWeight;

    // @notice Given a propoal hash and a voting address, find out the member the user has voted for
    mapping(string => mapping(address => address)) public electionMemberVotedFor;

    // @notice Given a proposal hash and a voting address, find if a member has diluted
    mapping(string => mapping(address => bool)) public hasAddressDilutedForProposal;

    // @notice Given a proposal hash (SCCP/SIP), return the ProposalLog struct associated
    mapping(string => ProposalLog) public proposalHashToLog;

    // @notice Given a proposal hash and a council member, return the DilutionReceipt if it exists
    mapping(string => mapping(address => DilutionReceipt)) public proposalHashToMemberDilution;

    /* Events */

    // @notice An event emitted when a new ElectionLog is created
    event ElectionLogged(
        string electionHash,
        address[] nominatedCouncilMembers,
        address[] voters,
        address[] nomineesVotedFor,
        uint[] assignedVoteWeights
    );

    // @notice An event emitted when a new ProposalLog is created
    event ProposalLogged(string proposalHash, uint start, uint end);

    // @notice An event emitted when a new DilutionReceipt is created
    event DilutionCreated(
        string proposalHash,
        address memberDiluted,
        uint totalDilutionValueBefore,
        uint totalDilutionValueAfter
    );

    // @notice An event emitted when a DilutionReceipt is modified
    event DilutionModified(
        string proposalHash,
        address memberDiluted,
        uint totalDilutionValueBefore,
        uint totalDilutionValueAfter
    );

    // @notice An event emitted when the number of council seats is modified
    event SeatsModified(uint previousNumberOfSeats, uint newNumberOfSeats);

    // @notice An event emitted when the proposal period is modified
    event ProposalPeriodModified(uint previousProposalPeriod, uint newProposalPeriod);

    /* */

    // @notice Initialises the contract with a X number of council seats and a proposal period of 3 days
    constructor(uint _numOfSeats) public Owned(msg.sender) {
        numOfSeats = _numOfSeats;
        proposalPeriod = 3 days;
    }

    /* Mutative Functions */

    /**
    @notice A function to create a new ElectionLog, this is called to record the result of a Spartan Council election
    @param electionHash The ipfs hash of the Spartan Council election proposal to log
    @param nominatedCouncilMembers The array of the successful Spartan Council nominees addresses, must be the same length as the numOfSeats
    @param voters An ordered array of all the voter's addresses corresponding to `nomineesVotedFor`, `assignedVoteWeights`
    @param nomineesVotedFor An ordered array of all the nominee address that received votes corresponding to `voters`, `assignedVoteWeights`
    @param assignedVoteWeights An ordered array of the voting weights corresponding to `voters`, `nomineesVotedFor`
    @return electionHash
     */
    function logElection(
        string memory electionHash,
        address[] memory nominatedCouncilMembers,
        address[] memory voters,
        address[] memory nomineesVotedFor,
        uint[] memory assignedVoteWeights
    ) public onlyOwner() returns (string memory) {
        require(bytes(electionHash).length > 0, "empty election hash provided");
        require(voters.length > 0, "empty voters array provided");
        require(nomineesVotedFor.length > 0, "empty nomineesVotedFor array provided");
        require(assignedVoteWeights.length > 0, "empty assignedVoteWeights array provided");
        require(nominatedCouncilMembers.length == numOfSeats, "invalid number of council members");

        ElectionLog memory newElectionLog = ElectionLog(electionHash, now);

        electionHashToLog[electionHash] = newElectionLog;

        // store the voting history for calculating the allocated voting weights
        for (uint i = 0; i < voters.length; i++) {
            latestDelegatedVoteWeight[voters[i]][nomineesVotedFor[i]] = assignedVoteWeights[i];
            latestVotingWeight[nomineesVotedFor[i]] = latestVotingWeight[nomineesVotedFor[i]] + assignedVoteWeights[i];
            electionMemberVotedFor[electionHash][voters[i]] = nomineesVotedFor[i];
        }

        // store the total weight of each successful council member
        for (uint j = 0; j < nominatedCouncilMembers.length; j++) {
            electionHashToLog[electionHash].votesForMember[nominatedCouncilMembers[j]] = latestVotingWeight[
                nominatedCouncilMembers[j]
            ];
            electionHashToLog[electionHash].councilMembers[nominatedCouncilMembers[j]] = true;
        }

        latestElectionHash = electionHash;

        emit ElectionLogged(electionHash, nominatedCouncilMembers, voters, nomineesVotedFor, assignedVoteWeights);

        return electionHash;
    }

    /**
    @notice A function to created a new ProposalLog, this is called to record SCCP/SIPS created and allow for dilution to occur per proposal.
    @param proposalHash the ipfs hash of the proposal to be logged
    @return proposalHash
     */
    function logProposal(string memory proposalHash) public returns (string memory) {
        require(!proposalHashToLog[proposalHash].exist, "proposal hash is not unique");
        require(bytes(proposalHash).length > 0, "proposal hash must not be empty");

        uint start = now;

        uint end = start + proposalPeriod;

        ProposalLog memory newProposalLog = ProposalLog(proposalHash, start, end, true);

        proposalHashToLog[proposalHash] = newProposalLog;

        emit ProposalLogged(proposalHash, start, end);

        return proposalHash;
    }

    /**
    @notice  A function to dilute a council member's voting weight for a particular proposal
    @param proposalHash the ipfs hash of the proposal to be logged
    @param memberToDilute the address of the member to dilute
     */
    function dilute(string memory proposalHash, address memberToDilute) public {
        require(memberToDilute != address(0), "member to dilute must be a valid address");
        require(
            electionHashToLog[latestElectionHash].councilMembers[memberToDilute],
            "member to dilute must be a nominated council member"
        );
        require(proposalHashToLog[proposalHash].exist, "proposal does not exist");
        require(
            latestDelegatedVoteWeight[msg.sender][memberToDilute] > 0,
            "sender has not delegated voting weight for member"
        );
        require(now < proposalHashToLog[proposalHash].end, "dilution can only occur within the proposal voting period");
        require(hasAddressDilutedForProposal[proposalHash][msg.sender] == false, "sender has already diluted");

        if (proposalHashToMemberDilution[proposalHash][memberToDilute].exist) {
            DilutionReceipt storage receipt = proposalHashToMemberDilution[proposalHash][memberToDilute];

            uint originalTotalDilutionValue = receipt.totalDilutionValue;

            receipt.dilutors.push(msg.sender);
            receipt.voterDilutions[msg.sender] = latestDelegatedVoteWeight[msg.sender][memberToDilute];
            receipt.totalDilutionValue = receipt.totalDilutionValue + latestDelegatedVoteWeight[msg.sender][memberToDilute];

            hasAddressDilutedForProposal[proposalHash][msg.sender] = true;

            emit DilutionCreated(
                proposalHash,
                receipt.memberDiluted,
                originalTotalDilutionValue,
                receipt.totalDilutionValue
            );
        } else {
            address[] memory dilutors;
            DilutionReceipt memory newDilutionReceipt = DilutionReceipt(proposalHash, memberToDilute, 0, dilutors, true);

            proposalHashToMemberDilution[proposalHash][memberToDilute] = newDilutionReceipt;

            uint originalTotalDilutionValue = proposalHashToMemberDilution[proposalHash][memberToDilute].totalDilutionValue;

            proposalHashToMemberDilution[proposalHash][memberToDilute].dilutors.push(msg.sender);

            proposalHashToMemberDilution[proposalHash][memberToDilute].voterDilutions[
                msg.sender
            ] = latestDelegatedVoteWeight[msg.sender][memberToDilute];

            proposalHashToMemberDilution[proposalHash][memberToDilute].totalDilutionValue = latestDelegatedVoteWeight[
                msg.sender
            ][memberToDilute];

            hasAddressDilutedForProposal[proposalHash][msg.sender] = true;

            emit DilutionCreated(
                proposalHash,
                memberToDilute,
                originalTotalDilutionValue,
                proposalHashToMemberDilution[proposalHash][memberToDilute].totalDilutionValue
            );
        }
    }

    /**
    @notice  A function that allows a voter to undo a dilution
    @param proposalHash the ipfs hash of the proposal to be logged
    @param memberToUndilute the address of the member to undilute
     */
    function invalidateDilution(string memory proposalHash, address memberToUndilute) public {
        require(memberToUndilute != address(0), "member to undilute must be a valid address");
        require(proposalHashToLog[proposalHash].exist, "proposal does not exist");
        require(
            proposalHashToMemberDilution[proposalHash][memberToUndilute].exist,
            "dilution receipt does not exist for this member and proposal hash"
        );
        require(
            proposalHashToMemberDilution[proposalHash][memberToUndilute].voterDilutions[msg.sender] > 0 &&
                hasAddressDilutedForProposal[proposalHash][msg.sender] == true,
            "voter has no dilution weight"
        );
        require(now < proposalHashToLog[proposalHash].end, "undo dilution can only occur within the proposal voting period");

        address caller = msg.sender;

        DilutionReceipt storage receipt = proposalHashToMemberDilution[proposalHash][memberToUndilute];

        uint originalTotalDilutionValue = receipt.totalDilutionValue;

        uint voterDilutionValue = receipt.voterDilutions[msg.sender];

        hasAddressDilutedForProposal[proposalHash][msg.sender] = false;

        for (uint i = 0; i < receipt.dilutors.length; i++) {
            if (receipt.dilutors[i] == caller) {
                receipt.dilutors[i] = receipt.dilutors[receipt.dilutors.length - 1];
                break;
            }
        }

        receipt.dilutors.pop();

        receipt.voterDilutions[msg.sender] = 0;
        receipt.totalDilutionValue = receipt.totalDilutionValue - voterDilutionValue;

        emit DilutionModified(proposalHash, receipt.memberDiluted, originalTotalDilutionValue, receipt.totalDilutionValue);
    }

    /* Views */

    /**
    @notice   A view function that checks which proposalHashes exist on the contract and return them
    @param proposalHashes a array of hashes to check validity against
    @return a array with elements either empty or with the valid proposal hash
     */
    function getValidProposals(string[] memory proposalHashes) public view returns (string[] memory) {
        string[] memory validHashes = new string[](proposalHashes.length);

        for (uint i = 0; i < proposalHashes.length; i++) {
            string memory proposalHash = proposalHashes[i];
            if (proposalHashToLog[proposalHash].exist) {
                validHashes[i] = (proposalHashToLog[proposalHash].proposalHash);
            }
        }

        return validHashes;
    }

    /**
    @notice A view function that calculates the council member voting weight for a proposal after any dilution penalties
    @param proposalHash the ipfs hash of the proposal to check dilution against
    @param councilMember the council member to check diluted weight for
    @return the calculated diluted ratio (1e18)
     */
    function getDilutedWeightForProposal(string memory proposalHash, address councilMember) public view returns (uint) {
        require(proposalHashToLog[proposalHash].exist, "proposal does not exist");
        require(
            electionHashToLog[latestElectionHash].councilMembers[councilMember],
            "address must be a nominated council member"
        );

        uint originalWeight = electionHashToLog[latestElectionHash].votesForMember[councilMember];
        uint penaltyValue = proposalHashToMemberDilution[proposalHash][councilMember].totalDilutionValue;

        return (originalWeight - penaltyValue).divideDecimal(originalWeight);
    }

    /**
    @notice A view helper function to get the dilutors for a particular DilutionReceipt
    @param proposalHash the ipfs hash of the proposal to get the dilution receipt for
    @param memberDiluted the council member to get the dilution array for
    @return a list of the voters addresses who have diluted this member for this proposal
     */
    function getDilutorsForDilutionReceipt(string memory proposalHash, address memberDiluted)
        public
        view
        returns (address[] memory)
    {
        return proposalHashToMemberDilution[proposalHash][memberDiluted].dilutors;
    }

    /**
    @notice A view helper function to get the weighting of a voter's dilution for a DilutionReceipt
    @param proposalHash the ipfs hash of the proposal to get the dilution receipt for
    @param memberDiluted the council member to check dilution weighting against
    @param voter the voter address to get the dilution weighting for
    @return the dilution weight of the voter, for a specific proposal and council member
     */
    function getVoterDilutionWeightingForDilutionReceipt(
        string memory proposalHash,
        address memberDiluted,
        address voter
    ) public view returns (uint) {
        return proposalHashToMemberDilution[proposalHash][memberDiluted].voterDilutions[voter];
    }

    /* Restricted Functions */

    /**
    @notice A function that can only be called by the OWNER that changes the number of seats on the Spartan Council
    @param _numOfSeats the number of seats to set the numOfSeats to
     */
    function modifySeats(uint _numOfSeats) public onlyOwner() {
        require(_numOfSeats > 0, "number of seats must be greater than zero");
        uint oldNumOfSeats = numOfSeats;
        numOfSeats = _numOfSeats;

        emit SeatsModified(oldNumOfSeats, numOfSeats);
    }

    /**
    @notice A function that can only be called by the owner that changes the proposal voting period length
    @param _proposalPeriod the proposal perod in seconds, to set the proposalPeriod variable to
     */
    function modifyProposalPeriod(uint _proposalPeriod) public onlyOwner() {
        uint oldProposalPeriod = proposalPeriod;
        proposalPeriod = _proposalPeriod;

        emit ProposalPeriodModified(oldProposalPeriod, proposalPeriod);
    }
}
