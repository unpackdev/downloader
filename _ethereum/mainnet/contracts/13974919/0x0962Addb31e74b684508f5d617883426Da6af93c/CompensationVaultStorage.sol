// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ICompensationVault.sol";
import "./StorageSlotOwnable.sol";

contract CompensationVaultStorage is StorageSlotOwnable {
    // V1 storage layout start

    address public token; // compensation token
    bool public paused;

    bool internal _initialized0; // initialize flags
    bool internal _initialized1;
    bool internal _initialized2;
    bool internal _initialized3;
    bool internal _initialized4;
    bool internal _initialized5;
    bool internal _initialized6;
    bool internal _initialized7;
    bool internal _initialized8;
    bool internal _initialized9;
    bool internal _initialized10;
    bool internal _initialized11;
    bool internal _initialized12;
    bool internal _initialized13;
    bool internal _initialized14;
    bool internal _initialized15;

    uint256 private _buf0; // buffer slot to split flags and numbers

    uint128 public totalCompensation; // amount of compensation that vault will pay (reset to 0 when vault reset)
    uint128 public debt; // amount of compensation that vault have to transfer (reset to 0 when vault reset)

    uint128 public pastDebt; // amount of compensation that vault have to transfer (remain when vault reset)

    uint64 public START_TIME; // time when the compensation program start
    uint64 public MAX_RUNNING_DAYS; // running period in days.

    uint128 public TOTAL_ALLOCATED; // total allocated reward token amount.
    uint128 public LIMIT_PER_TX; // compensation limit per transaction.
    uint128 public LIMIT_PER_DAY; // The remaining compensation limit for a day will be carried over as compensation limit the next day.

    mapping(uint256 => bool) public nonces;
    mapping(address => bool) public isSigner;
    mapping(address => bool) public isRouter;
    mapping(address => uint256) public compensations;
    // V1 storage layout end
}
