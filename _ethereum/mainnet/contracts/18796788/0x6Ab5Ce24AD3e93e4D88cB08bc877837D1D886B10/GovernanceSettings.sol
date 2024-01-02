// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IRegistry.sol";
import "./IRecordsRegistry.sol";
import "./IGovernanceSettings.sol";
import "./ExceptionsLibrary.sol";
/**
* @title Governance Settings Contract
* @notice This module is responsible for storing, validating, and applying Governance settings, and it inherits from the GovernorProposals contract.
*@dev This contract houses one of the most important structures of the protocol called GovernanceSettingsSet. It is used to represent various numerical parameters that universally and comprehensively describe the voting process. The module includes methods for formal data validation, which is proposed to be stored using this structure.
*/
abstract contract GovernanceSettings is IGovernanceSettings {
    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10**4;

    // STORAGE

    /**
    * @notice The minimum amount of votes required to create a proposal
    * @dev The proposal threshold is the number of votes (i.e., tokens delegated to an address) that are minimally required to create a proposal. When calling the Pool:propose method, the contract compares the number of votes of the address with this value, and if there are insufficient tokens in the delegation, the transaction ends with a revert.
    This value is stored in the Pool contract as an integer, taking into account the "Decimals" parameter of the Governance token. In the current version, for Governance tokens, this parameter is equal to 18. That is, the 18 rightmost digits of the value represent the fractional part of the number of tokens required to create a proposal.
    Each pool can set any ProposalThreshold value in the range from 0 to the maximum value allowed by the uint256 type. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions.
    */
    uint256 public proposalThreshold;

    /** 
    * @notice The minimum amount of votes which need to participate in the proposal in order for the proposal to be considered valid, given as a percentage of all existing votes
    * @dev The quorum threshold is a percentage ratio stored in the Pool contract as an integer using the DENOM entry. It indicates the minimum share of all proposals[proposalId].vote.availableVotes that must be used in voting (regardless of whether the votes were "for" or "against", their sum matters) for the vote to be considered valid.
    Reaching the Quorum Threshold is one of several conditions required for a proposal to be accepted and executable.
    Each pool can set any QuorumThreshold value in the range from 0 to 100%. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions.
    */
    uint256 public quorumThreshold;

    /** 
    * @notice The minimum amount of votes which are needed to approve the proposal, given as a percentage of all participating votes
    * @dev The decision threshold is a percentage ratio stored in the Pool contract as an integer using the DENOM entry. It indicates the minimum share of the votes cast by users that must be cast "for" a proposal during voting for a positive decision to be made.
    The sum of all votes cast by users during voting can be calculated using the formula:
        Pool:proposals[proposalId].vote.forVotes + Pool:proposals[proposalId].vote.againstVotes
    Reaching the Decision Threshold is one of several conditions required for a proposal to be accepted and executable.
    Each pool can set any DecisionThreshold value in the range from 0 to 100%. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions.
    */
    uint256 public decisionThreshold;

    /// @notice The amount of time for which the proposal will remain active, given as the number of blocks which have elapsed since the creation of the proposal
    uint256 public votingDuration;

    /// @notice The threshold value for a transaction which triggers the transaction execution delay
    uint256 public transferValueForDelay;

    /// @notice Returns transaction execution delay values for different proposal types
    mapping(IRegistry.EventType => uint256) public executionDelays;

    /// @notice Delay before voting starts. In blocks
    uint256 public votingStartDelay;

    /// @notice Storage gap (for future upgrades)
    uint256[49] private __gap;

    // EVENTS

    /**
    * @notice This event emitted only when the following values (governance settings) are set for a particular pool
     * @dev The emission of this event can coincide with the purchase of a pool, the launch of an initial TGE, or the execution of a transaction prescribed by a proposal with the GovernanceSettings type.GovernanceSettings
     * @param proposalThreshold_ the proposal threshold (specified in token units with decimals taken into account)
     * @param quorumThreshold_ the quorum threshold (specified as a percentage)
     * @param decisionThreshold_ the decision threshold (specified as a percentage)
     * @param votingDuration_ the duration of the voting period (specified in blocks)
     * @param transferValueForDelay_ the minimum amount in USD for which a transfer from the pool wallet will be subject to a delay
     * @param executionDelays_ execution delays specified in blocks for different types of proposals
     * @param votingStartDelay_ the delay before voting starts for newly created proposals, specified in blocks
     */
    event GovernanceSettingsSet(
        uint256 proposalThreshold_,
        uint256 quorumThreshold_,
        uint256 decisionThreshold_,
        uint256 votingDuration_,
        uint256 transferValueForDelay_,
        uint256[4] executionDelays_,
        uint256 votingStartDelay_
    );

    // PUBLIC FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function setGovernanceSettings(NewGovernanceSettings memory settings)
        external
    {
        // The governance settings function can only be called by the pool contract
        require(msg.sender == address(this), ExceptionsLibrary.INVALID_USER);

        // Internal function to update governance settings
        _setGovernanceSettings(settings);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function _setGovernanceSettings(NewGovernanceSettings memory settings)
        internal
    {
        // Validates the values for governance settings
        _validateGovernanceSettings(settings);

        // Apply settings
        proposalThreshold = settings.proposalThreshold;
        quorumThreshold = settings.quorumThreshold;
        decisionThreshold = settings.decisionThreshold;
        votingDuration = settings.votingDuration;
        transferValueForDelay = settings.transferValueForDelay;

        executionDelays[IRecordsRegistry.EventType.None] = settings
            .executionDelays[0];
        executionDelays[IRecordsRegistry.EventType.Transfer] = settings
            .executionDelays[1];
        executionDelays[IRecordsRegistry.EventType.TGE] = settings
            .executionDelays[2];
        executionDelays[
            IRecordsRegistry.EventType.GovernanceSettings
        ] = settings.executionDelays[3];

        votingStartDelay = settings.votingStartDelay;
    }

    // INTERNAL VIEW FUNCTIONS

    /**
     * @notice Validates governance settings
     * @param settings New governance settings
     */
    function _validateGovernanceSettings(NewGovernanceSettings memory settings)
        internal
        pure
    {
        // Check all values for sanity
        require(
            settings.quorumThreshold < DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            settings.decisionThreshold <= DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(settings.votingDuration > 0, ExceptionsLibrary.INVALID_VALUE);
    }
}
