pragma solidity ^0.6.0;

interface IConverter {
    function convert(address) external returns (uint256);
}
