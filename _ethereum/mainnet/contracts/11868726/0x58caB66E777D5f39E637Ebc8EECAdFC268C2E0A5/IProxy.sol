// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


interface IProxy {
    struct TONEvent {
        uint eventTransaction;
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        uint32 eventIndex;
        bytes eventData;
        int8 tonEventConfigurationWid;
        uint tonEventConfigurationAddress;
        uint16 requiredConfirmations;
        uint16 requiredRejects;
    }
}
