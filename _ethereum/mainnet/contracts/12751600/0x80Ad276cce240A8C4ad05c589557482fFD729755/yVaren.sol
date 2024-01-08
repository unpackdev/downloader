// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IyVaren.sol";
import "./IERC677.sol";

contract yVaren is IyVaren, IERC677Receiver, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant override MAX_OPERATIONS = 10;
    IERC677 public immutable override VAREN;

    uint256 public override blocksForNoWithdrawalFee;
    uint256 public override earlyWithdrawalFeePercent = 5000; // 0.5%
    mapping(address => uint256) public override earlyWithdrawalFeeExpiry;
    address public override treasury;
    uint256 public override treasuryEarlyWithdrawalFeeShare = 1000000; // 100%
    mapping(address => uint256) public override voteLockAmount;
    mapping(address => uint256) public override voteLockExpiry;
    mapping(address => bool) public override hasActiveProposal;
    mapping(uint256 => Proposal) public override proposals;
    uint256 public override proposalCount;
    uint256 public override votingPeriodBlocks;
    uint256 public override minVarenForProposal = 1e17; // 0.1 Varen
    uint256 public override quorumPercent = 150000; // 15%
    uint256 public override voteThresholdPercent = 500000; // 50%
    uint256 public override executionPeriodBlocks;

    modifier onlyThis() {
        require(msg.sender == address(this), "yVRN: FORBIDDEN");
        _;
    }

    constructor(
        address _varen,
        address _treasury,
        uint256 _blocksForNoWithdrawalFee,
        uint256 _votingPeriodBlocks,
        uint256 _executionPeriodBlocks
    ) ERC20("Varen Staking Share", "yVRN") {
        require(
            _varen != address(0) && _treasury != address(0),
            "yVRN: ZERO_ADDRESS"
        );
        VAREN = IERC677(_varen);
        treasury = _treasury;
        blocksForNoWithdrawalFee = _blocksForNoWithdrawalFee;
        votingPeriodBlocks = _votingPeriodBlocks;
        executionPeriodBlocks = _executionPeriodBlocks;
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "yVRN: ZERO");
        require(VAREN.transferFrom(msg.sender, address(this), amount), 'yVRN: transferFrom failed');
        _stake(msg.sender, amount);
    }

    function _stake(address sender, uint256 amount) internal virtual {
        uint256 shares = totalSupply() == 0
            ? amount
            : (amount.mul(totalSupply())).div(VAREN.balanceOf(address(this)).sub(amount));
        _mint(sender, shares);
        earlyWithdrawalFeeExpiry[sender] = blocksForNoWithdrawalFee.add(
            block.number
        );
    }

    function onTokenTransfer(address sender, uint value, bytes memory) external override nonReentrant {                
      require(value > 0, "yVRN: ZERO");
      require(msg.sender == address(VAREN), 'yVRN: access denied');
      _stake(sender, value);
    }

    function withdraw(uint256 shares) external override nonReentrant {
        require(shares > 0, "yVRN: ZERO");
        _updateVoteExpiry();
        require(_checkVoteExpiry(msg.sender, shares), "voteLockExpiry");
        uint256 varenAmount = (VAREN.balanceOf(address(this))).mul(shares).div(
            totalSupply()
        );
        _burn(msg.sender, shares);
        if (block.number < earlyWithdrawalFeeExpiry[msg.sender]) {
            uint256 feeAmount = varenAmount.mul(earlyWithdrawalFeePercent) /
                1000000;
            VAREN.transfer(
                treasury,
                feeAmount.mul(treasuryEarlyWithdrawalFeeShare) / 1000000
            );
            varenAmount = varenAmount.sub(feeAmount);
        }
        VAREN.transfer(msg.sender, varenAmount);
    }

    function getPricePerFullShare() external view override returns (uint256) {
        return totalSupply() == 0 ? 0 : VAREN.balanceOf(address(this)).mul(1e18).div(totalSupply());
    }

    function getStakeVarenValue(address staker)
        external
        view
        override
        returns (uint256)
    {
        return
            (VAREN.balanceOf(address(this)).mul(balanceOf(staker))).div(
                totalSupply()
            );
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public override nonReentrant returns (uint256 id) {
        require(!hasActiveProposal[msg.sender], "yVRN: HAS_ACTIVE_PROPOSAL");
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "yVRN: PARITY_MISMATCH"
        );
        require(targets.length != 0, "yVRN: NO_ACTIONS");
        require(targets.length <= MAX_OPERATIONS, "yVRN: TOO_MANY_ACTIONS");
        require(
            (VAREN.balanceOf(address(this)).mul(balanceOf(msg.sender))).div(
                totalSupply()
            ) >= minVarenForProposal,
            "yVRN: INSUFFICIENT_VAREN_FOR_PROPOSAL"
        );
        uint256 endBlock = votingPeriodBlocks.add(block.number);
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposer = msg.sender;
        newProposal.endBlock = endBlock;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.totalForVotes = 0;
        newProposal.totalAgainstVotes = 0;
        newProposal.quorumVotes = VAREN.balanceOf(address(this)).mul(quorumPercent) / 1000000;
        newProposal.executed = false;

        hasActiveProposal[msg.sender] = true;
        proposalCount = proposalCount.add(1);

        emit ProposalCreated(
            id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            block.number,
            endBlock,
            description
        );
    }

    function _checkVoteExpiry(address _sender, uint256 _shares)
        private
        view
        returns (bool)
    {
        // ?????
        return _shares <= balanceOf(_sender).sub(voteLockAmount[_sender]);
    }

    function _updateVoteExpiry() private {
        if (block.number >= voteLockExpiry[msg.sender]) {
            voteLockExpiry[msg.sender] = 0;
            voteLockAmount[msg.sender] = 0;
        }
    }

    function vote(
        uint256 id,
        bool support,
        uint256 voteAmount
    ) external override nonReentrant {
        Proposal storage proposal = proposals[id];
        require(proposal.proposer != address(0), "yVRN: INVALID_PROPOSAL_ID");
        require(block.number < proposal.endBlock, "yVRN: VOTING_ENDED");
        require(voteAmount > 0, "yVRN: ZERO");
        require(
            voteAmount <= balanceOf(msg.sender),
            "yVRN: INSUFFICIENT_BALANCE"
        );
        _updateVoteExpiry();
        require(
            voteAmount >= voteLockAmount[msg.sender],
            "yVRN: SMALLER_VOTE"
        );
        if (
            (support && voteAmount == proposal.forVotes[msg.sender]) ||
            (!support && voteAmount == proposal.againstVotes[msg.sender])
        ) {
            revert("yVRN: SAME_VOTE");
        }
        if (voteAmount > voteLockAmount[msg.sender]) {
            voteLockAmount[msg.sender] = voteAmount;
        }

        voteLockExpiry[msg.sender] = proposal.endBlock >
            voteLockExpiry[msg.sender]
            ? proposal.endBlock
            : voteLockExpiry[msg.sender];

        if (support) {
            proposal.totalForVotes = proposal.totalForVotes.add(voteAmount).sub(
                proposal.forVotes[msg.sender]
            );
            proposal.forVotes[msg.sender] = voteAmount;
            // remove opposite votes
            proposal.totalAgainstVotes = proposal.totalAgainstVotes.sub(
                proposal.againstVotes[msg.sender]
            );
            proposal.againstVotes[msg.sender] = 0;
        } else {
            proposal.totalAgainstVotes = proposal
            .totalAgainstVotes
            .add(voteAmount)
            .sub(proposal.againstVotes[msg.sender]);
            proposal.againstVotes[msg.sender] = voteAmount;
            // remove opposite votes
            proposal.totalForVotes = proposal.totalForVotes.sub(
                proposal.forVotes[msg.sender]
            );
            proposal.forVotes[msg.sender] = 0;
        }

        emit VoteCast(msg.sender, id, support, voteAmount);
    }

    function executeProposal(uint256 id)
        external
        payable
        override
        nonReentrant
    {
        Proposal storage proposal = proposals[id];
        require(!proposal.executed, "yVRN: PROPOSAL_ALREADY_EXECUTED");
        {
            // check if proposal passed
            require(
                proposal.proposer != address(0),
                "yVRN: INVALID_PROPOSAL_ID"
            );
            require(
                block.number >= proposal.endBlock,
                "yVRN: PROPOSAL_IN_VOTING"
            );
            hasActiveProposal[proposal.proposer] = false;
            uint256 totalVotes = proposal.totalForVotes.add(
                proposal.totalAgainstVotes
            );
            if (
                totalVotes < proposal.quorumVotes ||
                proposal.totalForVotes <
                totalVotes.mul(voteThresholdPercent) / 1000000 ||
                block.number >= proposal.endBlock.add(executionPeriodBlocks) // execution period ended
            ) {
                return;
            }
        }

        bool success = true;
        uint256 remainingValue = msg.value;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            if (proposal.values[i] > 0) {
                require(
                    remainingValue >= proposal.values[i],
                    "yVRN: INSUFFICIENT_ETH"
                );
                remainingValue = remainingValue - proposal.values[i];
            }
            (success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                abi.encodePacked(
                    bytes4(keccak256(bytes(proposal.signatures[i]))),
                    proposal.calldatas[i]
                )
            );
            if (!success) break;
        }
        proposal.executed = true;

        emit ProposalExecuted(id, success);
    }

    function getVotes(uint256 proposalId, address voter)
        external
        view
        override
        returns (bool support, uint256 voteAmount)
    {
        support = proposals[proposalId].forVotes[voter] > 0;
        voteAmount = support
            ? proposals[proposalId].forVotes[voter]
            : proposals[proposalId].againstVotes[voter];
    }

    function getProposalCalls(uint256 proposalId)
        external
        view
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        targets = proposals[proposalId].targets;
        values = proposals[proposalId].values;
        signatures = proposals[proposalId].signatures;
        calldatas = proposals[proposalId].calldatas;
    }

    // SETTERS
    function setTreasury(address _treasury) external override onlyThis {
        treasury = _treasury;
    }

    function setTreasuryEarlyWithdrawalFeeShare(
        uint256 _treasuryEarlyWithdrawalFeeShare
    ) external override onlyThis {
        require(_treasuryEarlyWithdrawalFeeShare <= 1000000);
        treasuryEarlyWithdrawalFeeShare = _treasuryEarlyWithdrawalFeeShare;
    }

    function setBlocksForNoWithdrawalFee(uint256 _blocksForNoWithdrawalFee)
        external
        override
        onlyThis
    {
        // max 60 days
        require(_blocksForNoWithdrawalFee <= 345600);
        blocksForNoWithdrawalFee = _blocksForNoWithdrawalFee;
    }

    function setEarlyWithdrawalFeePercent(uint256 _earlyWithdrawalFeePercent)
        external
        override
        onlyThis
    {
        // max 100%
        require(_earlyWithdrawalFeePercent <= 1000000);
        earlyWithdrawalFeePercent = _earlyWithdrawalFeePercent;
    }

    function setVotingPeriodBlocks(uint256 _votingPeriodBlocks)
        external
        override
        onlyThis
    {
        // min 8 hours, max 2 weeks
        require(_votingPeriodBlocks >= 1920 && _votingPeriodBlocks <= 80640);
        votingPeriodBlocks = _votingPeriodBlocks;
    }

    function setMinVarenForProposal(uint256 _minVarenForProposal)
        external
        override
        onlyThis
    {
        // min 0.01 Varen, max 520 Varen (1% of total supply)
        require(
            _minVarenForProposal >= 1e16 && _minVarenForProposal <= 520 * (1e18)
        );
        minVarenForProposal = _minVarenForProposal;
    }

    function setQuorumPercent(uint256 _quorumPercent)
        external
        override
        onlyThis
    {
        // min 10%, max 33%
        require(_quorumPercent >= 100000 && _quorumPercent <= 330000);
        quorumPercent = _quorumPercent;
    }

    function setVoteThresholdPercent(uint256 _voteThresholdPercent)
        external
        override
        onlyThis
    {
        // min 50%, max 66%
        require(
            _voteThresholdPercent >= 500000 && _voteThresholdPercent <= 660000
        );
        voteThresholdPercent = _voteThresholdPercent;
    }

    function setExecutionPeriodBlocks(uint256 _executionPeriodBlocks)
        external
        override
        onlyThis
    {
        // min 8 hours, max 30 days
        require(
            _executionPeriodBlocks >= 1920 && _executionPeriodBlocks <= 172800
        );
        executionPeriodBlocks = _executionPeriodBlocks;
    }

    // ERC20 functions (overridden to add modifiers)
    function transfer(address recipient, uint256 amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        _updateVoteExpiry();
        require(_checkVoteExpiry(msg.sender, amount), "voteLockExpiry");
        super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override nonReentrant returns (bool) {
        _updateVoteExpiry();
        require(_checkVoteExpiry(sender, amount), "voteLockExpiry");
        super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        nonReentrant
        returns (bool)
    {
        super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        nonReentrant
        returns (bool)
    {
        super.decreaseAllowance(spender, subtractedValue);
    }
    function decimals() public view virtual override returns (uint8) {
        return VAREN.decimals();
    }
}
