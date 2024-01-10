// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./Kernel.sol";

abstract contract NonLinearTimeLockSwapperV2_0_0___2_0_2Storage is Kernel {
    // swap data for each source token, i.e., teamCFX, ecoCFX, backCFX
    struct SourceTokeData {
        uint128 rate; // convertion rate from source token to target token
        uint128 startTime;
        uint256[] stepEndTimes;
        uint256[] accStepRatio;
    }

    IERC20 public token; // target token, i.e., CFX
    address public tokenWallet; // address who supply target token

    bool public migrationStopped;

    // time lock data for each source token
    mapping(address => SourceTokeData) public sourceTokenDatas;

    // source token deposit amounts
    // sourceToken => beneficiary => deposit amounts
    mapping(address => mapping(address => uint256)) public depositAmounts;

    // source token claimed amounts
    // sourceToken => beneficiary => claimed amounts
    mapping(address => mapping(address => uint256)) public claimedAmounts;
}
