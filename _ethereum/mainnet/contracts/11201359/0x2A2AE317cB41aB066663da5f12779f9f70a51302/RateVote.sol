// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./Defensible.sol";
import "./IMiniMe.sol";
import "./ISporeToken.sol";
import "./IRateVoteable.sol";
import "./BannedContractList.sol";

/*
    Can be paused by the owner
    The mushroomFactory must be set by the owner before mushrooms can be harvested (optionally), and can be modified to use new mushroom spawning logic
*/
contract RateVote is ReentrancyGuardUpgradeSafe, Defensible {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public votingEnabledTime;

    mapping(address => uint256) lastVoted;

    struct VoteEpoch {
        uint256 startTime;
        uint256 activeEpoch;
        uint256 increaseVoteWeight;
        uint256 decreaseVoteWeight;
    }

    VoteEpoch public voteEpoch;
    uint256 public voteDuration;

    IMiniMe public enokiToken;
    IRateVoteable public pool;
    BannedContractList public bannedContractList;

    // In percentage: mul(X).div(100)
    uint256 public decreaseRateMultiplier;
    uint256 public increaseRateMultiplier;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _pool,
        address _enokiToken,
        uint256 _voteDuration,
        uint256 _votingEnabledTime,
        address _bannedContractList
    ) public virtual initializer {
        __ReentrancyGuard_init();

        pool = IRateVoteable(_pool);

        decreaseRateMultiplier = 50;
        increaseRateMultiplier = 150;

        votingEnabledTime = _votingEnabledTime;

        voteDuration = _voteDuration;

        enokiToken = IMiniMe(_enokiToken);

        voteEpoch = VoteEpoch({
            startTime: votingEnabledTime, 
            activeEpoch: 0, 
            increaseVoteWeight: 0, 
            decreaseVoteWeight: 0
        });

        bannedContractList = BannedContractList(_bannedContractList);
    }

    /*
        Votes with a given nonce invalidate other votes with the same nonce
        This ensures only one rate vote can pass for a given time period
    */

    function getVoteEpoch() external view returns (VoteEpoch memory) {
        return voteEpoch;
    }

    /* === Actions === */

    /// @notice Any user can vote once in a given voting epoch, with their balance at the start of the epoch
    function vote(uint256 voteId) external nonReentrant defend(bannedContractList) {
        require(now > votingEnabledTime, "Too early");
        require(now <= voteEpoch.startTime.add(voteDuration), "Vote has ended");
        require(lastVoted[msg.sender] < voteEpoch.activeEpoch, "Already voted");

        uint256 userWeight = enokiToken.balanceOfAt(msg.sender, voteEpoch.startTime);

        if (voteId == 0) {
            // Decrease rate
            voteEpoch.decreaseVoteWeight = voteEpoch.decreaseVoteWeight.add(userWeight);
        } else if (voteId == 1) {
            // Increase rate
            voteEpoch.increaseVoteWeight = voteEpoch.increaseVoteWeight.add(userWeight);
        } else {
            revert("Invalid voteId");
        }

        lastVoted[msg.sender] = voteEpoch.activeEpoch;

        emit Vote(msg.sender, voteEpoch.activeEpoch, userWeight, voteId);
    }

    /// @notice Once a vote has exceeded the duration, it can be resolved, implementing the decision and starting the next vote    
    function resolveVote() external nonReentrant defend(bannedContractList) {
        require(now >= voteEpoch.startTime.add(voteDuration), "Vote still active");
        uint256 decision = 0;

        if (voteEpoch.decreaseVoteWeight > voteEpoch.increaseVoteWeight) {
            // Decrease wins
            pool.changeRate(decreaseRateMultiplier);
        } else if (voteEpoch.increaseVoteWeight > voteEpoch.decreaseVoteWeight) {
            // Increase wins
            pool.changeRate(increaseRateMultiplier);
            decision = 1;
        } else {
            //else Tie, no rate change
            decision = 2;
        }

        emit VoteResolved(voteEpoch.activeEpoch, decision);

        voteEpoch.activeEpoch = voteEpoch.activeEpoch.add(1);
        voteEpoch.decreaseVoteWeight = 0;
        voteEpoch.increaseVoteWeight = 0;
        voteEpoch.startTime = now;

        emit VoteStarted(voteEpoch.activeEpoch, voteEpoch.startTime, voteEpoch.startTime.add(voteDuration));
    }

    /* ===Events=== */

    event Vote(address indexed user, uint256 indexed epoch, uint256 weight, uint256 indexed vote);
    event VoteResolved(uint256 indexed epoch, uint256 indexed decision);
    event VoteStarted(uint256 indexed epoch, uint256 startTime, uint256 endTime);
}
