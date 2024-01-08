pragma solidity >=0.7.0 <0.8.0;

interface IStrategy {
    function vault() external view returns (address);
    function want() external view returns (address);
}