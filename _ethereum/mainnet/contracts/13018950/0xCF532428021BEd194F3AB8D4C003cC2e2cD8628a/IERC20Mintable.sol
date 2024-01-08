pragma solidity ^0.8.4;

interface IERC20Mintable{

    function mint(address to, uint256 amount) external;
}