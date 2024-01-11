pragma solidity 0.7.6;

interface IRates {
    function oraclePool() external view returns (address);

    function reverse() external view returns (bool);

    function getPrice() external view returns (uint);

    function updatePrice() external;
}