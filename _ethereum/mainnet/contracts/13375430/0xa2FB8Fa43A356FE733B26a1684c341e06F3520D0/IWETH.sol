// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IERC20.sol";


abstract contract IWETH is IERC20 {
    function deposit() virtual external payable;

    function withdraw(uint256 amount) virtual external;
}
