// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MovrErrors {
    string internal constant ADDRESS_0_PROVIDED = "ADDRESS_0_PROVIDED";
    string internal constant EMPTY_INPUT = "EMPTY_INPUT";
    string internal constant LENGTH_MISMATCH = "LENGTH_MISMATCH";
    string internal constant INVALID_VALUE = "INVALID_VALUE";
    string internal constant INVALID_AMT = "INVALID_AMT";

    string internal constant IMPL_NOT_FOUND = "IMPL_NOT_FOUND";
    string internal constant ROUTE_NOT_FOUND = "ROUTE_NOT_FOUND";
    string internal constant IMPL_NOT_ALLOWED = "IMPL_NOT_ALLOWED";
    string internal constant ROUTE_NOT_ALLOWED = "ROUTE_NOT_ALLOWED";
    string internal constant INVALID_CHAIN_DATA = "INVALID_CHAIN_DATA";
    string internal constant CHAIN_NOT_SUPPORTED = "CHAIN_NOT_SUPPORTED";
    string internal constant TOKEN_NOT_SUPPORTED = "TOKEN_NOT_SUPPORTED";
    string internal constant NOT_IMPLEMENTED = "NOT_IMPLEMENTED";
    string internal constant INVALID_SENDER = "INVALID_SENDER";
}
