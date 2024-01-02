// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IERC20Metadata.sol";

interface IWETH9 is IERC20 {

    function deposit() external payable;

    function withdraw(uint256 wad) external;

}
