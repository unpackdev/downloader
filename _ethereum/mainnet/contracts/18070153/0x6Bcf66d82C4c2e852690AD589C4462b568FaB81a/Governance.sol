// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20.sol";
import "./IDABotManager.sol";
import "./Errors.sol";
import "./Ownable.sol";
import "./IConfigurator.sol";
import "./IGovernance.sol";
import "./IVoteStrategy.sol";
import "./ITimelockExecutor.sol";
import "./GovernanceLib.sol";

contract Governance is Ownable, IGovernanceEvent, Initializable {
    using GovernanceLib for Proposal;

    IConfigurator public config;
    IERC20 private __vics;

    address private _guardian;
    uint256 private _proposalCount;
    mapping(uint256 => Proposal) _proposals;
    mapping(address => IVoteStrategy) _strategies;
    IVoteStrategy public defaultStrategy;
    ITimelockExecutor public executor;

    uint256 constant HUNDRED_PERCENT = 10000;

    /// Target should be either 0x0 or account of a DABot
    modifier validTarget(address target) {
        if (target != address(0)) {
            require(
                _botManager().isRegisteredBot(target),
                Errors.GOV_TARGET_SHOULD_BE_ZERO_OR_REGISTERED_BOT
            );
        }
        _;
    }

    modifier validProposalId(uint256 id) {
        require(_proposals[id].isValid(), Errors.GOV_INVALID_PROPOSAL_ID);
        _;
    }

    modifier votingProposal(uint256 id) {
        Proposal storage p = _proposals[id];
        require(p.isValid(), Errors.GOV_INVALID_PROPOSAL_ID);
        require(
            p.state() == ProposalState.Voting,
            Errors.GOV_PROPOSAL_DONT_ACCEPT_VOTE
        );
        _;
    }

    modifier onlyOperator() {
        // TODO: check for operator role in configurator
        _;
    }

    function initialize(IConfigurator _config) external payable initializer {
        _transferOwnership(_msgSender());
        setConfigProvider(_config);
    }

    function setDefaultStrategy(IVoteStrategy strategy) external onlyOwner {
        defaultStrategy = strategy;
        emit DefaultStrategyChanged(address(strategy));
    }

    function setVoteStrategy(address target, IVoteStrategy strategy) external onlyOwner {
        _strategies[target] = strategy;
        emit StrategyChanged(target, address(strategy));
    }

    function setExecutor(ITimelockExecutor _executor) public onlyOwner {
        executor = _executor;
        emit ExecutorChanged(address(_executor));
    }

    function setConfigProvider(IConfigurator _config) public onlyOwner {
        config = _config;
    }

    function vics() public view returns(IERC20) {
        return IERC20(config.addressOf(AddressBook.ADDR_VICS));
    }

    function getProposalById(uint proposalId) external view returns(ProposalMeta memory p) {
        p = _proposals[proposalId].meta;
        p.state = _proposals[proposalId].state();
    }

     function getStrategy(address target) public view returns (IVoteStrategy strategy) {
        strategy = _strategies[target];
        if (address(strategy) == address(0) && _botManager().isRegisteredBot(target)) 
            strategy = defaultStrategy;
    }

    function createProposal(
        string memory title,
        address target,
        bytes32 contentHash,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory args,
        bool[] memory delegateCalls
    ) external validTarget(target) returns (uint256) {
        require(
            targets.length == values.length &&
                values.length == signatures.length &&
                values.length == args.length &&
                values.length == delegateCalls.length,
            Errors.GOV_INVALID_CREATION_DATA
        );

        _proposalCount++;
        Proposal storage p = _proposals[_proposalCount];
        p.strategy = _getStrategy(target);
        p.meta.target = target;
        p.meta.blockNo = block.number;

        uint power = p.votePower(msg.sender);
        {
            uint proposalCreationFee = p.strategy.creationFee(target);
            IERC20 _vics = vics();

            require(
                power * HUNDRED_PERCENT / p.totalVotePower() >= p.strategy.minPower(target),
                Errors.GOV_INSUFFICIENT_POWER_TO_CREATE_PROPOSAL
            );
            require(
                _vics.balanceOf(msg.sender) >= proposalCreationFee,
                Errors.GOV_INSUFFICIENT_VICS_TO_CREATE_PROPOSAL
            );

            _vics.transferFrom(msg.sender, address(this), proposalCreationFee);
            
        }

        p.meta = ProposalMeta(
            _proposalCount,
            ProposalState.Auto,
            uint64(block.timestamp),
            uint64(block.timestamp + p.strategy.duration(target)),
            0,
            contentHash,
            target,
            msg.sender,
            block.number,
            0,
            0,
            targets,
            values,
            signatures,
            args,
            delegateCalls
        );
        p.strategy.snapshot(target);
        _emitProposal(p, title);      
        _vote(p, msg.sender, power, true);
        return p.meta.proposalId;
    }

    function _emitProposal(Proposal storage p, string memory title) private {
        emit NewProposal( 
            p.meta.proposalId,
            title,
            p.meta.startedAt,
            p.meta.endedBy,
            p.meta.target,
            msg.sender,
            p.meta.contentHash
        );
    }

    function cancelProposal(uint256 proposalId)
        external
        validProposalId(proposalId)
    {
        Proposal storage p = _proposals[proposalId];
        require(
            msg.sender == p.meta.proposer || msg.sender == _guardian,
            Errors.GOV_REQUIRED_PROPOSER_OR_GUARDIAN
        );
        require(
            p.meta.state == ProposalState.Auto ||
                p.meta.state == ProposalState.Queued
        );

        _updateState(p, ProposalState.Canceled, bytes(''));
    }

    function vote(uint256 proposalId, bool support)
        public
        votingProposal(proposalId)
    {
        Proposal storage p = _proposals[proposalId];
        require(p.votes[msg.sender].power == 0, Errors.GOV_DUPLICATED_VOTE);

        uint256 power = p.votePower(msg.sender);
        require(power > 0, Errors.GOV_INSUFFICIENT_POWER_TO_VOTE);
        _vote(p, msg.sender, power, support);
    }

    function _vote(Proposal storage p, address account, uint power, bool support) private {
        p.votes[account].power = power;
        p.votes[account].support = support;

        bool passed = false;
        if (support) {
            p.meta.forVotes += power;
            passed = p.isPassedProposal();
        } else p.meta.againstVotes += power;
        emit Vote(account, p.meta.proposalId, power, support);
        if (passed) _updateState(p, ProposalState.Passed, bytes(''));
    }

    function unvote(uint256 proposalId) external votingProposal(proposalId) {
        Proposal storage p = _proposals[proposalId];
        uint256 currentPower = p.votes[msg.sender].power;
        if (currentPower == 0) return;

        if (p.votes[msg.sender].support) {
            p.meta.forVotes -= currentPower;
        } else p.meta.againstVotes -= currentPower;
        delete p.votes[msg.sender];
        emit Unvote(msg.sender, proposalId);
    }

    function updateState(uint256 proposalId, ProposalState state)
        external
        validProposalId(proposalId)
        onlyOperator
    {
        Proposal storage p = _proposals[proposalId];
        require(
            p.isOffchainProposal(),
            Errors.GOV_CANNOT_CHANGE_STATE_OF_ON_CHAIN_PROPOSAL
        );

        ProposalState currentState = p.state();
        require(
            state == ProposalState.Queued || state == ProposalState.Executed,
            Errors.GOV_INVALID_NEW_STATE
        );
        if (state == ProposalState.Queued)
            require(
                currentState == ProposalState.Passed,
                Errors.GOV_CANNOT_CHANGE_STATE_OF_CLOSED_PROPOSAL
            );
        if (state == ProposalState.Executed)
            require(
                currentState == ProposalState.Queued ||
                    currentState == ProposalState.Passed,
                Errors.GOV_CANNOT_CHANGE_STATE_OF_CLOSED_PROPOSAL
            );
        _updateState(p, state, bytes(''));
    }

    function queueProposal(uint256 proposalId)
        external
        validProposalId(proposalId)
    {
        Proposal storage p = _proposals[proposalId];
        require(
            p.state() == ProposalState.Passed,
            Errors.GOV_CAN_ONLY_QUEUE_PASSED_PROPOSAL
        );

        uint256 executionTime = block.timestamp + executor.getDelay();
        for (uint256 i = 0; i < p.meta.targets.length; i++) {
            _queueOrRevert(
                p.meta.targets[i],
                p.meta.values[i],
                p.meta.signatures[i],
                p.meta.args[i],
                executionTime,
                p.meta.delegateCalls[i]
            );
        }
        p.meta.executionTime = uint64(executionTime);
        _updateState(p, ProposalState.Queued, abi.encode(executionTime));
    }

    function executeProposal(uint256 proposalId)
        external
        payable
        validProposalId(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];
        for (uint256 i = 0; i < proposal.meta.targets.length; i++) {
            executor.executeTransaction{
                value: proposal.meta.values[i]
            }(
                proposal.meta.targets[i],
                proposal.meta.values[i],
                proposal.meta.signatures[i],
                proposal.meta.args[i],
                proposal.meta.executionTime,
                proposal.meta.delegateCalls[i]
            );
        }
        _updateState(proposal, ProposalState.Executed, bytes(''));
    }

    function _updateState(Proposal storage p, ProposalState state, bytes memory data) private {
        p.meta.state = state;
        emit StateChanged(p.meta.proposalId, state, data); 
    }

    function _getStrategy(address target) private view returns (IVoteStrategy strategy) {
        strategy = getStrategy(target);
        require(
            address(strategy) != address(0),
            Errors.GOV_DEFAULT_STRATEGY_IS_NOT_SET
        );
    }

    function _botManager() private view returns (IDABotManager) {
        return IDABotManager(config.addressOf(AddressBook.ADDR_BOT_MANAGER));
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory callData,
        uint256 executionTime,
        bool withDelegatecall
    ) internal {
        require(
            !executor.isActionQueued(
                keccak256(
                    abi.encode(
                        target,
                        value,
                        bytes4(keccak256(bytes(signature))),
                        callData,
                        executionTime,
                        withDelegatecall
                    )
                )
            ),
            Errors.GOV_DUPLICATED_ACTION
        );
        executor.queueTransaction(
            target,
            value,
            signature,
            callData,
            executionTime,
            withDelegatecall
        );
    }
}
