pragma solidity ^0.6.0;

interface IVaultCalculator {
    function getUnderlyingToken(address _account) external view returns (uint256);
}
