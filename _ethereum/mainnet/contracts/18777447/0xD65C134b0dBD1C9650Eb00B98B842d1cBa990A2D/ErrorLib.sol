// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.20;

library ErrorLib {
    error AddressNull();
    error AmountNull();
    error InsufficientUnderlying();
    error InvalidL2Address();
    error InvalidBatchNonce();
    error EmptyArray();
    error BlockAlreadyProcessed();
}
