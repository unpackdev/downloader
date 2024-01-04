pragma solidity ^0.5.16;

interface IPriceOracle {
    function price(string calldata symbol) external view returns (uint);
}