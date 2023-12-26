pragma solidity 0.8.16;

interface ICloneable {
    function isInitialized() external view returns (bool);
}
