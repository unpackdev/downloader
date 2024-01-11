// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns(uint256 balance);
    function transfer(address recipient, uint256 amount) external returns(bool success);
    function transferFrom(address owner, address recipient, uint256 amount) external returns(bool success);
    function allowance(address owner, address spender) external view returns(uint256 remaining);
    function approve(address spender, uint256 amount) external returns(bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}