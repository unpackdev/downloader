// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./ITomiGovernance.sol";
import "./SafeMath.sol";

/**
 * @title TomiBallot
 * @dev Implements voting process along with vote delegation
 */
contract TomiBallotRevenue {
    using SafeMath for uint;

    struct Participator {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }

    mapping(address => Participator) public participators;

    address public TOMI;
    address public governor;
    address public proposer;
    uint256 public endTime;
    uint256 public executionTime;
    bool public ended;
    string public subject;
    string public content;


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
        uint256 _endTime,
        uint256 _executionTime,
        address _governor,
        string memory _subject,
        string memory _content
    ) public {
        TOMI = _TOMI;
        proposer = _proposer;
        endTime = _endTime;
        executionTime = _executionTime;
        governor = _governor;
        subject = _subject;
        content = _content;
        createTime = block.timestamp;
    }


    /**
     * @dev Give 'participator' the right to vote on this ballot.
     * @param participator address of participator
     */
    function _giveRightToJoin(address participator) private returns (Participator storage) {
        require(block.timestamp < endTime, 'Ballot is ended');
        Participator storage sender = participators[participator];
        require(!sender.participated, 'You already participate in');
        sender.weight += IERC20(governor).balanceOf(participator);
        require(sender.weight != 0, 'Has no right to participate in');
        return sender;
    }

    function _stakeCollateralToJoin(uint256 collateral) private returns (bool) {
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
        Participator storage sender = _giveRightToJoin(msg.sender);
        require(to != msg.sender, 'Self-delegation is disallowed');

        while (participators[to].delegate != address(0)) {
            to = participators[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, 'Found loop in delegation');
        }
        sender.participated = true;
        sender.delegate = to;
        Participator storage delegate_ = participators[to];
        if (delegate_.participated) {
            // If the delegate already voted,
            // directly add to the number of votes
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
    //  */
    // function participate(uint256 collateral) public {
    //     if (collateral > 0) {
    //         require(_stakeCollateralToJoin(collateral), "TomiBallotRevenue:Fail due to stake TOMI as collateral!");
    //     }

    //     Participator storage sender = _giveRightToJoin(msg.sender);
    //     sender.participated = true;

    //     if (msg.sender != proposer) {
    //         total += sender.weight;
    //     }
    // }

    function participateByGovernor(address user) public onlyGovernor {
        Participator storage sender = _giveRightToJoin(user);
        sender.participated = true;

        if (user != proposer) {
            total += sender.weight;
        }
    }

    function end() public onlyGovernor returns (bool) {
        require(block.timestamp >= executionTime, 'ballot not yet ended');
        require(!ended, 'end has already been called');
        ended = true;
        return ended;
    }

    function weight(address user) external view returns (uint256) {
        Participator memory participator = participators[user];
        return participator.weight;
    }
}
