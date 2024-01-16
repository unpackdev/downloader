// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC20.sol";

interface ICheeth is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}
