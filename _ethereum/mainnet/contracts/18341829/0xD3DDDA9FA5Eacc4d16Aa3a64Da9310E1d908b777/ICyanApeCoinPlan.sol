// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICyanApeCoinPlan {
    enum PaymentPlanStatus {
        ACTIVE_ACCRUE_APESTAKING,
        ACTIVE_ACCRUE_CYANVAULT,
        COMPLETED
    }

    struct PaymentPlan {
        uint256 poolId;
        uint32 tokenId;
        uint224 loanedAmount;
        address cyanWalletAddress;
        PaymentPlanStatus status;
    }

    function paymentPlan(uint256 planId) external view returns (PaymentPlan memory);

    function createBaycPlan(
        uint256 planId,
        uint32 tokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external;

    function createMaycPlan(
        uint256 planId,
        uint32 tokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external;

    function createBakcPlanWithBAYC(
        uint256 planId,
        uint32 baycTokenId,
        uint32 bakcTokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external;

    function createBakcPlanWithMAYC(
        uint256 planId,
        uint32 maycTokenId,
        uint32 bakcTokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external;

    function createApeCoinPlan(
        uint256 planId,
        uint256 stakeAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external;

    function complete(uint256 planId) external;

    function completeApeCoinPlan(uint256 planId) external;

    function autoCompound(uint256[] calldata planIds) external;
}
