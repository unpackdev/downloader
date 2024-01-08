// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CreamStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit USDT in C.R.E.A.M. and earn interest.
contract CreamStrategyUSDT is CreamStrategy {
    string public constant NAME = "Cream-Strategy-USDT";
    string public constant VERSION = "3.0.11";

    // crUSDT = 0x797AAB1ce7c01eB727ab980762bA88e7133d2157
    constructor(address _pool, address _swapManager)
        CreamStrategy(_pool, _swapManager, 0x797AAB1ce7c01eB727ab980762bA88e7133d2157)
    {}
}
