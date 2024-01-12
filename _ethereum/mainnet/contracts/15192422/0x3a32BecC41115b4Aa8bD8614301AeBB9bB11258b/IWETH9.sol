// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./IERC20Metadata.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}
