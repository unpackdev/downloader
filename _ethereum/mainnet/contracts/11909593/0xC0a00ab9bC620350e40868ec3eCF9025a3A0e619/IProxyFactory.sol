pragma solidity 0.7.6;

interface IProxyFactory {
    function deployMinimal(address _logic, bytes memory _data) external returns (address proxy);
}
