// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library Constants {
    /// @notice Flooring protocol
    /// @dev floor token amount of 1 NFT (with 18 decimals)
    uint256 public constant FLOOR_TOKEN_AMOUNT = 1_000_000 ether;
    /// @dev The minimum vip level required to use `proxy collection`
    uint8 public constant PROXY_COLLECTION_VIP_THRESHOLD = 3;

    /// @notice Rolling Bucket Constant Conf
    uint256 public constant BUCKET_SPAN_1 = 259199 seconds; // BUCKET_SPAN minus 1, used for rounding up
    uint256 public constant BUCKET_SPAN = 3 days;
    uint256 public constant MAX_LOCKING_BUCKET = 240;
    uint256 public constant MAX_LOCKING_PERIOD = 720 days; // MAX LOCKING BUCKET * BUCKET_SPAN

    /// @notice Auction Config
    uint256 public constant FREE_AUCTION_PERIOD = 24 hours;
    uint256 public constant AUCTION_INITIAL_PERIODS = 24 hours;
    uint256 public constant AUCTION_COMPLETE_GRACE_PERIODS = 2 days;
    /// @dev minimum bid per NFT when someone starts aution on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_MINIMUM_BID = 1000 ether;
    /// @dev minimum bid per NFT when someone starts aution on vault
    uint256 public constant AUCTION_ON_VAULT_MINIMUM_BID = 10000 ether;
    /// @dev admin fee charged per NFT when someone starts aution on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_SAFEBOX_COST = 0;
    /// @dev admin fee charged per NFT when owner starts aution on himself safebox
    uint256 public constant AUCTION_COST = 100 ether;

    /// @notice Raffle Config
    uint256 public constant RAFFLE_COST = 500 ether;
    uint256 public constant RAFFLE_COMPLETE_GRACE_PERIODS = 2 days;

    /// @notice Private offer Config
    uint256 public constant PRIVATE_OFFER_DURATION = 24 hours;
    uint256 public constant PRIVATE_OFFER_COMPLETE_GRACE_DURATION = 2 days;
    uint256 public constant PRIVATE_OFFER_COST = 0;

    uint256 public constant ADD_FREE_NFT_REWARD = 0;

    /// @notice Lock/Unlock config
    uint256 public constant USER_SAFEBOX_QUOTA_REFRESH_DURATION = 1 days;
    uint256 public constant USER_REDEMPTION_WAIVER_REFRESH_DURATION = 1 days;
    uint256 public constant VAULT_REDEMPTION_MAX_LOKING_RATIO = 80;

    /// @notice Activities Fee Rate

    /// @notice Fee rate used to distribute funds that collected from Auctions on expired safeboxes.
    /// these auction would be settled using credit token
    uint256 public constant FREE_AUCTION_FEE_RATE_BIPS = 2000; // 20%
    /// @notice Fee rate settled with credit token
    uint256 public constant CREDIT_FEE_RATE_BIPS = 150; // 2%
    /// @notice Fee rate settled with specified token
    uint256 public constant SPEC_FEE_RATE_BIPS = 300; // 3%
    /// @notice Fee rate settled with all other tokens
    uint256 public constant COMMON_FEE_RATE_BIPS = 500; // 5%

    uint256 public constant VIP_LEVEL_COUNT = 8;

    struct AuctionBidOption {
        uint256 extendDurationSecs;
        uint256 minimumRaisePct;
        uint256 vipLevel;
    }

    function getVipLockingBuckets(uint256 vipLevel) internal pure returns (uint256 buckets) {
        require(vipLevel < VIP_LEVEL_COUNT);
        assembly {
            switch vipLevel
            case 1 { buckets := 1 }
            case 2 { buckets := 5 }
            case 3 { buckets := 20 }
            case 4 { buckets := 60 }
            case 5 { buckets := 120 }
            case 6 { buckets := 180 }
            case 7 { buckets := MAX_LOCKING_BUCKET }
        }
    }

    function getVipLevel(uint256 totalCredit) internal pure returns (uint8) {
        if (totalCredit < 30_000 ether) {
            return 0;
        } else if (totalCredit < 100_000 ether) {
            return 1;
        } else if (totalCredit < 300_000 ether) {
            return 2;
        } else if (totalCredit < 1_000_000 ether) {
            return 3;
        } else if (totalCredit < 3_000_000 ether) {
            return 4;
        } else if (totalCredit < 10_000_000 ether) {
            return 5;
        } else if (totalCredit < 30_000_000 ether) {
            return 6;
        } else {
            return 7;
        }
    }

    function getVipBalanceRequirements(uint256 vipLevel) internal pure returns (uint256 required) {
        require(vipLevel < VIP_LEVEL_COUNT);

        assembly {
            switch vipLevel
            case 1 { required := 30000 }
            case 2 { required := 100000 }
            case 3 { required := 300000 }
            case 4 { required := 1000000 }
            case 5 { required := 3000000 }
            case 6 { required := 10000000 }
            case 7 { required := 30000000 }
        }

        /// credit token should be scaled with 18 decimals(1 ether == 10**18)
        unchecked {
            return required * 1 ether;
        }
    }

    function getBidOption(uint256 idx) internal pure returns (AuctionBidOption memory) {
        require(idx < 4);
        AuctionBidOption[4] memory bidOptions = [
            AuctionBidOption({extendDurationSecs: 5 minutes, minimumRaisePct: 1, vipLevel: 0}),
            AuctionBidOption({extendDurationSecs: 8 hours, minimumRaisePct: 10, vipLevel: 3}),
            AuctionBidOption({extendDurationSecs: 16 hours, minimumRaisePct: 20, vipLevel: 5}),
            AuctionBidOption({extendDurationSecs: 24 hours, minimumRaisePct: 40, vipLevel: 7})
        ];
        return bidOptions[idx];
    }

    function raffleDurations(uint256 idx) internal pure returns (uint256 vipLevel, uint256 duration) {
        require(idx < 6);

        vipLevel = idx;
        assembly {
            switch idx
            case 1 { duration := 1 }
            case 2 { duration := 2 }
            case 3 { duration := 3 }
            case 4 { duration := 5 }
            case 5 { duration := 7 }
        }
        unchecked {
            duration *= 1 days;
        }
    }

    /// return locking ratio restrictions indicates that the vipLevel can utility infinite lock NFTs at corresponding ratio
    function getLockingRatioForInfinite(uint8 vipLevel) internal pure returns (uint256 ratio) {
        assembly {
            switch vipLevel
            case 1 { ratio := 0 }
            case 2 { ratio := 0 }
            case 3 { ratio := 20 }
            case 4 { ratio := 30 }
            case 5 { ratio := 40 }
            case 6 { ratio := 50 }
            case 7 { ratio := 80 }
        }
    }

    /// return locking ratio restrictions indicates that the vipLevel can utility safebox to lock NFTs at corresponding ratio
    function getLockingRatioForSafebox(uint8 vipLevel) internal pure returns (uint256 ratio) {
        assembly {
            switch vipLevel
            case 1 { ratio := 10 }
            case 2 { ratio := 20 }
            case 3 { ratio := 30 }
            case 4 { ratio := 40 }
            case 5 { ratio := 50 }
            case 6 { ratio := 60 }
            case 7 { ratio := 70 }
        }
    }

    function getVipRequiredStakingWithDiscount(uint256 requiredStaking, uint8 vipLevel)
        internal
        pure
        returns (uint256)
    {
        if (vipLevel < 3) {
            return requiredStaking;
        }
        unchecked {
            /// the higher vip level, more discount for staking
            ///  discount range: 5% - 25%
            return requiredStaking * (100 - (vipLevel - 2) * 5) / 100;
        }
    }

    function getRequiredStakingForLockRatio(uint256 locked, uint256 totalManaged) internal pure returns (uint256) {
        if (totalManaged <= 0) {
            return 1200 ether;
        }

        unchecked {
            uint256 lockingRatioPct = locked * 100 / totalManaged;
            if (lockingRatioPct <= 40) {
                return 1200 ether;
            } else if (lockingRatioPct < 60) {
                return 1320 ether + ((lockingRatioPct - 40) >> 1) * 120 ether;
            } else if (lockingRatioPct < 70) {
                return 2640 ether + ((lockingRatioPct - 60) >> 1) * 240 ether;
            } else if (lockingRatioPct < 80) {
                return 4080 ether + ((lockingRatioPct - 70) >> 1) * 480 ether;
            } else if (lockingRatioPct < 90) {
                return 6960 ether + ((lockingRatioPct - 80) >> 1) * 960 ether;
            } else if (lockingRatioPct < 100) {
                /// 108000 * 2^x
                return (108000 ether << ((lockingRatioPct - 90) >> 1)) / 5;
            } else {
                return 345600 ether;
            }
        }
    }

    /// @dev returns (costAfterDiscount, quotaUsedAfter)
    function getVipClaimCostWithDiscount(uint256 cost, uint8 vipLevel, uint96 quotaUsed)
        internal
        pure
        returns (uint256, uint96)
    {
        uint96 totalQuota = 1 ether;

        assembly {
            switch vipLevel
            case 0 { totalQuota := mul(0, totalQuota) }
            case 1 { totalQuota := mul(2000, totalQuota) }
            case 2 { totalQuota := mul(4000, totalQuota) }
            case 3 { totalQuota := mul(8000, totalQuota) }
            case 4 { totalQuota := mul(16000, totalQuota) }
            case 5 { totalQuota := mul(32000, totalQuota) }
            case 6 { totalQuota := mul(64000, totalQuota) }
            case 7 { totalQuota := mul(128000, totalQuota) }
        }

        if (totalQuota <= quotaUsed) {
            return (cost, quotaUsed);
        }

        unchecked {
            totalQuota -= quotaUsed;
            if (cost < totalQuota) {
                return (0, uint96(quotaUsed + cost));
            } else {
                return (cost - totalQuota, totalQuota + quotaUsed);
            }
        }
    }

    function getClaimCost(uint256 lockingRatioPct) internal pure returns (uint256) {
        if (lockingRatioPct < 40) {
            return 0;
        } else {
            /// 1000 * 2^(0..12)
            unchecked {
                return 1000 ether * (2 ** ((lockingRatioPct - 40) / 5));
            }
        }
    }

    function getVaultAuctionDurationAtLR(uint256 lockingRatio) internal pure returns (uint256) {
        if (lockingRatio < 80) return 1 hours;
        else if (lockingRatio < 85) return 3 hours;
        else if (lockingRatio < 90) return 6 hours;
        else if (lockingRatio < 95) return 12 hours;
        else return 24 hours;
    }

    function getSafeboxPeriodQuota(uint8 vipLevel) internal pure returns (uint16 quota) {
        assembly {
            switch vipLevel
            case 0 { quota := 0 }
            case 1 { quota := 1 }
            case 2 { quota := 2 }
            case 3 { quota := 4 }
            case 4 { quota := 8 }
            case 5 { quota := 16 }
            case 6 { quota := 32 }
            case 7 { quota := 64 }
        }
    }

    function getSafeboxUserQuota(uint8 vipLevel) internal pure returns (uint16 quota) {
        assembly {
            switch vipLevel
            case 0 { quota := 0 }
            case 1 { quota := 4 }
            case 2 { quota := 8 }
            case 3 { quota := 16 }
            case 4 { quota := 32 }
            case 5 { quota := 64 }
            case 6 { quota := 128 }
            case 7 { quota := 256 }
        }
    }
}
