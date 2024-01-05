// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Controllable.sol";
import "./Initializable.sol";

import "./INFTGemMultiToken.sol";
import "./IProposalFactory.sol";
import "./IProposal.sol";
import "./IERC1155.sol";
import "./INFTGemPoolFactory.sol";
import "./INFTGemPool.sol";
import "./INFTGemGovernor.sol";
import "./INFTGemFeeManager.sol";
import "./IProposalData.sol";

import "./SafeMath.sol";
import "./GovernanceLib.sol";
import "./ProposalsLib.sol";

import "./console.sol";


contract NFTGemGovernor is Initializable, Controllable, INFTGemGovernor {
    using SafeMath for uint256;

    address private multitoken;
    address private factory;
    address private feeTracker;
    address private proposalFactory;
    address private swapHelper;

    uint256 private constant GOVERNANCE = 0;
    uint256 private constant FUEL = 1;
    uint256 private constant GOV_TOKEN_INITIAL = 500000;
    uint256 private constant GOV_TOKEN_MAX     = 1000000;

    bool private governanceIssued;

    /**
     * @dev contract controller
     */
    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev init this smart contract
     */
    function initialize(
        address _multitoken,
        address _factory,
        address _feeTracker,
        address _proposalFactory,
        address _swapHelper
    ) external override initializer {
        multitoken = _multitoken;
        factory = _factory;
        feeTracker = _feeTracker;
        proposalFactory = _proposalFactory;
        swapHelper = _swapHelper;
    }

    /**
     * @dev create proposal vote tokens
     */
    function createProposalVoteTokens(uint256 proposalHash) external override onlyController {
        GovernanceLib.createProposalVoteTokens(multitoken, proposalHash);
    }

    /**
     * @dev destroy proposal vote tokens
     */
    function destroyProposalVoteTokens(uint256 proposalHash) external override onlyController {
        GovernanceLib.destroyProposalVoteTokens(multitoken, proposalHash);
    }

    /**
     * @dev execute proposal
     */
    function executeProposal(address propAddress) external override onlyController {
        ProposalsLib.executeProposal(multitoken, factory, address(this), feeTracker, swapHelper, propAddress);
    }

    /**
     * @dev issue initial governance tokens
     */
    function issueInitialGovernanceTokens(address receiver) external override returns (uint256) {
        require(!governanceIssued, "ALREADY_ISSUED");
        INFTGemMultiToken(multitoken).mint(receiver, GOVERNANCE, GOV_TOKEN_INITIAL);
        governanceIssued = true;
        emit GovernanceTokenIssued(receiver, GOV_TOKEN_INITIAL);
    }

    /**
     * @dev maybe issue a governance token to receiver
     */
    function maybeIssueGovernanceToken(address receiver) external override onlyController returns (uint256) {
        uint256 totalSupplyOf = INFTGemMultiToken(multitoken).totalBalances(GOVERNANCE);
        if (totalSupplyOf >= GOV_TOKEN_MAX) {
            return 0;
        }
        INFTGemMultiToken(multitoken).mint(receiver, GOVERNANCE, 1);
        emit GovernanceTokenIssued(receiver, 1);
    }

    /**
     * @dev shhh
     */
    function issueFuelToken(address receiver, uint256 amount) external override onlyController returns (uint256) {
        INFTGemMultiToken(multitoken).mint(receiver, FUEL, amount);
    }

    /**
     * @dev create a new pool - public, only callable by a controller of this contract
     */
    function createSystemPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external override onlyController returns (address pool) {
        pool = GovernanceLib.createPool(
            factory,
            symbol,
            name,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,
            allowedToken
        );
        // associate the pool with its relations
        associatePool(msg.sender, msg.sender, pool);
    }

    /**
     * @dev associate the pool with its relations
     */
    function associatePool(
        address creator,
        address funder,
        address pool
    ) internal {
        IControllable(multitoken).addController(pool);
        IControllable(this).addController(pool);
        INFTGemPool(pool).setMultiToken(multitoken);
        INFTGemPool(pool).setSwapHelper(swapHelper);
        INFTGemPool(pool).setGovernor(address(this));
        INFTGemPool(pool).setFeeTracker(feeTracker);
        INFTGemPool(pool).mintGenesisGems(creator, funder);
    }

    /**
     * @dev create a new pool - public, only callable by a controller of this contract
     */
    function createPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external override onlyController returns (address pool) {
        pool = GovernanceLib.createPool(
            factory,
            symbol,
            name,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,
            allowedToken
        );
        // associate the pool with its relations
        associatePool(IProposal(pool).creator(), IProposal(pool).funder(), pool);
    }

    /**
     * @dev create a proposal to create a new pool
     */
    function createNewPoolProposal(
        address submitter,
        string memory title,
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTIme,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,
        address allowedToken
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createNewPoolProposal(
            symbol,
            name,
            ethPrice,
            minTIme,
            maxTime,
            diffStep,
            maxClaims,
            allowedToken
        );
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.CREATE_POOL,
            title,
            proposal
        );
    }

    /**
     * @dev create a proposal to change fees for a token / pool
     */
    function createChangeFeeProposal(
        address submitter,
        string memory title,
        address token,
        address pool,
        uint256 feeDivisor
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createChangeFeeProposal(token, pool, feeDivisor);
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.CHANGE_FEE,
            title,
            proposal
        );
    }

    /**
     * @dev create a proposal to craete a project funding proposal
     */
    function createFundProjectProposal(
        address submitter,
        string memory title,
        address receiver,
        string memory descriptionUrl,
        uint256 ethAmount
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createFundProjectProposal(receiver, descriptionUrl, ethAmount);
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.FUND_PROJECT,
            title,
            proposal
        );
    }

    /**
     * @dev create a proposal to update the allowlist of a token/pool
     */
    function createUpdateAllowlistProposal(
        address submitter,
        string memory title,
        address token,
        address pool,
        bool newStatus
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createUpdateAllowlistProposal(token, pool, newStatus);
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.UPDATE_ALLOWLIST,
            title,
            proposal
        );
    }
}
