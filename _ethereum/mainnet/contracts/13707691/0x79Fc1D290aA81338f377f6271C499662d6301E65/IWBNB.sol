// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IBEP20.sol";

interface IWBNB is IBEP20 {
    function deposit() external payable;
}