// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "./LibBitSet.sol";
import "./LibShared.sol";
import "./Constants.sol";

enum GameStatus {
    MINTING,
    PAUSING,
    PENDING,
    RUNNING,
    FORFEIT,
    WINNERS
}

library LibGame {
    using LibBitSet for LibBitSet.Set;
    using LibShared for uint256;
    using LibShared for uint32;

    uint256 private constant GAME_OFFSET_RESET_TIME = 112;
    uint256 private constant GAME_OFFSET_PAUSE_TIME = 144;
    uint256 private constant GAME_OFFSET_ROUND_TIME = 176;
    uint256 private constant GAME_OFFSET_MULTI_USER = 208;
    uint256 private constant GAME_OFFSET_GAME_STATE = 216;
    uint256 private constant INFO_OFFSET_GAME_STATE = 0;
    uint256 private constant INFO_OFFSET_BLOCK_TIME = 8;
    uint256 private constant INFO_OFFSET_RESET_TIME = 40;
    uint256 private constant INFO_OFFSET_PAUSE_TIME = 72;
    uint256 private constant INFO_OFFSET_ROUND_TIME = 104;
    uint256 private constant INFO_OFFSET_PRIZE_POOL = 136;
    uint256 private constant INFO_OFFSET_GAMESTATUS = 168;
    uint256 private constant INFO_OFFSET_BURN_COUNT = 176;
    uint256 private constant INFO_OFFSET_SAFE_COUNT = 192;
    uint256 private constant INFO_OFFSET_LIVE_COUNT = 208;
    uint256 private constant INFO_OFFSET_GAME_ROUND = 224;
    uint256 private constant MASK_MULTI = 0xFF;
    uint256 private constant MASK_STATE = 0xFF;
    uint256 private constant MASK_BURNED = 0xFFFF;
    uint256 private constant MASK_TIMESTAMP = 0xFFFFFFFF;
    uint256 private constant MASK_PENDING = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    struct Game {
        uint256 data;
        uint256 prizePool;
        LibBitSet.Set[2] tokens;
    }

    event GameStart(uint32 indexed gameRound);
    event GameOver(uint32 indexed gameRound, address winner);
    event GameCancelled(uint32 indexed gameRound, uint256 mintCount);
    event RoundStart(uint32 indexed gameRound);

    function nextGameRound(Game storage self
    ) internal view returns (uint32) {
       return _nextGameRound(self.data);
    }

    function initGame(Game storage self,
        uint256 startTokenId
    ) internal returns (uint32) {
        return _initGame(self, self.data, startTokenId);
    }

    function startGame(Game storage self
    ) internal {
        _startGame(self);
    }

    function startRound(Game storage self,
        uint32 gameRound
    ) internal {
        _startRound(self, gameRound);
    }

    function resetGame(Game storage self,
        uint256 startTokenId
    ) internal returns (uint32) {
        return _resetGame(self, self.data, startTokenId);
    }

    function cancelGame(Game storage self,
        uint256 startTokenId
    ) internal {
        uint256 data = self.data;
        emit GameCancelled(data.getGameRound(), data.getLiveCount());
        _resetGame(self, data, startTokenId);
    }

    function getStatus(Game storage self
    )  internal view returns (GameStatus) {
        return _getStatus(self, self.data);
    }

    function getStatus(Game storage self,
        uint256 data
    )  internal view returns (GameStatus) {
        return _getStatus(self, data);
    }

    function isGameOver(Game storage self,
        uint32 gameRound
    ) internal view returns (uint256) {
        return _isGameOver(self, gameRound);
    }

    function liveTokenCount(Game storage self
    ) internal view returns (uint16) {
        return _liveTokenCount(self, self.data);
    }

    function virtualLiveTokenCount(Game storage self
    ) internal view returns (uint16) {
        return _virtualLiveTokenCount(self, self.data);
    }

    function virtualSafeTokenCount(Game storage self
    ) internal view returns (uint16) {
        return _virtualSafeTokenCount(self, self.data);
    }

    function virtualBurnTokenCount(Game storage self
    ) internal view returns (uint16) {
        return _virtualBurnTokenCount(self, self.data);
    }

    function getTokenStatus(Game storage self,
        uint256 tokenId
    ) internal view returns (uint8) {
        return _getTokenStatus(self, tokenId);
    }

    function virtualResetEndTime(Game storage self,
        GameStatus status
    ) internal view returns (uint32) {
        return _virtualResetEndTime(self.data, status);
    }

    function gameInfo(Game storage self
    ) internal view returns (uint256) {
       return _gameInfo(self);
    }

    function _nextGameRound(
        uint256 data
    ) private pure returns (uint32) {
        unchecked {
            return (data.getGameRound() + (uint32(1) << OFFSET_GAME_NUMBER)) | 1;
        }
    }

    function _initGame(Game storage self,
        uint256 data,
        uint256 startTokenId
    ) private returns (uint32)  {
        uint256 gameRound = _nextGameRound(data);
        self.data = gameRound << DATA_OFFSET_GAME_ROUND;
        self.tokens[0].offset = self.tokens[1].offset = startTokenId;
        return uint32(gameRound);
    }

    function _startGame(Game storage self
    ) private {
        uint256 data = self.data;
        data = _clearEndTimes(data) | (GAME_STATE_STARTED << GAME_OFFSET_GAME_STATE);
        self.data = data;
        emit GameStart(data.getGameRound());
    }

    function _startRound(Game storage self,
        uint32 gameRound
    ) private {
        uint256 data = self.data;
        if (block.timestamp <= roundEndTime(data)) return;
        unchecked {
            LibBitSet.Set[2] storage tokens = self.tokens;
            if (data.getGameRound() != gameRound) {
                uint8 prevIndex = data.getLiveIndex();
                data = data.addBurnCount(uint16(tokens[prevIndex].length()));
                delete tokens[prevIndex];
                tokens[prevIndex].offset = tokens[1 - prevIndex].offset;
                data = data.setGameRound(gameRound);
            }
            data = _clearMultiUser(data);
            self.data = setRoundEndTime(data, block.timestamp +
                LibShared.max(tokens[gameRound.liveIndex()].length() << TOKEN_DELAY_ROUND, MIN_ROUND_TIME));
            emit RoundStart(gameRound);
        }
    }

    function _resetGame(Game storage self,
        uint256 data,
        uint256 startTokenId
    ) private returns (uint32) {
        self.prizePool = 0;
        delete self.tokens;
        self.tokens[0].offset = self.tokens[1].offset = startTokenId;
        return _initGame(self, data.clearRound(), startTokenId);
    }

    function _getStatus(Game storage self,
        uint256 data
    ) private view returns (GameStatus) {
        uint256 pauseTime = pauseEndTime(data);
        uint256 resetTime = resetEndTime(data);
        if (block.timestamp > pauseTime && (resetTime > 0 && block.timestamp <= resetTime)) {
            return GameStatus.WINNERS;
        }
        if (gameState(data) == GAME_STATE_OFFLINE) {
            return GameStatus.MINTING;
        }
        if (_isPending(data)) {
            return GameStatus.PENDING;
        }
        uint256 roundTime = roundEndTime(data);
        if (roundTime != 0 && block.timestamp <= roundTime && self.tokens[data.getLiveIndex()].length() > 1) {
            return GameStatus.RUNNING;
        }
        if (isMultiUser(data)) {
            if ((roundTime == 0 || block.timestamp > roundTime) && (pauseTime > 0 && block.timestamp <= pauseTime)) {
                return GameStatus.PAUSING;
            }
            return (pauseTime > 0 && block.timestamp > pauseTime && roundTime < pauseTime) ?
                GameStatus.PENDING : GameStatus.RUNNING;
        }
        return self.tokens[data.getSafeIndex()].length() == 0 ?
            GameStatus.FORFEIT : GameStatus.WINNERS;
    }

    function _liveTokenCount(Game storage self,
        uint256 data
    ) private view returns (uint16) {
        return uint16(self.tokens[data.getLiveIndex()].length());
    }

    function _safeTokenCount(Game storage self,
        uint256 data
    ) private view returns (uint16) {
        return uint16(self.tokens[data.getSafeIndex()].length());
    }

    function _virtualLiveTokenCount(Game storage self,
        uint256 data
    ) private view returns (uint16) {
        if ((gameState(data) == GAME_STATE_OFFLINE) ||
            (block.timestamp <= roundEndTime(data)) ||
            _isPending(data)) {
            return _liveTokenCount(self, data);
        }
        return 0;
    }

    function _virtualSafeTokenCount(Game storage self,
        uint256 data
    ) private view returns (uint16) {
        if (gameState(data) == GAME_STATE_OFFLINE) {
            return 0;
        }
        return _safeTokenCount(self, data);
    }

    function _virtualBurnTokenCount(Game storage self,
        uint256 data
    ) private view returns (uint16) {
        uint16 burnCount = data.getBurnCount();
        if ((gameState(data) == GAME_STATE_STARTED) &&
            (block.timestamp > roundEndTime(data)) &&
            !_isPending(data)) {
            burnCount += _liveTokenCount(self, data);
        }
        return burnCount;
    }

    function _getTokenStatus(Game storage self,
        uint256 tokenId
    ) private view returns (uint8) {
        if (tokenId < self.tokens[0].offset) return TOKEN_STATUS_BANNED;
        uint256 data = self.data;
        if (gameState(data) == GAME_STATE_OFFLINE) return TOKEN_STATUS_QUEUED;
        if (_virtualLiveTokenCount(self, data) > 1 && self.tokens[data.getLiveIndex()].contains(tokenId)) {
            return TOKEN_STATUS_ACTIVE;
        }
        return (self.tokens[data.getSafeIndex()].contains(tokenId)) ? TOKEN_STATUS_SECURE : TOKEN_STATUS_BURNED;
    }

    function _isGameOver(Game storage self,
        uint32 gameRound
    ) private view returns (uint256) {
        GameStatus status = _getStatus(self, self.data);
        if (status < GameStatus.FORFEIT) return LibBitSet.NOT_FOUND;
        if (status == GameStatus.FORFEIT) return FORFEIT_TOKEN_ID + (gameRound >> OFFSET_GAME_NUMBER);
        return self.tokens[gameRound.safeIndex()].findFirst();
    }

    function _virtualResetEndTime(
        uint256 data,
        GameStatus status
    ) private pure returns (uint32) {
        uint32 resetTime = resetEndTime(data);
        if (status > GameStatus.RUNNING && resetTime == 0) {
            return roundEndTime(data) + MIN_RESET_TIME;
        }
        return resetTime;
    }

    function _gameInfo(Game storage self
    ) private view returns (uint256) {
        uint256 data = self.data;
        GameStatus status = _getStatus(self, data);
        uint256 prizePool = self.prizePool / WEI;
        uint32 gameRound = data.getGameRound();
        uint256 state = gameState(data);
        uint32 roundTime = roundEndTime(data);
        uint32 pauseTime = pauseEndTime(data);
        uint32 resetTime = resetEndTime(data);
        uint16 liveCount = _virtualLiveTokenCount(self, data);
        uint16 safeCount = _virtualSafeTokenCount(self, data);
        uint16 burnCount = _virtualBurnTokenCount(self, data);
        if (status == GameStatus.RUNNING) {
            pauseTime = resetTime = 0;
        }
        if ((status == GameStatus.PAUSING || status == GameStatus.PENDING) && pauseTime != 0) {
            unchecked { gameRound++; }
            (liveCount, safeCount) = (safeCount, 0);
            roundTime = resetTime = 0;
            if (block.timestamp > pauseTime) {
                pauseTime = 0;
            }
        }
        if (status == GameStatus.PENDING) {
            roundTime = pauseTime = resetTime = 0;
        }
        if (status > GameStatus.RUNNING) {
            roundTime = pauseTime = 0;
            if (resetTime == 0) {
                resetTime = _virtualResetEndTime(data, status);
                state = GAME_STATE_VIRTUAL;
            }
            if (resetTime != 0 && block.timestamp > resetTime) {
                status = GameStatus.MINTING;
                gameRound = _nextGameRound(data);
                prizePool = roundTime = pauseTime = liveCount = safeCount = burnCount = 0;
            }
        }
        uint256 info = (state << INFO_OFFSET_GAME_STATE);
        info |=
            (uint256(block.timestamp) << INFO_OFFSET_BLOCK_TIME) |
            (uint256(resetTime) << INFO_OFFSET_RESET_TIME) |
            (uint256(pauseTime) << INFO_OFFSET_PAUSE_TIME) |
            (uint256(roundTime) << INFO_OFFSET_ROUND_TIME) |
            (prizePool << INFO_OFFSET_PRIZE_POOL) |
            (uint256(status) << INFO_OFFSET_GAMESTATUS);
        info |=
            (uint256(burnCount) << INFO_OFFSET_BURN_COUNT) |
            (uint256(safeCount) << INFO_OFFSET_SAFE_COUNT) |
            (uint256(liveCount) << INFO_OFFSET_LIVE_COUNT) |
            (uint256(gameRound) << INFO_OFFSET_GAME_ROUND);
        return info;
    }

    function gameState(uint256 data) internal pure returns (uint8) {
        return uint8((data >> GAME_OFFSET_GAME_STATE) & MASK_STATE);
    }

    function setMultiUser(uint256 data) internal pure returns (uint256) {
        return _clearMultiUser(data) | (1 << GAME_OFFSET_MULTI_USER);
    }

    function isMultiUser(uint256 data) internal pure returns (bool) {
        return uint8((data >> GAME_OFFSET_MULTI_USER) & MASK_MULTI) == 1;
    }

    function hasPauseExpired(uint256 data) internal view returns (bool) {
        uint32 pauseTime = pauseEndTime(data);
        return (pauseTime > 0 && block.timestamp > pauseTime && roundEndTime(data) < pauseTime);
    }

    function roundEndTime(uint256 data) internal pure returns (uint32) {
        return uint32((data >> GAME_OFFSET_ROUND_TIME) & MASK_TIMESTAMP);
    }

    function setRoundEndTime(uint256 data, uint256 time) internal pure returns (uint256) {
        return clearRoundEndTime(data) | (time << GAME_OFFSET_ROUND_TIME);
    }

    function clearRoundEndTime(uint256 data) internal pure returns (uint256) {
        return (data & ~(MASK_TIMESTAMP << GAME_OFFSET_ROUND_TIME));
    }

    function pauseEndTime(uint256 data) internal pure returns (uint32) {
        return uint32((data >> GAME_OFFSET_PAUSE_TIME) & MASK_TIMESTAMP);
    }

    function setPauseEndTime(uint256 data, uint256 time) internal pure returns (uint256) {
        return clearPauseEndTime(data) | (time << GAME_OFFSET_PAUSE_TIME);
    }

    function clearPauseEndTime(uint256 data) internal pure returns (uint256) {
        return (data & ~(MASK_TIMESTAMP << GAME_OFFSET_PAUSE_TIME));
    }

    function resetEndTime(uint256 data) internal pure returns (uint32) {
        return uint32((data >> GAME_OFFSET_RESET_TIME) & MASK_TIMESTAMP);
    }

    function setResetEndTime(uint256 data, uint256 time) internal pure returns (uint256) {
        return clearPauseEndTime(data) | (time << GAME_OFFSET_RESET_TIME);
    }

    function clearResetEndTime(uint256 data) internal pure returns (uint256) {
        return (data & ~(MASK_TIMESTAMP << GAME_OFFSET_RESET_TIME));
    }

    function _clearMultiUser(uint256 data) private pure returns (uint256) {
        return (data & ~(MASK_MULTI << GAME_OFFSET_MULTI_USER));
    }

    function _clearEndTimes(uint256 data) private pure returns (uint256) {
        return (data & ~(MASK_PENDING << GAME_OFFSET_RESET_TIME));
    }

    function _isPending(uint256 data) private pure returns (bool) {
        return ((data >> GAME_OFFSET_RESET_TIME) & MASK_PENDING) == 0;
    }
}
