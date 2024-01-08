// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IFarmingPool {
    function addLiquidity(uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function liquidate(address account) external;

    function computeBorrowerInterestEarning()
        external
        returns (uint256 borrowerInterestEarning);

    function estimateBorrowerInterestEarning()
        external
        view
        returns (uint256 borrowerInterestEarning);

    function getTotalTransferToAdapterFor(address account)
        external
        view
        returns (uint256 totalTransferToAdapter);

    function getLoansAtLastAccrualFor(address account)
        external
        view
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        );

    function getPoolLoansAtLastAccrual()
        external
        view
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        );

    function needToLiquidate(address account, uint256 liquidationThreshold)
        external
        view
        returns (
            bool isLiquidate,
            uint256 accountRedeemableUnderlyingTokens,
            uint256 threshold
        );

    event AddLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        uint256 amount,
        uint256 receiveQuantity,
        uint256 timestamp
    );

    event RemoveLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        uint256 requestedAmount,
        uint256 actualAmount,
        uint256 adapterTransfer,
        uint256 loanPrincipalToRepay,
        uint256 payableInterest,
        uint256 taxAmount,
        uint256 receiveQuantity,
        uint256 outstandingInterest,
        uint256 timestamp
    );

    event LiquidateFarmer(
        address indexed account,
        address indexed underlyingAssetAddress,
        address indexed farmerAccount,
        uint256 requestedAmount,
        uint256 actualAmount,
        uint256 adapterTransfer,
        uint256 loanPrincipalToRepay,
        uint256 payableInterest,
        uint256 taxAmount,
        uint256 liquidationPenalty,
        uint256 receiveQuantity,
        uint256 outstandingInterest,
        uint256 timestamp
    );

    event ComputeBorrowerInterestEarning(
        uint256 borrowerInterestEarning,
        uint256 timestamp
    );
}
