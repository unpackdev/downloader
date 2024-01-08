// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";

interface TokenLike is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}
