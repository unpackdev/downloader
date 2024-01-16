// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IUshiToken is IERC20 {
    function setAntiWhale(bool enabled) external;
    function setAntiBot(bool enabled) external;
}