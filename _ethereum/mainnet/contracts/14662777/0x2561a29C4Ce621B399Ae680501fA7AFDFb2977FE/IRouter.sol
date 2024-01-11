//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IRouter {
    function redeemStable(uint256 _amount) external returns (address);
    function depositStable(uint256 _amount) external returns (address);
    function aUST() external view returns (IERC20);
    function wUST() external view returns (IERC20);
}
