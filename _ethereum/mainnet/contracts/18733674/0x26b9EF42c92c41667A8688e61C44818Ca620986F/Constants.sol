// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Constants {
    uint256 public constant BORROW_AMOUNT_FOR_SENTINEL_REGISTRATION = 200000 * 10 ** 18;
    uint256 public constant STAKING_MIN_AMOUT_FOR_SENTINEL_REGISTRATION = 200000 * 10 ** 18;
    uint256 public constant STAKING_MIN_AMOUT_FOR_SENTINEL_REGISTRATION_TRUNCATED = 200000;
    uint256 public constant GUARDIAN_AMOUNT = 10000;
    uint256 public constant AVAILABLE_EPOCHS = 60;
    uint64 public constant MIN_STAKE_DURATION = 604800;
    uint32 public constant DECIMALS_PRECISION = 10 ** 6;
    uint32 public constant MAX_BORROWER_BORROWED_AMOUNT = 200000;
    bytes1 public constant REGISTRATION_NULL = 0x00;
    bytes1 public constant REGISTRATION_SENTINEL_STAKING = 0x01;
    bytes1 public constant REGISTRATION_SENTINEL_BORROWING = 0x02;
    bytes1 public constant REGISTRATION_GUARDIAN = 0x03;
    uint16 public constant NUMBER_OF_ALLOWED_SLASHES = 3;
}
