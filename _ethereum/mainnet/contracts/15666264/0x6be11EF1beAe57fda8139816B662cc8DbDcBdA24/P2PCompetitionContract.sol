// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./IP2PCompetitionContract.sol";
import "./CompetitionContract.sol";

/*
PCC01: Player address invalid
PPC02: Time invalid
PCC03: DistanceTime invalid
PCC04: Time was expired
PCC05: Only Player 2
PCC06: Lack of fee
PCC07: Had accepted
PCC08: Only Player1 or Player2
PCC09: Invalid length
PCC10: Invalid index
PCC11: Not enough Fee or EntryFee
PCC12: Only Player1 or Player2
PCC13: Time ivalid
PCC14: Only Player1 and Player2
PCC15: Confirmed
PCC16: Not votable
PCC17: Had resulted
PCC18: Required Open
PCC19: Required Lock
*/

contract P2PCompetitionContract is
    CompetitionContract,
    IP2PCompetitionContract
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    Competition public competition;

    uint256 public startP2PTime;
    uint256 public endP2PTime;
    uint256 public maximumRefundTime;
    bool public head2head;

    uint256 private distanceAcceptTime;
    uint256 private distanceConfirmTime;
    uint256 private distanceVoteTime;

    TotalBet public totalBet;
    mapping(address => bool) public voteResult;
    TotalBet public totalVoteResult;
    mapping(address => Confirm) public confirms;
    mapping(Player => address[]) public ticketSell;

    function getDistanceTime()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (distanceAcceptTime, distanceConfirmTime, distanceVoteTime);
    }

    function setBasic(
        address _player2,
        address _player1,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        address _sportManager,
        bool _head2head
    ) external override onlyConfigurator onlyLock {
        require(_player1 != address(0) && _player2 != address(0), "PCC01");
        require(_player1 != _player2, "PCC01");
        sportManager = ISportManager(_sportManager);
        competition = Competition(
            _player1,
            _player2,
            _sportTypeAlias,
            Player.NoPlayer,
            0,
            false,
            false
        );
        minEntrant = _minEntrant;
        totalFee = fee;
        head2head = _head2head;
        emit NewP2PCompetition(_player1, _player2, head2head);
    }

    function setEntryFee(uint256 _entryFee) external override onlyConfigurator {
        entryFee = _entryFee;
    }

    function setStartAndEndTimestamp(
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _startP2PTime,
        uint256 _minimumBetime
    ) external override onlyConfigurator {
        require(
            block.timestamp <= _startBetTime &&
                _startBetTime + _minimumBetime <= _endBetTime &&
                _endBetTime < _startP2PTime,
            "PPC02"
        );
        startBetTime = _startBetTime;
        endBetTime = _endBetTime;
        startP2PTime = _startP2PTime;
    }

    function setDistanceTime(
        uint256 _distanceAcceptTime,
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime,
        uint256 _maximumRefundTime
    ) external override onlyConfigurator {
        require(_distanceConfirmTime < _distanceVoteTime, "PCC03");
        distanceAcceptTime = _distanceAcceptTime;
        distanceVoteTime = _distanceVoteTime;
        distanceConfirmTime = _distanceConfirmTime;
        maximumRefundTime = _maximumRefundTime;
    }

    function acceptBetting(address player2)
        external
        override
        onlyLock
        onlyOwner
    {
        require(block.timestamp <= startBetTime + distanceAcceptTime, "PCC04");
        require(player2 == competition.player2, "PCC05");
        require(getTotalToken(tokenAddress) >= 2 * fee, "PCC06");
        require(!competition.isAccept, "PCC07");
        competition.isAccept = true;
        totalFee += fee;
        _start();
        emit Accepted(player2, block.timestamp);
    }

    function _start() private {
        status = Status.Open;
        emit Ready(block.timestamp, startBetTime, endBetTime);
    }

    function placeBet(address user, uint256[] memory betIndexs)
        external
        override
        onlyOpen
        betable(user)
        onlyOwner
    {
        if (head2head) {
            require(
                user == competition.player1 || user == competition.player2,
                "PCC08"
            );
        }
        require(betIndexs.length == 1, "PCC09");
        require(betIndexs[0] < 2, "PCC10");
        uint256 totalToken = getTotalToken(tokenAddress);
        uint256 totalEntryFee = (1 + totalBet.player1 + totalBet.player2) *
            entryFee;
        totalFee += fee;
        require(totalToken >= totalEntryFee + totalFee, "PCC11");
        _placeBet(user, betIndexs[0] == 0, betIndexs[0] == 1);
    }

    function _placeBet(
        address user,
        bool player1,
        bool player2
    ) private {
        if (player1) {
            ticketSell[Player.Player1].push(user);
            totalBet.player1++;
        } else {
            ticketSell[Player.Player2].push(user);
            totalBet.player2++;
        }
        listBuyer.push(user);
        betOrNotYet[user] = true;

        emit PlaceBet(user, player1, player2, entryFee + fee);
    }

    function submitP2PCompetitionTimeOver() external override {
        require(
            msg.sender == competition.player1 ||
                msg.sender == competition.player2,
            "PCC12"
        );

        require(block.timestamp > startP2PTime);

        if (endP2PTime == 0) {
            endP2PTime = block.timestamp;
        }

        emit P2PEndTime(endP2PTime);
    }

    function confirmResult(bool _isWinner) external override {
        require(block.timestamp > endP2PTime, "PCC13");
        require(block.timestamp <= endP2PTime + distanceConfirmTime, "PCC13");

        address _player1 = competition.player1;
        address _player2 = competition.player2;
        require(msg.sender == _player1 || msg.sender == _player2, "PCC14");
        require(!confirms[msg.sender].isConfirm, "PCC15");

        if (msg.sender == _player1) {
            if (_isWinner) {
                confirms[msg.sender] = Confirm(true, Player.Player1);
            } else {
                confirms[msg.sender] = Confirm(true, Player.Player2);
            }
        } else if (msg.sender == _player2) {
            if (_isWinner) {
                confirms[msg.sender] = Confirm(true, Player.Player2);
            } else {
                confirms[msg.sender] = Confirm(true, Player.Player1);
            }
        }

        if (confirms[_player1].isConfirm && confirms[_player2].isConfirm) {
            _setResult(_player1, _player2);
        }
        emit ConfirmResult(msg.sender, _isWinner, block.timestamp);
    }

    function _setResult(address _player1, address _player2)
        private
        returns (bool)
    {
        if (confirms[_player1].playerWon == confirms[_player2].playerWon) {
            competition.playerWon = confirms[_player1].playerWon;
            competition.resulted = true;
            emit SetResult(confirms[_player1].playerWon);
            return true;
        }
        return false;
    }

    function voteable(address user) public view returns (bool) {
        if (competition.resulted || !betOrNotYet[user] || voteResult[user]) {
            return false;
        }

        bool enoughEntrant = _checkEntrantCodition();
        if (!enoughEntrant) return false;

        address _player1 = competition.player1;
        address _player2 = competition.player2;
        if (!confirms[_player1].isConfirm || !confirms[_player2].isConfirm) {
            return
                block.timestamp > endP2PTime + distanceConfirmTime &&
                    block.timestamp < endP2PTime + distanceVoteTime
                    ? true
                    : false;
        } else {
            return
                confirms[_player1].playerWon != confirms[_player2].playerWon &&
                    block.timestamp < endP2PTime + distanceVoteTime
                    ? true
                    : false;
        }
    }

    function vote(
        address user,
        bool _player1Win,
        bool _player2Win
    ) external override onlyOwner {
        require(voteable(user), "PCC16");
        require(_player1Win != _player2Win, "PCC16");

        voteResult[user] = true;
        totalFee += fee;

        if (_player1Win) {
            totalVoteResult.player1++;
        } else {
            totalVoteResult.player2++;
        }
        emit Voted(user, block.timestamp);
        uint256 amountBuyer = listBuyer.length;
        if (amountBuyer > 1) {
            if (totalVoteResult.player1 > (amountBuyer / 2)) {
                _setResultAfterVote(Player.Player1);
            }

            if (totalVoteResult.player2 > (amountBuyer / 2)) {
                _setResultAfterVote(Player.Player2);
            }

            if (
                (totalVoteResult.player1 + totalVoteResult.player2) ==
                amountBuyer &&
                totalVoteResult.player1 == totalVoteResult.player2
            ) {
                _setResultAfterVote(Player.NoPlayer);
            }
        } else {
            if (_player1Win) {
                _setResultAfterVote(Player.Player1);
            } else {
                _setResultAfterVote(Player.Player2);
            }
        }
    }

    function _setResultAfterVote(Player _player) private {
        require(!competition.resulted, "PCC17");
        competition.resulted = true;
        competition.playerWon = _player;
        emit SetResult(_player); //success
    }

    function distributedReward() external override nonReentrant{
        if (!competition.isAccept) {
            require(
                block.timestamp >= startBetTime + distanceAcceptTime,
                "PCC18"
            );
        }
        bool enoughEntrant = _checkEntrantCodition();
        if (enoughEntrant) {
            if (competition.isAccept) {
                require(status == Status.Open, "PCC18");
            } else {
                require(status == Status.Lock, "PCC19");
            }
            if (!competition.resulted) {
                if (endP2PTime != 0) {
                    require(block.timestamp > endP2PTime + distanceVoteTime);
                } else {
                    require(block.timestamp > startP2PTime + maximumRefundTime);
                }
            }
        }

        address[] memory winners;
        uint256 ownerReward;
        uint256 winnerReward;
        uint256 totalEntryFee = (totalBet.player1 + totalBet.player2) *
            entryFee;

        if (!enoughEntrant || !competition.resulted) {
            status = Status.Non_Eligible;
            winners = listBuyer;
            winnerReward = totalEntryFee;
            ownerReward = totalFee;
        }
        if (enoughEntrant && competition.resulted) {
            status = Status.End;
            if (competition.playerWon == Player.Player1) {
                winners = ticketSell[Player.Player1];
            } else if (competition.playerWon == Player.Player2) {
                winners = ticketSell[Player.Player2];
            } else {
                winners = listBuyer;
            }

            if (winners.length > 0) {
                winnerReward = totalEntryFee;
                ownerReward = totalFee;
            } else {
                ownerReward = totalFee + totalEntryFee;
            }
        }
        competition.winnerReward = winnerReward;

        if (ownerReward > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, ownerReward);
        }
        if (winners.length > 0) {
            _sendRewardToWinner(winners, winnerReward);
        }

        uint256 remaining = getTotalToken(tokenAddress);
        if (remaining > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, remaining);
        }

        emit Close(block.timestamp, competition.winnerReward);
    }
}
