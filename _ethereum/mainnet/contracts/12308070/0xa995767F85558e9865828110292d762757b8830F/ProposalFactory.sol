// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IProposal.sol";
import "./IProposalFactory.sol";
import "./Controllable.sol";
import "./Create2.sol";
import "./GovernanceLib.sol";
import "./Proposal.sol";

contract ProposalFactory is Controllable, IProposalFactory {
    address private operator;

    mapping(uint256 => address) private _getProposal;
    address[] private _allProposals;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev get the proposal for this
     */
    function getProposal(uint256 _symbolHash) external view override returns (address proposal) {
        proposal = _getProposal[_symbolHash];
    }

    /**
     * @dev get the proposal for this
     */
    function allProposals(uint256 idx) external view override returns (address proposal) {
        proposal = _allProposals[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allProposalsLength() external view override returns (uint256 proposal) {
        proposal = _allProposals.length;
    }

    /**
     * @dev deploy a new proposal using create2
     */
    function createProposal(
        address submitter,
        string memory title,
        address proposalData,
        IProposal.ProposalType proposalType
    ) external override onlyController returns (address payable proposal) {

        // make sure this proposal doesnt already exist
        bytes32 salt = keccak256(abi.encodePacked(submitter, title));
        require(_getProposal[uint256(salt)] == address(0), "PROPOSAL_EXISTS"); // single check is sufficient

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(Proposal).creationCode;

        // use create2 to deploy the quantized erc20 contract
        proposal = payable(Create2.deploy(0, salt, bytecode));

        // initialize  the proposal with submitter, proposal type, and proposal data
        Proposal(proposal).initialize(submitter, title, proposalData, IProposal.ProposalType(proposalType));

        // add teh new proposal to our lists for management
        _getProposal[uint256(salt)] = proposal;
        _allProposals.push(proposal);

        // emit an event about the new proposal being created
        emit ProposalCreated(submitter, uint256(proposalType), proposal);
    }
}
