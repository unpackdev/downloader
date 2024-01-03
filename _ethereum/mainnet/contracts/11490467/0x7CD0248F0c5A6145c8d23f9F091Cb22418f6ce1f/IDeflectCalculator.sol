pragma solidity ^0.6.0;

interface IDeflectCalculator {
    function getUnderlyingDeflect(address _account, address _contract) external view returns (uint256);
}
