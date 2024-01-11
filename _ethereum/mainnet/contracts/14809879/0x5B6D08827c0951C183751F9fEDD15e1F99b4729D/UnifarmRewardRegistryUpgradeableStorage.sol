// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract UnifarmRewardRegistryUpgradeableStorage {
    // solhint-disable-next-line
    receive() external payable {}

    /// @notice referral percentage
    uint256 public refPercentage;

    /// @notice struct to store referral commision for each unifarm influceners.
    struct ReferralConfiguration {
        // influencer wallet address.
        address userAddress;
        // decided referral percentage
        uint256 referralPercentage;
    }

    /// @notice reward cap
    mapping(address => mapping(address => uint256)) public rewardCap;

    /// @notice mapping for storing reward per block.
    mapping(address => bytes) internal _rewards;

    /// @notice Referral Configuration
    mapping(address => ReferralConfiguration) public referralConfig;

    /// @notice add multicall support
    address public multiCall;
}
