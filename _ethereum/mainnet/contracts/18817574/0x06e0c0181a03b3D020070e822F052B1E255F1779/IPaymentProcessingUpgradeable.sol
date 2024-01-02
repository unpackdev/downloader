// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPaymentProcessingUpgradeable {
    error Payment__InsufficientBalance();
    error Payment__InvalidAccount();
    error Payment__ExceedBPS();
}
