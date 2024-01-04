// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct DebtBridgeInputData {
    address dsa;
    uint256 colAmt;
    address colToken;
    uint256 debtAmt;
    address oracleAggregator;
    uint256 makerDestVaultId;
    string makerDestColType;
    uint256 fees;
    uint256 flashRoute;
}
