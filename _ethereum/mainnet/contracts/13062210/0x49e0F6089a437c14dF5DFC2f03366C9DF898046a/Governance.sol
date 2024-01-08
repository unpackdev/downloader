// SPDX-License-Identifier: None
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IRewardDistributionRecipient.sol";
import "./VotingPowerFees.sol";
import "./VotingPowerFeesAndRewards.sol";
import "./IGovernance.sol";

contract Governance is VotingPowerFeesAndRewards {
    uint256 internal proposalCount;
    uint256 internal period = 3 days; // voting period in blocks ~ 17280 3 days for 15s/block
    uint256 internal minimum = 1e18;
    address internal governance;
    mapping(address => uint256) public voteLock; // period that your sake it locked to keep it for voting

    struct Proposal {
        uint256 id;
        address proposer;
        string ipfsCid;
        mapping(address => uint256) forVotes;
        mapping(address => uint256) againstVotes;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 start; // block start;
        uint256 end; // start + period
    }

    mapping(uint256 => Proposal) public proposals;

    event NewGovernanceAddress(address newGovernance);
    event NewMinimumValue(uint256 newMinimum);
    event NewPeriodValue(uint256 newPeriod);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /* Getters */

    /// @notice Returns proposalCount value.
    /// @return _proposalCount - uint256 value
    function getProposalCount() external view returns (uint256 _proposalCount) {
        return proposalCount;
    }

    /// @notice Returns period value.
    /// @dev Voting period in seconds
    /// @return _period - uint256 value
    function getPeriod() external view returns (uint256 _period) {
        return period;
    }

    /// @notice Returns minimum value.
    /// @dev minimum value is the value of the voting power which user must have to create proposal.
    /// @return _minimum - uint256 value
    function getMinimum() external view returns (uint256 _minimum) {
        return minimum;
    }

    /// @notice Returns governance address.
    /// @return _governance - address value
    function getGovernance() external view returns (address _governance) {
        return governance;
    }

    /// @notice Returns vote lockFor the specified user
    /// @param _user user for whom to get voteLock value.
    /// @return _voteLock - user's uint256 vote lock timestamp
    function getVoteLock(address _user) external view returns (uint256 _voteLock) {
        return voteLock[_user];
    }

    /// @notice Returns proposal's data with the specified proposal id.
    /// @param _proposalId - an index (count number) in the proposals mapping.
    /// @return id - proposal id
    /// @return proposer - proposal author address
    /// @return ipfsCid - ipfs cid of the proposal text
    /// @return totalForVotes - total amount of the voting power used for voting **for** proposal
    /// @return totalAgainstVotes - total amount of the voting power used for voting **against** proposal
    /// @return start - timestamp when proposal was created
    /// @return end - timestamp when proposal will be ended and disabled for voting (end = start + period)
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory ipfsCid,
            uint256 totalForVotes,
            uint256 totalAgainstVotes,
            uint256 start,
            uint256 end
        )
    {
        return (
            proposals[_proposalId].id,
            proposals[_proposalId].proposer,
            proposals[_proposalId].ipfsCid,
            proposals[_proposalId].totalForVotes,
            proposals[_proposalId].totalAgainstVotes,
            proposals[_proposalId].start,
            proposals[_proposalId].end
        );
    }

    /// @notice Returns proposals' data in the range of ids.
    /// @dev Revert will be thrown if _fromId >= _toId
    /// @param _fromId - proposal id/index at which to start extraction.
    /// @param _toId - proposal id/index *before* which to end extraction.
    /// @return id - proposals ids
    /// @return proposer - proposals authors addresses
    /// @return ipfsCid - ipfs cids of the proposals' texts
    /// @return totalForVotes - total amount of the voting power used for voting **for** proposals
    /// @return totalAgainstVotes - total amount of the voting power used for voting **against** proposals
    /// @return start - timestamps when proposals was created
    /// @return end - timestamps when proposals will be ended and disabled for voting (end = start + period)
    function getProposals(uint256 _fromId, uint256 _toId)
        external
        view
        returns (
            uint256[] memory id,
            address[] memory proposer,
            string[] memory ipfsCid,
            uint256[] memory totalForVotes,
            uint256[] memory totalAgainstVotes,
            uint256[] memory start,
            uint256[] memory end
        )
    {
        require(_fromId < _toId, "invalid range");
        uint256 numberOfProposals = _toId.sub(_fromId);
        id = new uint256[](numberOfProposals);
        proposer = new address[](numberOfProposals);
        ipfsCid = new string[](numberOfProposals);
        totalForVotes = new uint256[](numberOfProposals);
        totalAgainstVotes = new uint256[](numberOfProposals);
        start = new uint256[](numberOfProposals);
        end = new uint256[](numberOfProposals);
        for (uint256 i = 0; i < numberOfProposals; i = i.add(1)) {
            uint256 proposalId = _fromId.add(i);
            id[i] = proposals[proposalId].id;
            proposer[i] = proposals[proposalId].proposer;
            ipfsCid[i] = proposals[proposalId].ipfsCid;
            totalForVotes[i] = proposals[proposalId].totalForVotes;
            totalAgainstVotes[i] = proposals[proposalId].totalAgainstVotes;
            start[i] = proposals[proposalId].start;
            end[i] = proposals[proposalId].end;
        }
    }

    /// @notice Returns user's votes for the specified proposal id.
    /// @param _proposalId - an index (count number) in the proposals mapping.
    /// @param _user - user for which votes are requested
    /// @return forVotes - uint256 value
    function getProposalForVotes(uint256 _proposalId, address _user) external view returns (uint256 forVotes) {
        return (proposals[_proposalId].forVotes[_user]);
    }

    /// @notice Returns user's votes against the specified proposal id.
    /// @param _proposalId - an index (count number) in the proposals mapping.
    /// @param _user - user for which votes are requested
    /// @return againstVotes - uint256 value
    function getProposalAgainstVotes(uint256 _proposalId, address _user) external view returns (uint256 againstVotes) {
        return (proposals[_proposalId].againstVotes[_user]);
    }

    /// @notice Contract's constructor
    /// @param _stakingToken Sets staking token
    /// @param _feesToken Sets fees token
    /// @param _rewardsToken Sets rewards token
    /// @param _governance Sets governance address
    constructor(
        IERC20 _stakingToken,
        IERC20 _feesToken,
        IERC20 _rewardsToken,
        address _governance
    ) public VotingPowerFeesAndRewards(_stakingToken, _feesToken, _rewardsToken) {
        governance = _governance;
    }

    /* Administration functionality */

    /// @notice Fee collection for any other token
    /// @dev Transfers token to the governance address
    /// @param _token Token address
    /// @param _amount Amount for transferring to the governance
    function seize(IERC20 _token, uint256 _amount) external onlyGovernance {
        require(_token != feesToken, "feesToken");
        require(_token != rewardsToken, "rewardsToken");
        require(_token != stakingToken, "stakingToken");
        _token.safeTransfer(governance, _amount);
    }

    /// @notice Sets staking token.
    /// @param _stakingToken new staking token address.
    function setStakingToken(IERC20 _stakingToken) external onlyGovernance {
        stakingToken = _stakingToken;
    }

    /// @notice Sets governance.
    /// @param _governance new governance value.
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit NewGovernanceAddress(governance);
    }

    /// @notice Sets minimum.
    /// @param _minimum new minimum value.
    function setMinimum(uint256 _minimum) external onlyGovernance {
        minimum = _minimum;
        emit NewMinimumValue(minimum);
    }

    /// @notice Sets period.
    /// @param _period new period value.
    function setPeriod(uint256 _period) external onlyGovernance {
        period = _period;
        emit NewPeriodValue(period);
    }

    /* Proposals and voting functionality */
    /// @notice Creates new proposal without text, proposal settings are default on the contract.
    /// @param _ipfsCid ipfs cid of the proposal's text
    /// @dev User must have voting power >= minimum in order to create proposal.
    /// New proposal will be added to the proposals mapping.
    function propose(string calldata _ipfsCid) external {
        require(balanceOf(msg.sender) >= minimum, "<minimum");
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            ipfsCid: _ipfsCid,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            start: block.timestamp,
            end: period.add(block.timestamp)
        });

        voteLock[msg.sender] = period.add(block.timestamp);
    }

    function revokeProposal(uint256 _id) external {
        require(proposals[_id].proposer == msg.sender, "!proposer");
        proposals[_id].end = 0;
    }

    /// @notice Votes for the proposal using voting power.
    /// @dev After voting function withdraws fee for the user(if breaker == false).
    /// @param id proposal's id
    function voteFor(uint256 id) external {
        require(proposals[id].start < block.timestamp, "<start");
        require(proposals[id].end > block.timestamp, ">end");
        uint256 votes = balanceOf(msg.sender).sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(votes);
        proposals[id].forVotes[msg.sender] = balanceOf(msg.sender);
        // check that we will not reduce user's lock time (if he voted for another, newer proposal)
        if (voteLock[msg.sender] < proposals[id].end) {
            voteLock[msg.sender] = proposals[id].end;
        }
    }

    /// @notice Votes against the proposal using voting power.
    /// @dev After voting function withdraws fee for the user.
    /// @param id proposal's id
    function voteAgainst(uint256 id) external {
        require(proposals[id].start < block.timestamp, "<start");
        require(proposals[id].end > block.timestamp, ">end");
        uint256 votes = balanceOf(msg.sender).sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(votes);
        proposals[id].againstVotes[msg.sender] = balanceOf(msg.sender);

        if (voteLock[msg.sender] < proposals[id].end) {
            voteLock[msg.sender] = proposals[id].end;
        }
    }

    /* Staking, voting power functionality */
    /// @notice Stakes token and adds voting power (with a 1:1 ratio)
    /// @dev Token amount must be approved to this contract before staking.
    /// Before staking contract withdraws fee for the user.
    /// @param amount Amount to stake
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Withdraws token and subtracts voting power (with a 1:1 ratio)
    /// @dev Tokens must be unlocked to withdraw (voteLock[msg.sender] < block.timestamp).
    /// Before withdraw contract withdraws fee for the user.
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) nonReentrant public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(voteLock[msg.sender] < block.timestamp, "!locked");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }
}
