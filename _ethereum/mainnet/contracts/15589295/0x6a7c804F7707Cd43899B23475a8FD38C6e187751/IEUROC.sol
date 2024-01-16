// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
interface IEUROC is IERC20 {
    function isBlacklisted(address account_) external returns(bool);
}