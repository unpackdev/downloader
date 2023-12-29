// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Shared constructs for the Subscription Token Protocol contracts
library Shared {
    /// @dev The initialization parameters for a subscription token
    struct InitParams {
        /// @dev the name of the collection
        string name;
        /// @dev the symbol of the collection
        string symbol;
        /// @dev the metadata URI for the collection
        string contractUri;
        /// @dev the metadata URI for the tokens
        string tokenUri;
        /// @dev the address of the owner of the collection
        address owner;
        /// @dev the number of base tokens required for a single second of time
        uint256 tokensPerSecond;
        /// @dev the minimum number of seconds an account can purchase
        uint256 minimumPurchaseSeconds;
        /// @dev the basis points for reward allocations
        uint16 rewardBps;
        /// @dev the number of times the reward rate is halved (until it reaches one). 6 = 64,32,16,16,8,4,2,1 .. then 0
        uint8 numRewardHalvings;
        /// @dev the basis points for fee allocations
        uint16 feeBps;
        /// @dev the address of the fee recipient
        address feeRecipient;
        /// @dev the address of the ERC20 token used for purchases, or the 0x0 for native
        address erc20TokenAddr;
    }
}
