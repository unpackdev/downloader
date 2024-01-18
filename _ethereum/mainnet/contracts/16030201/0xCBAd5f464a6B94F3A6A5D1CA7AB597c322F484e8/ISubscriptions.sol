// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ISubscriptions {
    struct Subscription {
        uint256 idx;
        address tokenPaid;
        string tier;
        uint256 usdAmount;
        uint256 frequency;
        uint256 startDate;
        uint256 endDate;
        uint256 stakedAmount;
        uint256 processedAt;
        uint256 processedAmount;
    }

    struct SubscriptionTier {
        uint256 frequency;
        uint256 usdAmount;
        uint256 usdStakeAmount;
        uint256 feePercentage;
    }

    function subscribe(
        address token_,
        string calldata tierName_,
        uint256 startDate_
    ) external;

    function unsubscribe() external;

    function withdrawStake() external;

    function processPayments(address[] calldata addressesToProcess_) external;

    function getActiveSubscriptionCount() external view returns (uint256);

    function getSubscriptionTiersCount() external view returns (uint256);
}
