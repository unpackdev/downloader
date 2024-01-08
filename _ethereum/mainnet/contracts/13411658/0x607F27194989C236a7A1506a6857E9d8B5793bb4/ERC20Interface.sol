//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}