pragma solidity ^0.8.20;

interface ERC20 {
    function balanceOf(address _who) external view returns (uint256);
}