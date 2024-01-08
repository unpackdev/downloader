// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTGemGovernor {
    event GovernanceTokenIssued(address indexed receiver, uint256 amount);
    event FeeUpdated(address indexed proposal, address indexed token, uint256 newFee);
    event AllowList(address indexed proposal, address indexed token, bool isBanned);
    event ProjectFunded(address indexed proposal, address indexed receiver, uint256 received);
    event StakingPoolCreated(
        address indexed proposal,
        address indexed pool,
        string symbol,
        string name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,
        address alllowedToken
    );

    function initialize(
        address _multitoken,
        address _factory,
        address _feeTracker,
        address _proposalFactory,
        address _swapHelper
    ) external;

    function createProposalVoteTokens(uint256 proposalHash) external;

    function destroyProposalVoteTokens(uint256 proposalHash) external;

    function executeProposal(address propAddress) external;

    function issueInitialGovernanceTokens(address receiver) external returns (uint256);

    function maybeIssueGovernanceToken(address receiver) external returns (uint256);

    function issueFuelToken(address receiver, uint256 amount) external returns (uint256);

    function createPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external returns (address);

    function createSystemPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external returns (address);

    function createNewPoolProposal(
        address,
        string memory,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external returns (address);

    function createChangeFeeProposal(
        address,
        string memory,
        address,
        address,
        uint256
    ) external returns (address);

    function createFundProjectProposal(
        address,
        string memory,
        address,
        string memory,
        uint256
    ) external returns (address);

    function createUpdateAllowlistProposal(
        address,
        string memory,
        address,
        address,
        bool
    ) external returns (address);
}
