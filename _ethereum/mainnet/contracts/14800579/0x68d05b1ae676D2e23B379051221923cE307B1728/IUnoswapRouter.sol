// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeERC20.sol";

interface IUnoswapRouter {
    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns (uint256 returnAmount);
}
