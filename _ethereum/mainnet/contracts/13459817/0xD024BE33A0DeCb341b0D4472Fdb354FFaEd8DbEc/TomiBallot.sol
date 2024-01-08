// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./ITomiGovernance.sol";
import "./SafeMath.sol";

import "./console.sol";

/**
 * @title TomiBallot
 * @dev Implements voting process along with vote delegation
 */
contract TomiBallot {
    using SafeMath for uint;

    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote; // index of the voted proposal
    }

    mapping(address => Voter) public voters;
    mapping(uint256 => uint256) public proposals;

    address public TOMI;
    address public governor;
    address public proposer;
    uint256 public value;
    uint256 public endTime;
    uint256 public executionTime;
    bool public ended;
    string public subject;
    string public content;

    uint256 private constant NONE = 0;
    uint256 private constant YES = 1;
    uint256 private constant NO = 2;
    uint256 private constant MINIMUM_TOMI_TO_EXEC = 3 * (10 ** 18);

    uint256 public total;
    uint256 public createTime;

    modifier onlyGovernor() {
        require(msg.sender == governor, 'TomiBallot: FORBIDDEN');
        _;
    }

    /**
     * @dev Create a new ballot.
     */
    constructor(
        address _TOMI,
        address _proposer,
        uint256 _value,
        uint256 _endTime,
        uint256 _executionTime,
        address _governor,
        string memory _subject,
        string memory _content
    ) public {
        TOMI = _TOMI;
        proposer = _proposer;
        value = _value;
        endTime = _endTime;
        executionTime = _executionTime;
        governor = _governor;
        subject = _subject;
        content = _content;
        proposals[YES] = 0;
        proposals[NO] = 0;
        createTime = block.timestamp;
    }

    /**
     * @dev Give 'voter' the right to vote on this ballot.
     * @param voter address of voter
     */
    function _giveRightToVote(address voter) private returns (Voter storage) {
        require(block.timestamp < endTime, 'Ballot is ended');
        Voter storage sender = voters[voter];
        require(!sender.voted, 'You already voted');
        sender.weight += IERC20(governor).balanceOf(voter);
        require(sender.weight != 0, 'Has no right to vote');
        return sender;
    }

    function _stakeCollateralToVote(uint256 collateral) private returns (bool) {
        uint256 collateralRemain = IERC20(governor).balanceOf(msg.sender);
        uint256 collateralMore = collateral.sub(collateralRemain);
        require(IERC20(TOMI).allowance(msg.sender, address(this)) >= collateralMore, "TomiBallot:Collateral allowance is not enough to vote!");
        IERC20(TOMI).transferFrom(msg.sender, address(this), collateralMore);
        IERC20(TOMI).approve(governor, collateralMore);
        bool success = ITomiGovernance(governor).onBehalfDeposit(msg.sender, collateralMore);
        return success;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = _giveRightToVote(msg.sender);
        require(to != msg.sender, 'Self-delegation is disallowed');

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, 'Found loop in delegation');
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote] += sender.weight;
            total += msg.sender != proposer ? sender.weight: 0;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
            total += msg.sender != proposer ? sender.weight: 0;
        }
    }

    // /**
    //  * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
    //  * @param proposal index of proposal in the proposals array
    //  */
    // function vote(uint256 proposal, uint256 collateral) public {
    //     if (collateral > 0) {
    //         require(_stakeCollateralToVote(collateral), "TomiBallot:Fail due to stake TOMI as collateral!");
    //     }

    //     Voter storage sender = _giveRightToVote(msg.sender);
    //     require(proposal == YES || proposal == NO, 'Only vote 1 or 2');
    //     sender.voted = true;
    //     sender.vote = proposal;
    //     proposals[proposal] += sender.weight;
        
    //     if (msg.sender != proposer) {
    //         total += sender.weight;
    //     }
    // }

    function voteByGovernor(address user, uint256 proposal) public onlyGovernor {
        Voter storage sender = _giveRightToVote(user);
        require(proposal == YES || proposal == NO, 'Only vote 1 or 2');
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal] += sender.weight;
        
        if (user != proposer) {
            total += sender.weight;
        }
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view returns (uint256) {
        if (proposals[YES] > proposals[NO]) {
            return YES;
        } else if (proposals[YES] < proposals[NO]) {
            return NO;
        } else {
            return NONE;
        }
    }

    function result() public view returns (bool) {
        uint256 winner = winningProposal();
        if (winner == YES && total >= MINIMUM_TOMI_TO_EXEC) {
            return true;
        }
        return false;
    }

    function end() public onlyGovernor returns (bool) {
        require(block.timestamp >= executionTime, 'ballot not yet ended');
        require(!ended, 'end has already been called');
        ended = true;
        return result();
    }

    function weight(address user) external view returns (uint256) {
        Voter memory voter = voters[user];
        return voter.weight;
    }
}
