// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

struct ProtectionPayload {
    bytes32 taskHash;
    address colToken;
    address debtToken;
    uint256 rateMode;
    uint256 amtToFlashBorrow;
    uint256 amtOfDebtToRepay;
    uint256 minimumHealthFactor;
    uint256 wantedHealthFactor;
    address onBehalfOf;
    uint256 protectionFeeInETH;
    address[] swapActions;
    bytes[] swapDatas;
}

struct ExecutionData {
    address user;
    address action;
    uint256 subBlockNumber;
    bytes data;
    bytes offChainData;
    bool isPermanent;
}

struct ProtectionDataCompute {
    address colToken;
    address debtToken;
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 colLiquidationThreshold;
    uint256 wantedHealthFactor;
    uint256 colPrice;
    uint256 debtPrice;
    address onBehalfOf;
    uint256 protectionFeeInETH;
    uint256 flashloanPremiumBps;
}

struct FlashLoanData {
    address[] assets;
    uint256[] amounts;
    uint256[] premiums;
    bytes params;
}

struct FlashLoanParamsData {
    uint256 minimumHealthFactor;
    bytes32 taskHash;
    address debtToken;
    uint256 amtOfDebtToRepay;
    uint256 rateMode;
    address onBehalfOf;
    uint256 protectionFeeInETH;
    address[] swapActions;
    bytes[] swapDatas;
}

struct RepayAndFlashBorrowData {
    bytes32 id;
    address user;
    address colToken;
    address debtToken;
    uint256 wantedHealthFactor;
    uint256 protectionFeeInETH;
}

struct RepayAndFlashBorrowResult {
    bytes32 id;
    uint256 amtToFlashBorrow;
    uint256 amtOfDebtToRepay;
    string message;
}

struct CanExecData {
    bytes32 id;
    address user;
    uint256 minimumHF;
    address colToken;
    address spender;
}

struct CanExecResult {
    bytes32 id;
    bool isPositionUnSafe;
    bool isATokenAllowed;
    string message;
}
