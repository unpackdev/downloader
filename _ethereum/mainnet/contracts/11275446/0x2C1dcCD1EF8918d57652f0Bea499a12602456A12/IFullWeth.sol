// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IFullWeth is IERC20 {
    function deposit() payable external;
}
