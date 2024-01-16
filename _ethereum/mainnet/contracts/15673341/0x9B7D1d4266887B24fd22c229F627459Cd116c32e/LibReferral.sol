// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibReferral {
    bytes32 constant REFERRAL_STORAGE_POSITION =
        keccak256("com.enterdao.landworks.referral");

    // Stores information about a metaverse registry's referrer and
    // percentage, used to calculate the reward upon every rent.
    struct MetaverseRegistryReferrer {
        // address of the referrer
        address referrer;
        // percentage from the rent protocol fee, which will be
        // accrued to the referrer
        uint24 percentage;
    }

    struct ReferrerPercentage {
        // Main referrer percentage, used as reward
        // for referrers + referees.
        uint24 mainPercentage;
        // Secondary percentage, which is used to calculate
        // the reward for a given referee.
        uint24 secondaryPercentage;
    }

    struct ReferralStorage {
        // Sets referrers
        address admin;
        // Stores addresses of listing referrer
        mapping(uint256 => address) listReferrer;
        // Accrued referrers fees address => paymentToken => amount
        mapping(address => mapping(address => uint256)) referrerFees;
        // Metaverse Registry referrers
        mapping(address => MetaverseRegistryReferrer) metaverseRegistryReferrers;
        // Referrers percentages
        mapping(address => ReferrerPercentage) referrerPercentages;
    }

    function referralStorage()
        internal
        pure
        returns (ReferralStorage storage rs)
    {
        bytes32 position = REFERRAL_STORAGE_POSITION;

        assembly {
            rs.slot := position
        }
    }
}
