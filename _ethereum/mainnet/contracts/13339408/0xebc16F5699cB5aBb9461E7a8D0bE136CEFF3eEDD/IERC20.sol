pragma solidity ^0.8.4;

interface IERC20 {

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);
    function allowance(address owner, address spender)
    external view returns (uint256);
}