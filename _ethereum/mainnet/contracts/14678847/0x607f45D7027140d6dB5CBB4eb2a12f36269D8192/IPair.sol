pragma solidity ^0.8.12;

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}