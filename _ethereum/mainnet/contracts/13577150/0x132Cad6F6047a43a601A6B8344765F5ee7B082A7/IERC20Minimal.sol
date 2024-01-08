pragma solidity ^0.7.0;

interface IERC20Minimal {
    function transfer(address recipient, uint256 amount) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}