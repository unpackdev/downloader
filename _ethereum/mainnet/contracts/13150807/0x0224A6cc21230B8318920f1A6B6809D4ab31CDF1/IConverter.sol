pragma solidity 0.8.2;

interface IConverter {
    function convert(address) external returns (uint256);
}
