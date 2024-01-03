pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract Governance {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Rejected,
        Executable,
        Executed,
        Expired
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address[] contracts;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 expirationBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool canceled;
        bool executed;
        bool expedited;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    event ProposalCreated(
        uint256 indexed id,
        address proposer,
        address[] contracts,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string description,
        bool expedited
    );
    event ProposalCanceled(uint256 id);
    event ProposalExecuted(uint256 id);
    event VoteCast(
        address voter,
        uint256 proposalId,
        bool support,
        uint256 votes,
        bool isUpdate
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data
    );

    /* ========== STATE VARIABLES ========== */

    address public token;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lockedUntil;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    mapping(bytes32 => bool) public signatureWhitelist;

    bool private initialized;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _token
    ) public {
        require(!initialized, '!initialized');
        initialized = true;
        token = _token;
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lockedUntil(address account) external view returns (uint256) {
        if (block.number < _lockedUntil[account]) {
            return _lockedUntil[account];
        }
        return 0;
    }

    function proposerMinStaked() public pure returns (uint256) {
        return 10e18; // 0.01% of CAP
    }

    function proposalMaxOperations() public pure returns (uint256) {
        return 10;
    }

    function forVotesThreshold() public view virtual returns (uint256) {
        return IERC20(token).totalSupply().mul(4).div(100);
    }

    function forVotesExpeditedThreshold() public view virtual returns (uint256) {
        return IERC20(token).totalSupply().mul(15).div(100);
    }

    function votingPeriod() public pure virtual returns (uint256) {
        return 40320; // around 1 week
    }

    function executablePeriod() public pure virtual returns (uint256) {
        return 40320; // around 1 week
    }

    function proposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, '!id');
        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number < proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            if (proposal.expedited && proposal.forVotes > proposal.againstVotes && proposal.forVotes > forVotesExpeditedThreshold()) {
                return ProposalState.Executable;
            }
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < forVotesThreshold()) {
            return ProposalState.Rejected;
        } else if (block.number < proposal.expirationBlock) {
            return ProposalState.Executable;
        } else {
            return ProposalState.Expired;
        }
    }

    function proposalData(uint256 proposalId) external view returns (address[] memory contracts, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.contracts, proposal.values, proposal.signatures, proposal.calldatas);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeToVote(uint256 amount) public {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }

    function releaseStaked(uint256 amount) external {
        _unstake(msg.sender, amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function submitProposal(
        uint256 discoverabilityPeriod,
        address[] memory contracts,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        bool expedited
    ) external returns (uint256 id) {

        require(contracts.length != 0, '!empty');
        require(contracts.length <= proposalMaxOperations() && (!expedited || contracts.length < 4), '!max_operations');
        require(contracts.length == values.length && contracts.length == signatures.length && contracts.length == calldatas.length, '!mismatch');
        require(discoverabilityPeriod > 0, '!discoverability');

        address proposer = msg.sender;
        if (balanceOf(proposer) < proposerMinStaked()) {
            stakeToVote(proposerMinStaked().sub(balanceOf(proposer)));
        }

        uint256 startBlock = block.number.add(discoverabilityPeriod);
        uint256 endBlock = startBlock.add(votingPeriod());

        // lock staked funds until end of voting period
        _lockUntil(proposer, endBlock);

        // check urgency
        if (expedited) {
            _validateExpedition(signatures);
        }

        uint256 newProposalId = ++proposalCount;
        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = proposer;
        newProposal.contracts = contracts;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.expirationBlock = endBlock.add(executablePeriod());
        // skip forVotes and againstVotes (default 0)
        // skip canceled and executed (default false)
        if (expedited) newProposal.expedited = expedited;

        emit ProposalCreated(
            newProposalId,
            msg.sender,
            contracts,
            values,
            signatures,
            calldatas,
            description,
            expedited
        );

        return newProposalId;

    }

    function cancelProposal(uint256 proposalId) external {
        require(proposalState(proposalId) == ProposalState.Pending, '!state');
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer, '!authorized');
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function castVote(uint256 proposalId, bool support) external {
        require(proposalState(proposalId) == ProposalState.Active, '!voting_closed');

        address voter = msg.sender;

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];

        uint256 votes = balanceOf(voter);

        bool isUpdate;
        if (receipt.hasVoted) {
            isUpdate = true;
            // rollback previous vote
            if (receipt.support) {
                proposal.forVotes = proposal.forVotes.sub(receipt.votes);
            } else {
                proposal.againstVotes = proposal.againstVotes.sub(receipt.votes);
            }
        }

        // apply new vote
        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        _lockUntil(voter, proposal.endBlock);

        emit VoteCast(
            voter,
            proposalId,
            support,
            votes,
            isUpdate
        );

    }

    function executeProposal(uint256 proposalId) external payable {
        require(proposalState(proposalId) == ProposalState.Executable, '!not_executable');
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        uint256 length = proposal.contracts.length;
        for (uint256 i = 0; i < length; i++) {
            _executeTransaction(
                proposal.contracts[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i]
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function addSignaturesToWhitelist(string[] calldata signaturesToAdd) external onlyGovernance {
        for (uint256 i=0 ; i < signaturesToAdd.length; ++i) {
            bytes32 signature = keccak256(bytes(signaturesToAdd[i]));
            signatureWhitelist[signature] = true;
        }
    }

    function removeSignaturesFromWhitelist(string[] calldata signaturesToRemove) external onlyGovernance {
        for (uint256 i=0 ; i < signaturesToRemove.length; ++i) {
            bytes32 signature = keccak256(bytes(signaturesToRemove[i]));
            delete signatureWhitelist[signature];
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _stake(address account, uint256 amount) internal {
        require(account != address(this), '!allowed');
        _balances[account] = _balances[account].add(amount);
    }

    function _unstake(address account, uint256 amount) internal {
        require(block.number >= _lockedUntil[account], '!locked_till_expiry');
        _balances[account] = _balances[account].sub(amount, '!insufficient_funds');
    }

    function _lockUntil(address account, uint256 blockNumber) internal {
        if (_lockedUntil[account] <= blockNumber) {
            _lockedUntil[account] = blockNumber.add(1);
        }
    }

    function _executeTransaction(
        address contractAddress,
        uint256 value,
        string memory signature,
        bytes memory data
    ) internal {
        require(contractAddress != token, '!allowed');

        bytes32 txHash = keccak256(abi.encode(contractAddress, value, signature, data));

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success,) = contractAddress.call{value: value}(callData);
        require(success, '!failed');

        emit ExecuteTransaction(
            txHash,
            contractAddress,
            value,
            signature,
            data
        );
    }

    function _validateExpedition(
        string[] memory signatures
    ) internal view {
        uint256 i;
        for (; i < signatures.length; i++) {
            if (!signatureWhitelist[keccak256(bytes(signatures[i]))]) break;
        }

        require(i == signatures.length, '!error');
    }

    /* ========== MOFIFIERS ========== */

    modifier onlyGovernance() {
        require(msg.sender == address(this), '!authorized');
        _;
    }

}
