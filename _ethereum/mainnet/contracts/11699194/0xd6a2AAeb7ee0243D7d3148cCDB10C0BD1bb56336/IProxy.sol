pragma solidity 0.7.3;

interface IProxy {
    function setProxyOwner(address _newOwner) external;
    function setImplementation(address _newImplementation) external;
}