// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./ICompetitionContract.sol";

interface IP2PCompetitionContract is Metadata {
    struct Competition {
        address player1;
        address player2;
        uint256 sportTypeAlias;
        Player playerWon;
        uint256 winnerReward;
        bool isAccept;
        bool resulted;
    }

    struct TotalBet {
        uint256 player1;
        uint256 player2;
    }

    struct Confirm {
        bool isConfirm;
        Player playerWon;
    }

    event NewP2PCompetition(
        address indexed player1,
        address indexed player2,
        bool isHead2Head
    );
    event PlaceBet(
        address indexed buyer,
        bool player1,
        bool player2,
        uint256 amount
    );
    event Accepted(address _player2, uint256 _timestamp);
    event P2PEndTime(uint256 endP2PTime);
    event ConfirmResult(address _player, bool _isWinner, uint256 _timestamp);
    event Voted(address bettor, uint256 timestamp);
    event SetResult(Player _player);

    function setBasic(
        address _player2,
        address _player1,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        address _sportManager,
        bool _head2head
    ) external;

    function setEntryFee(uint256 _entryFee) external;

    function setStartAndEndTimestamp(
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _startP2PTime,
        uint256 _minimumBetime
    ) external;

    function setDistanceTime(
        uint256 _p2pDistanceAcceptTime,
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime,
        uint256 _maximumRefundTime
    ) external;

    function acceptBetting(address user) external;

    function submitP2PCompetitionTimeOver() external;

    function confirmResult(bool _isWinner) external;

    function vote(
        address user,
        bool _player1Win,
        bool _player2Win
    ) external;
}
