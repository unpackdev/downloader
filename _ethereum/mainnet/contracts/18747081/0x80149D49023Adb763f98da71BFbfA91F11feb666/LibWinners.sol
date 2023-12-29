// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./EnumerableMap.sol";
import "./LibShared.sol";
import "./Constants.sol";

library LibWinners {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using LibShared for uint32;

    uint256 private constant WINNER_OFFSET_ADDRESS = 96;
    uint256 private constant WINNER_OFFSET_ID = 32;
    uint32 private constant WINNER_MASK_ID = 0xFFFFFFFF;

    struct Winner {
        uint256 data;
        uint256 tokenId;
        uint256 prize;
    }

    struct Winners {
        mapping(uint256 => Winner) _winningData;
        EnumerableMap.UintToUintMap _gameWinners;
    }

    function recordWinner(Winners storage self,
        uint256 tokenId,
        uint256 prize,
        uint32 gameRound,
        address winnerAddress
    ) internal {
        _recordWinner(self, tokenId, prize, gameRound, winnerAddress);
    }

    function hasWinner(Winners storage self,
        uint256 tokenId
    ) internal view returns (bool) {
        return self._winningData[tokenId].data != 0;
    }

    function totalWinners(Winners storage self
    ) internal view returns (uint256) {
        return self._gameWinners.length();
    }

    function getWinnerAt(Winners storage self,
        uint256 index
    ) internal view returns (Winner memory) {
        (, uint256 tokenId) = self._gameWinners.at(index);
        return self._winningData[tokenId];
    }

    function getWinner(Winners storage self,
        uint32 gameNumber
    ) internal view returns (Winner memory) {
        return _getWinner(self, gameNumber);
    }

    function getWinnerId(Winners storage self,
        uint256 tokenId
    ) internal view returns (uint32) {
        return uint32((self._winningData[tokenId].data >> WINNER_OFFSET_ID) & WINNER_MASK_ID);
    }

    function packWinnerData(Winners storage self,
        uint32 gameRound,
        address winnerAddress
    ) internal view returns (uint256) {
        return
            (uint256(uint160(winnerAddress)) << WINNER_OFFSET_ADDRESS) |
            (self._gameWinners.length() << WINNER_OFFSET_ID) |
            uint256(gameRound);
    }

    function _recordWinner(Winners storage self,
        uint256 tokenId,
        uint256 prize,
        uint32 gameRound,
        address winnerAddress
    ) private {
        self._gameWinners.set(gameRound >> OFFSET_GAME_NUMBER, tokenId);
        self._winningData[tokenId] = Winner({
            data: packWinnerData(self, gameRound, winnerAddress),
            tokenId: tokenId,
            prize: prize
        });
    }

    function _getWinner(Winners storage self,
        uint32 gameNumber
    ) private view returns (Winner memory) {
        Winner memory winner;
        (bool isFound, uint256 tokenId) = self._gameWinners.tryGet(gameNumber);
        if (!isFound) return winner;
        winner = self._winningData[tokenId];
        if (tokenId >= FORFEIT_TOKEN_ID) winner.tokenId = 0;
        return winner;
    }
}
