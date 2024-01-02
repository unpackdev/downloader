// SPDX-License-Identifier: MIT
import "./IERC20.sol";
pragma solidity ^0.8.4;

interface IFanvToken is IERC20{
    function mint(address account, uint amount) external;
    function balanceOf(address account) external view override returns (uint256);
    function approve(address spender, uint256 amount) external override returns (bool);
    function transfer(address recipient, uint256 amount) external override returns (bool);
    function allowance(address owner, address spender) external view override returns (uint256);
}