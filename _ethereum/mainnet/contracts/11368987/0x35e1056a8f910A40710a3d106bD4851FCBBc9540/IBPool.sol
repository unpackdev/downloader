// SPDX-License-Identifier: None

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IBPool is IERC20 {
    function getFinalTokens() external view returns(address[] memory);
    function getDenormalizedWeight(address token) external view returns (uint256);
    function setSwapFee(uint256 swapFee) external;
    function setController(address controller) external;
    function finalize() external;
    function bind(address token, uint256 balance, uint256 denorm) external;
    function getBalance(address token) external view returns (uint);
    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;
}