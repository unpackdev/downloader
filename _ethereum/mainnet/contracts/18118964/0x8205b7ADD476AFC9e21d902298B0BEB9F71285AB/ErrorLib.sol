// SPDX-License-Identifier: Apache-2.0.
pragma solidity 0.8.17;

library ErrorLib {
    error InvalidBatchNonce();
    error NotRelayer();
    error TroveAddressAlreadySet();
    error NonZeroTotalSupply();
    error OwnerNotLast();
    error TransferFailed(address token);
}
