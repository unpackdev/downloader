// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./LibShared.sol";
import "./LibGame.sol";
import "./Constants.sol";

enum UserStatus {
    EXPIRED,
    STALE,
    VALID
}

library LibUser {
    using LibGame for LibGame.Game;
    using LibShared for uint256;
    using LibGame for uint256;
    using LibShared for uint32;

    uint256 private constant COMMIT_WINDOW = 120;
    uint256 private constant OFFSET_COMMIT = 32;
    uint256 private constant USER_OFFSET_OWNER_ADDR = 64;
    uint256 private constant INFO_OFFSET_IS_PLAYING = 0;
    uint256 private constant INFO_OFFSET_PERMISSION = 1;
    uint256 private constant INFO_OFFSET_BURN_COUNT = 8;
    uint256 private constant INFO_OFFSET_SAFE_COUNT = 24;
    uint256 private constant INFO_OFFSET_LIVE_COUNT = 40;
    uint8 private constant PERM_DENIED = 0x0;
    uint8 private constant PERM_COMMIT = 0x1;
    uint8 private constant PERM_REVEAL = 0x2;
    uint8 private constant PERM_CLAIMS = 0x4;

    struct User {
        uint256 data;
        uint256 lastCommit;
    }

    error ErrorCommitDenied();
    error ErrorCommitPrevious();
    error ErrorRevealDenied();
    error ErrorRevealLength();
    error ErrorRevealMismatch();

    function isInvalid(User storage self,
        uint32 gameRound
    ) internal view returns (bool) {
        uint256 data = self.data;
        unchecked {
            return (
                (data == 0) ||
                (gameRound - data.getGameRound() >= 2) ||
                (data.getLiveCount() == 0 && data.getSafeCount() == 0)
            );
        }
    }

    function initUser(User storage self,
        address addy,
        uint32 gameRound
    ) internal returns (uint256) {
        return _initUser(self, addy, gameRound);
    }

    function isExpired(User storage self,
        uint32 gameRound
    ) internal view returns (bool) {
        return _isExpired(self, gameRound);
    }

    function commit(User storage self,
        uint32 gameRound,
        GameStatus status,
        bytes32 hash
    ) internal {
        _commit(self, gameRound, status, hash);
    }

    function reveal(User storage self,
        uint32 gameRound,
        GameStatus status,
        bytes memory secret
    ) internal {
        _reveal(self, gameRound, status, secret);
    }

    function getUserInfo(User storage self,
        LibGame.Game storage game
    ) internal view returns (uint256) {
        return _getUserInfo(self, game);
    }

    function _initUser(User storage self,
        address addr,
        uint32 gameRound
    ) private returns (uint256) {
        uint256 data = self.data;
        uint32 prevGameRound = data.getGameRound();
        unchecked {
            uint32 nextGameRound = prevGameRound + 1;
            if (data == 0 || gameRound - prevGameRound >= 2) {
                data = uint256(uint160(addr)) << USER_OFFSET_OWNER_ADDR;
                self.lastCommit = 0;
            } else if (nextGameRound == gameRound) {
                data = data.addBurnCount(data.getLiveCount());
                data = data.setLiveCount(data.getSafeCount());
                data = data.clearSafeCount();
                self.lastCommit = 0;
            }
        }
        data = data.setGameRound(gameRound);
        self.data = data;
        return data;
    }

    function _isExpired(User storage self, uint32 gameRound) private view returns (bool) {
        return gameRound - self.data.getGameRound() >= 2;
    }

    function _commit(User storage self,
        uint32 gameRound,
        GameStatus status,
        bytes32 hash
    ) private {
        _initUser(self, address(0), gameRound);
        if (self.lastCommit != 0) revert ErrorCommitPrevious();
        if ((_getPermissions(self, status, gameRound) != PERM_COMMIT)) revert ErrorCommitDenied();
        self.lastCommit = (uint256(hash) << OFFSET_COMMIT) | (block.number + COMMIT_WINDOW);
    }

    function _reveal(User storage self,
        uint32 gameRound,
        GameStatus status,
        bytes memory secret
    ) private {
        if (secret.length != 4) revert ErrorRevealLength();
        if (_getPermissions(self, status, gameRound) != PERM_REVEAL) revert ErrorRevealDenied();
        bytes32 hash = keccak256(secret);
        self.lastCommit = uint256(hash) << OFFSET_COMMIT;
        if (self.lastCommit != (self.lastCommit & ~uint256(0xFFFFFFFF))) revert ErrorRevealMismatch();
        return;
    }

    function _getStatus(User storage self,
        uint32 gameRound
    ) private view returns (UserStatus) {
        uint256 lastGameRound = self.data.getGameRound();
        if (lastGameRound == gameRound) return UserStatus.VALID;
        unchecked {
            if (lastGameRound + 1 == gameRound) return UserStatus.STALE;
        }
        return UserStatus.EXPIRED;
    }

    function _getPermissions(User storage self,
        GameStatus status,
        uint32 gameRound
    ) private view returns (uint8) {
        uint256 data = self.data;
        uint32 lastGameRound =  data.getGameRound();
        uint16 count = data.getLiveCount();
        if ((status == GameStatus.PENDING || status == GameStatus.RUNNING) && (lastGameRound + 1 == gameRound)) {
            count = data.getSafeCount();
        }
        if ((status != GameStatus.PENDING && status != GameStatus.RUNNING) ||
            (gameRound - lastGameRound >= 2) || (count == 0)) {
            return PERM_DENIED;
        }
        uint256 lastCommit = self.lastCommit;
        if (lastCommit == 0) return PERM_COMMIT;
        uint32 blockNumber = uint32(lastCommit);
        if ((blockNumber == 0) && (lastGameRound + 1 == gameRound) &&
            (lastCommit > REVEAL_THRESHOLD)) {
            return PERM_COMMIT;
        }
        if (lastCommit <= REVEAL_THRESHOLD) return PERM_DENIED;
        return (blockNumber > 1 && block.number <= blockNumber) ? PERM_REVEAL : PERM_CLAIMS;
    }

    function _getUserInfo(User storage self,
        LibGame.Game storage game
    ) private view returns (uint256) {
        uint256 userData = self.data;
        uint32 lastGameRound = userData.getGameRound();
        if (lastGameRound == 0) return 0;
        uint256 gameData = game.data;
        uint256 resetEndTime = gameData.resetEndTime();
        uint32 gameRound = gameData.getGameRound();
        uint16 liveCount = userData.getLiveCount();
        uint16 safeCount = userData.getSafeCount();
        uint16 burnCount = userData.getBurnCount();
        GameStatus status = game.getStatus();
        if (status > GameStatus.RUNNING) {
            if (resetEndTime == 0) {
                resetEndTime = game.virtualResetEndTime(status);
            }
            if (resetEndTime != 0 && block.timestamp > resetEndTime) {
                gameRound = game.nextGameRound();
            }
        }
        unchecked {
            uint256 isPlayer = (userData.getGameNumber() == gameData.getGameNumber() &&
                (liveCount | safeCount | burnCount) != 0) ? 1 : 0;
            if (((status == GameStatus.PAUSING || status == GameStatus.PENDING) && (gameData.pauseEndTime() != 0))) {
                gameRound++;
            }
            uint256 perms = _getPermissions(self, status, gameRound);
            if (gameRound - lastGameRound >= 2) {
                burnCount += (liveCount + safeCount);
                liveCount = safeCount = 0;
            }
            else if ((lastGameRound + 1 == gameRound) || (status > GameStatus.RUNNING)) {
                burnCount += liveCount;
                liveCount  = 0;
                if (status == GameStatus.PENDING || status == GameStatus.RUNNING) {
                    (liveCount, safeCount) = (safeCount, 0);
                } else if (status > GameStatus.RUNNING) {
                    burnCount += safeCount;
                    safeCount  = 0;
                }
            }
            return
                (isPlayer           << INFO_OFFSET_IS_PLAYING) |
                (perms              << INFO_OFFSET_PERMISSION) |
                (uint256(burnCount) << INFO_OFFSET_BURN_COUNT) |
                (uint256(safeCount) << INFO_OFFSET_SAFE_COUNT) |
                (uint256(liveCount) << INFO_OFFSET_LIVE_COUNT);
        }
    }
}
