//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IP2PSports {
    event ChallengeCreated(uint256 challengeId, address token, address by);
    event ChallengeJoined(uint256 challengeId, uint256 amount, address by);
    event ChallengeResolved(uint256 challengeId, uint8 finalOutcome);
    event ChallengeCanceled(uint256 challengeId);

    event ChallengeFundsMoved(
        uint256 challengeId,
        address[] winners,
        uint256[] winnersProfit,
        address[] losers,
        uint256[] losersLoss
    );
    event UserWithdrawn(address token, uint256 amount, address by);

    event AdminReceived(uint256 challengeId, address token, uint256 amount);
    event AdminWithdrawn(address token, uint256 amount);

    enum ChallengeStatus {
        None,
        CanBeCreated,
        Betting,
        Awaiting,
        Canceled,
        ResolvedFor,
        ResolvedAgainst,
        ResolvedDraw
    }

    struct Challenge {
        address token;
        address[] usersFor;
        address[] usersAgainst;
        uint256 amountFor;
        uint256 amountAgainst;
        ChallengeStatus status;
    }

    struct UserBet {
        uint256 amount;
        uint8 decision;
    }

    struct Withdrawables {
        address token;
        uint256 amount;
    }

    struct AdminShareRule {
        uint256[] thresholds;
        uint256[] percentages;
    }
}
