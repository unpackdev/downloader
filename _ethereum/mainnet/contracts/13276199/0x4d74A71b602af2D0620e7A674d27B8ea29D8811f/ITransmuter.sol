pragma solidity 0.8.4;

import "./IVaultHolder.sol";

interface ITransmuter is IVaultHolder {
    function pause() external view returns (bool);
    function setKeepers(address[] calldata _keepers, bool[] calldata _states) external;
}