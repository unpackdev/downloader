// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IFactoryErrors {
    error TreasuryAddressCanNotBeNull();
    error RouterAddressCanNotBeNull();
    error TransactionUnderpriced();
}