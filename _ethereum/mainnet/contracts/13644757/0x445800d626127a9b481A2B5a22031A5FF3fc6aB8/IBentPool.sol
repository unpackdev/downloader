// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IBentPool {
    function lpToken() external view returns (address);
}
