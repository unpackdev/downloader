// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IERC20.sol";

// https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

interface IwETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}
