// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./GovernorUpgradeable.sol";
import "./GovernorSettingsUpgradeable.sol";
import "./GovernorVotesCompUpgradeable.sol";
import "./GovernorTimelockCompoundUpgradeable.sol";
import "./Initializable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./console.sol";
import "./GovernorCompatibilityBravoUpgradeable.sol";
import "./ITodayDAO.sol";

/// @custom:security-contact dev@todaynft.xyz
contract TodayGovernor is
    Initializable,
    ITodayDAO,
    IERC721ReceiverUpgradeable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCompatibilityBravoUpgradeable,
    GovernorVotesCompUpgradeable,
    GovernorTimelockCompoundUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 public constant MIN_PROPOSAL_THRESHOLD = 1;
    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD = 366;

    /// @notice The minimum setable voting period
    uint256 public constant MIN_VOTING_PERIOD = 5_760; // About 24 hours

    /// @notice The max setable voting period
    uint256 public constant MAX_VOTING_PERIOD = 161_280; // About 4 weeks

    /// @notice The min setable voting delay
    uint256 public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint256 public constant MAX_VOTING_DELAY = 40_320; // About 1 week

    /// WARNING: Only for testing
    uint256 public constant MIN_QUORUM_VOTES = 2;

    /// @notice The maximum setable quorum votes basis points
    uint256 public constant MAX_QUORUM_VOTES = 366;

    uint256 private _quorumVotes;

    uint256 public proposalCount;

    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    mapping(address => uint256) public latestProposalIds;

    mapping(uint256 => uint256) public proposalIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        ERC20VotesCompUpgradeable _token,
        ICompoundTimelockUpgradeable _timelock,
        address vetoer_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThreshold_,
        uint256 quorumVotes_
    ) public initializer {
        require(
            address(_timelock) != address(0),
            "TodayGovernor::initialize: can only initialize once"
        );
        require(
            address(vetoer_) != address(0),
            "TodayGovernor::initialize: invalid vetoer address"
        );
        require(
            votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD,
            "TodayGovernor::initialize: invalid voting period"
        );
        require(
            votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY,
            "TodayGovernor::initialize: invalid voting delay"
        );
        require(
            proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD &&
                proposalThreshold_ <= MAX_PROPOSAL_THRESHOLD,
            "TodayGovernor::initialize: invalid proposal threshold"
        );
        require(
            quorumVotes_ >= MIN_QUORUM_VOTES && quorumVotes_ <= MAX_QUORUM_VOTES,
            "TodayGovernor::initialize: invalid proquorum votes"
        );

        __Governor_init("Today DAO");
        __GovernorSettings_init(votingDelay_, votingPeriod_, proposalThreshold_);
        __GovernorCompatibilityBravo_init();
        __GovernorVotesComp_init(_token);
        __GovernorTimelockCompound_init(_timelock);

        vetoer = vetoer_;
        _quorumVotes = quorumVotes_;
    }

    /**
     * Create a proposal if the sender has enough votes
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(GovernorUpgradeable, GovernorCompatibilityBravoUpgradeable, IGovernorUpgradeable)
        returns (uint256)
    {
        require(moreThan50(values) == false, "TodayGovernor::propose: invalid values");

        uint256 proposeId = super.propose(targets, values, calldatas, description);

        proposalCount++;
        latestProposalIds[msg.sender] = proposeId;
        proposalIds[proposalCount] = proposeId;

        return proposeId;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint256) {
        require(moreThan50(values) == false, "TodayGovernor::propose: invalid values");

        uint256 proposeId = super.propose(targets, values, signatures, calldatas, description);

        proposalCount++;
        latestProposalIds[msg.sender] = proposeId;
        proposalIds[proposalCount] = proposeId;

        return proposeId;
    }

    function moreThan50(uint256[] memory values) internal view returns (bool) {
        uint256 totalBalance = timelock().balance;
        uint256 totalValue = 0;
        for (uint256 i = 0; i < values.length; i++) {
            totalValue += values[i];
        }
        return totalValue > totalBalance.div(2);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return _quorumVotes;
    }

    /**
     * the number of blocks a proposal needs to wait after creation to become active and allow voting.
     * Usually set to zero, but a longer delay gives people time to set up their votes before voting begins
     */
    function votingDelay()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    /**
     * the number of blocks to run the voting. A longer period gives people more time to vote.
     * Usually, DAOs set the period to something between 3 and 6 days.
     */
    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    /**
     * the minimum amount of voting power an address needs to create a proposal.
     * A low threshold allows spam, but a high threshold makes proposals nearly
     * impossible! Often, DAOs set to a number that allows 5 or 10 of the largest
     * tokenholders to create proposals.
     */
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    // The following functions are overrides required by Solidity.
    /**
     * Get the amount of votes a user had before the proposal goes live
     */
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesCompUpgradeable)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /**
     * Get us to get the current state of the specified proposal
     */
    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, IGovernorUpgradeable, GovernorTimelockCompoundUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId)
        internal
        view
        override(GovernorUpgradeable, GovernorCompatibilityBravoUpgradeable)
        returns (bool)
    {
        (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) = votes(proposalId);

        uint256 totalVotes = forVotes + againstVotes + abstainVotes;
        return totalVotes >= quorumVotes();
        // return super._quorumReached(proposalId);
    }

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId)
        internal
        view
        override(GovernorUpgradeable, GovernorCompatibilityBravoUpgradeable)
        returns (bool)
    {
        (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) = votes(proposalId);

        uint256 totalVotes = forVotes + againstVotes + abstainVotes;
        return totalVotes > 1 && forVotes > totalVotes.div(2);
        // return super._voteSucceeded(proposalId);
    }

    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal override(GovernorUpgradeable, GovernorCompatibilityBravoUpgradeable) {
        super._countVote(proposalId, account, support, weight);
    }

    /**
     * Send the proposal for execution, the proposal needs to has surpassed the needed timelock delay
     */
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockCompoundUpgradeable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * Cancel the specified proposal if the creator of it falls bellow the required threshold
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(GovernorUpgradeable, GovernorTimelockCompoundUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * Get the address through which the governor executes action.
     */
    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockCompoundUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function veto(uint256 proposalId, string memory description) external {
        require(vetoer != address(0), "TodayGovernor::veto: no vetoer set");
        require(msg.sender == vetoer, "TodayGovernor::veto: sender is not the vetoer");
        require(
            state(proposalId) != ProposalState.Executed,
            "TodayGovernor::veto: proposal is already executed"
        );

        (
            address[] memory targets,
            uint256[] memory values,
            ,
            bytes[] memory calldatas
        ) = getActions(proposalId);

        bytes32 descriptionHash = keccak256(bytes(description));

        _cancel(targets, values, calldatas, descriptionHash);

        emit ProposalVetoed(proposalId);
    }

    /**
     * @notice Changes vetoer address
     * @dev Vetoer function for updating vetoer address
     */
    function setVetoer(address newVetoer) public {
        require(msg.sender == vetoer, "TodayGovernor::setVetoer: vetoer only");

        emit NewVetoer(vetoer, newVetoer);

        vetoer = newVetoer;
    }

    function removeVetoer() public {
        require(msg.sender == vetoer, "TodayGovernor::removeVetoer: vetoer only");

        setVetoer(address(0));
    }

    /**
     * ERC165 that allows to validate the interfaces used in our contract
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, IERC165Upgradeable, GovernorTimelockCompoundUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
