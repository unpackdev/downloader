// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Errors {
    string ADDRESS_ZERO_ERROR = "Can not use address zero";
    string NOT_POSITIVE_ERROR = "Value should be more bigger than 0";
    string LTN_TIMESTAMP_ERROR = "Time should be bigger than current time";
    string LTS_TIMESTAMP_ERROR = "Time should be bigger than start time";
    string NOT_ON_SALE_ERROR = "Not on the sale period";
    string NOT_ON_BUY_ERROR = "Not on the buy period";
    string BAD_AMOUNT_ERROR = "Bad amount";
    string INSUFFICIENT_BALANCE_ERROR = "Insufficient balance in ICO";
    string NOT_HOLDER_ERROR = "Not a holder";
}