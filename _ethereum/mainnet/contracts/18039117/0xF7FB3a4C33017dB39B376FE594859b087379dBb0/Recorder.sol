// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   ██████╗░███████╗░█████╗░░█████╗░██████╗░██████╗░███████╗██████╗░   //
//   ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗   //
//   ██████╔╝█████╗░░██║░░╚═╝██║░░██║██████╔╝██║░░██║█████╗░░██████╔╝   //
//   ██╔══██╗██╔══╝░░██║░░██╗██║░░██║██╔══██╗██║░░██║██╔══╝░░██╔══██╗   //
//   ██║░░██║███████╗╚█████╔╝╚█████╔╝██║░░██║██████╔╝███████╗██║░░██║   //
//   ╚═╝░░╚═╝╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝   //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

import "./Owned.sol";
import "./Strings.sol";

import "./IRecorder.sol";
import "./IRenderer.sol";

/// @title Recorder
/// @author swaHili (swa.eth)
/// @notice Records player stats for Roshambo
contract Recorder is Owned, IRecorder {
    using Strings for uint256;
    string public name;
    string public symbol;
    mapping(address => Record) public records;

    constructor() Owned(msg.sender) {
        name = "Recorder";
        symbol = "RECORDER";
    }

    function setRecord(
        uint40 _gameId,
        uint72 _pot,
        uint8 _totalRounds,
        uint8 _currentRound,
        address _winner,
        address _loser
    ) external onlyOwner {
        Record storage winner = records[_winner];
        Record storage loser = records[_loser];
        winner.games.push(_gameId);
        loser.games.push(_gameId);
        uint128 wager = uint128(_pot) / 2;
        uint8 winnerRoundsWon = (_totalRounds / 2) + 1;
        uint8 loserRoundsWon = _currentRound - winnerRoundsWon;

        winner.seriesWon++;
        winner.roundsWon += winnerRoundsWon;
        winner.roundsLost += loserRoundsWon;
        winner.wagers += wager;
        winner.profits += wager;

        emit SetRecord(
            _winner,
            winner.playerId,
            _gameId,
            winner.roundsWon,
            winner.seriesWon,
            winner.roundsLost,
            winner.seriesLost,
            winner.wagers,
            winner.profits
        );

        loser.seriesLost++;
        loser.roundsWon += loserRoundsWon;
        loser.roundsLost += winnerRoundsWon;
        loser.wagers += wager;

        emit SetRecord(
            _loser,
            loser.playerId,
            _gameId,
            loser.roundsWon,
            loser.seriesWon,
            loser.roundsLost,
            loser.seriesLost,
            loser.wagers,
            loser.profits
        );
    }

    function getGameIds(address _player) external view returns (uint40[] memory) {
        Record memory record = records[_player];
        return record.games;
    }

    function adjustRake(uint256 _pot, uint256 _rake) external pure returns (uint256 adjusted) {
        if (_pot > 10 ether) {
            adjusted = _rake - ((_rake * 50) / 100);
        } else if (_pot >= 5 ether) {
            adjusted = _rake - ((_rake * 40) / 100);
        } else if (_pot >= 2.5 ether) {
            adjusted = _rake - ((_rake * 30) / 100);
        } else if (_pot >= 1 ether) {
            adjusted = _rake - ((_rake * 20) / 100);
        } else if (_pot >= 0.5 ether) {
            adjusted = _rake - ((_rake * 10) / 100);
        } else {
            adjusted = _rake;
        }
    }

    function weiToEth(uint256 _weiAmount) public pure returns (string memory) {
        uint256 ethAmount = (_weiAmount * 1e4) / 1e18;
        string memory base = (ethAmount / 10000).toString();
        string memory decimal = (ethAmount % 10000).toString();

        // Adds leading zeros to the decimal part, if needed
        while (bytes(decimal).length < 4) {
            decimal = string(abi.encodePacked("0", decimal));
        }

        // Removes trailing zeros from the decimal part
        bytes memory decimalBytes = bytes(decimal);
        int256 endIndex = int256(decimalBytes.length);
        for (int256 i = endIndex - 1; i >= 0; i--) {
            if (decimalBytes[uint256(i)] != "0") {
                endIndex = i + 1;
                break;
            }
            // In case we have a string "0000"
            if (i == 0) endIndex = 0;
        }

        bytes memory resultBytes = new bytes(uint256(endIndex));
        for (uint256 i; i < uint256(endIndex); ++i) {
            resultBytes[i] = decimalBytes[i];
        }
        decimal = string(resultBytes);

        // If the decimal part is not empty, append it to the base part
        if (bytes(decimal).length > 0) {
            return string(abi.encodePacked(base, ".", decimal));
        } else {
            return base;
        }
    }
}
