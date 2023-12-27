// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface Types {
    enum CallType {
        CALL,
        DELEGATECALL,
        STATICCALL
    }

    struct Executable {
        CallType callType;
        address target;
        uint256 value;
        bytes data;
    }

    struct TokenRequest {
        address token;
        uint256 amount;
    }
}
