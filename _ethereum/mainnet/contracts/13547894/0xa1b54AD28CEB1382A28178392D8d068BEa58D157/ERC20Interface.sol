pragma solidity ^0.5.16;

interface ERC20Interface {
    function approve(address spender, uint256 amount) external returns (bool success);
    function mint(address to, uint amount) external;
    function burn(uint amount) external;
    function transfer(address to, uint value) external returns (bool);
}
