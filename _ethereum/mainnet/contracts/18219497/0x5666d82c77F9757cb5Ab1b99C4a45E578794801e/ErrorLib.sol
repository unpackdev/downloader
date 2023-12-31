// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.0;

library ErrorLib {
    error AddressNul();
    error AmountNul();
    error InsufficientUnderlying();
    error InvalidL2Address();
    error InvalidBatchNonce();
    error InvalidBridgeNonce();
    error FWAlreadySet();
    error CallerNotRelayer();
    error CallerNotAllowedLiquidityProvider();
    error EmptyArray();
    error BlockAleadyProcessed();
}
