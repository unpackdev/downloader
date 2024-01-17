// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
