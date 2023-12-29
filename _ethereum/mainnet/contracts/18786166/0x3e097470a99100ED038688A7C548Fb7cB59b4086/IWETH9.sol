// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

interface IWETH9 is IERC20 {
    function symbol() external view returns (string memory);

    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
