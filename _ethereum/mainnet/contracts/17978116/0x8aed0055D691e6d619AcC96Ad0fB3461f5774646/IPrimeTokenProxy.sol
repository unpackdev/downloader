// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPrimeTokenProxy {
    error ContractDisabled();
    error InvalidCaller();
    error InvalidEthDestination(address ethDestination);
    error InvalidPrimeAddress(address primeDestination);
    error InvalidPrimePayment();

    event IsDisabledSet(bool isDisabled);
    event IsSendFromDisabledSet(bool isSendFromDisabled);
}
