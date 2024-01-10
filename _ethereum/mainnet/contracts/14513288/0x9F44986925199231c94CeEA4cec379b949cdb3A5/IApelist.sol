pragma solidity 0.8.11;

interface IApelist {
    function apeMint(address, uint256, uint256) external;
    function totalSupply(uint256) external view returns (uint256);
}
