// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./TransferHelper.sol";

interface ITreasury {
    function balanceOf(address owner_, uint256 id_) external view returns (uint256);

    function metaId(uint32 id_) external view returns (uint16);

    function getTotalPoints(uint32 nthEra_) external view returns (uint256);

    function getTotalTokens(uint32 nthEra_, address token_) external view returns (uint256);

    function subtractTP(uint32 uid_, uint32 nthEra_, uint64 point_) external;

    function getCurrentEra() external view returns (uint32);
}

library TreasuryLib {
    struct Storage {
        address accountant;
        address sabt;
        mapping(uint32 => uint32) claims;
        uint32 totalClaim;
        uint32 settlementId;
    }

    uint8 internal constant USER_META_ID = 1;
    uint8 internal constant EARLYADOPTER_META_ID = 9;
    uint8 internal constant FOUNDATION_META_ID = 10;

    uint32 internal constant DENOM = 100000;

    struct Claim {
        uint32 num;
        uint32 denom;
    }

    error MembershipNotOwned(uint32 uid, address owner);
    error InvalidMetaId(uint16 metaId, uint32 uid, uint16 real);
    error EraNotPassed(uint32 nthEra, uint32 currentEra);
    error NoTotalTP(uint32 nthEra, uint256 point);
    error NoTotalTokens(uint32 nthEra, address token);

    function _checkMembership(Storage storage self, uint32 uid_, uint16 metaId_) internal view {
        // the sender owns the membership with UID
        if (ITreasury(self.sabt).balanceOf(msg.sender, uid_) == 0) {
            revert MembershipNotOwned(uid_, msg.sender);
        }
        uint16 uMeta = ITreasury(self.sabt).metaId(uid_);
        if (uMeta != metaId_) {
            revert InvalidMetaId(metaId_, uid_, uMeta);
        }
    }

    function _checkEraPassed(Storage storage self, uint32 nthEra_) internal view {
        // get current Era
        uint32 currentEra = ITreasury(self.accountant).getCurrentEra();
        if (nthEra_ >= currentEra) {
            revert EraNotPassed(nthEra_, currentEra);
        }
    }

    function _exchange(Storage storage self, address token, uint32 nthEra, uint32 uid, uint64 point) internal {
        // check if the sender owns the membership with UID
        if (ITreasury(self.sabt).balanceOf(msg.sender, uid) == 0) {
            revert MembershipNotOwned(uid, msg.sender);
        }
        // check if the era has already passed
        _checkEraPassed(self, nthEra);
        // subtract membership point in accountant
        ITreasury(self.accountant).subtractTP(uid, nthEra, point);
        // exchange membership point with reward
        uint256 reward = _getReward(self, token, nthEra, point);
        // exchange reward with token
        TransferHelper.safeTransfer(token, msg.sender, reward);
    }

    function _claim(Storage storage self, address token, uint32 nthEra, uint32 uid) internal {
        // check if the sender has UID with early adoptor meta id
        _checkMembership(self, uid, EARLYADOPTER_META_ID);
        // check if the era has already passed
        _checkEraPassed(self, nthEra);
        // get reward from accountant
        uint256 claim = _getClaim(self, token, uid, nthEra);
        // exchange reward with token
        TransferHelper.safeTransfer(token, msg.sender, claim);
    }

    function _settle(Storage storage self, address token, uint32 nthEra, uint32 uid) internal {
        // check if the sender has UID with foundation meta id
        _checkMembership(self, uid, FOUNDATION_META_ID);
        // check if the era has already passed
        _checkEraPassed(self, nthEra);
        uint256 settlement = _getSettlement(self, token, nthEra);
        TransferHelper.safeTransfer(token, msg.sender, settlement);
    }

    error ShareLimitExceeded(uint32 totalClaim, uint32 limit);

    function _setClaim(Storage storage self, uint32 uid, uint32 num) internal {
        self.claims[uid] = num;
        self.totalClaim += num;
        // check if total claim is less than or equal to 60.0000%
        if (self.totalClaim > 600000) {
            revert ShareLimitExceeded(self.totalClaim, 600000);
        }
    }

    function _setSettlement(Storage storage self, uint32 uid) internal {
        self.settlementId = uid;
    }

    function _getReward(Storage storage self, address token, uint32 nthEra, uint256 point)
        internal
        view
        returns (uint256)
    {
        // get reward from Treasury ratio
        // 1. get total supply of mp
        uint256 totalTP = ITreasury(self.accountant).getTotalPoints(nthEra);
        if (totalTP == 0) {
            revert NoTotalTP(nthEra, totalTP);
        }
        // 2. get fee collected on nthEra
        uint256 totalTokens = ITreasury(self.accountant).getTotalTokens(nthEra, token);
        if (totalTokens == 0) {
            revert NoTotalTokens(nthEra, token);
        }
        // 3. get reward from community Treasury ratio
        return ((point * totalTokens * 4) / 10) / totalTP;
    }

    function _getClaim(Storage storage self, address token, uint32 uid, uint32 nthEra)
        internal
        view
        returns (uint256)
    {
        // check if sender has UID
        if (ITreasury(self.sabt).balanceOf(msg.sender, uid) == 0) {
            revert MembershipNotOwned(uid, msg.sender);
        }
        // 1. get fee collected on nthEra
        uint256 totalTokens = ITreasury(self.accountant).getTotalTokens(nthEra, token);
        if (totalTokens == 0) {
            revert NoTotalTokens(nthEra, token);
        }
        // 2. get reward from community Treasury ratio
        return ((totalTokens * (self.claims[uid])) / DENOM);
    }

    function _getSettlement(Storage storage self, address token, uint32 nthEra) internal view returns (uint256) {
        // check if sender has UID
        if (ITreasury(self.sabt).balanceOf(msg.sender, self.settlementId) == 0) {
            revert MembershipNotOwned(self.settlementId, msg.sender);
        }
        // 1. get fee collected on nthEra
        uint256 totalTokens = ITreasury(self.accountant).getTotalTokens(nthEra, token);
        if (totalTokens == 0) {
            revert NoTotalTokens(nthEra, token);
        }
        // 2. get reward from community Treasury ratio
        return ((totalTokens * (600000 - self.totalClaim)) / DENOM);
    }
}
