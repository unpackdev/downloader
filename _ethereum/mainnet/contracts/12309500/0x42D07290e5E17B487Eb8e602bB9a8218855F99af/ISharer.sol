pragma solidity >=0.7.0 <0.8.0;

interface ISharer {
    function distribute(address _strategy) external;
}