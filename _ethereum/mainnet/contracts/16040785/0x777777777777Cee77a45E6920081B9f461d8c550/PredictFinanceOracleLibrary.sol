// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PredictFinanceOracleLibrary {
    enum DataType {
        BYTES32,
        STRING,
        UINT256,
        BOOL
    }

    struct QuestionDetail {
        bool resolved;
        bytes32[] data;
        bytes32[] outcomes;
        uint256[] payouts;
        DataType dataType;
        DataType outcomesType;
        uint128 deadline;
        string title;
        string description;
        string[3] categories;
    }
}
