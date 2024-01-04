pragma solidity ^0.7.0;

import "./IERC20.sol";

interface IDexm is IERC20 {  
    function transfer(address to, uint256 amount) external override returns (bool);
    function transferFrom(address from, address to, uint256 amount) external override returns (bool);
    function balanceOf(address account) external view override returns (uint256);
}