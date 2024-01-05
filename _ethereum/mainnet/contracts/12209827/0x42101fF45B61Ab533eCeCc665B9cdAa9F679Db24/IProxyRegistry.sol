pragma solidity 0.6.12;

interface IProxyRegistry {
    function getProxy(uint256 _index) external view returns(address);
}