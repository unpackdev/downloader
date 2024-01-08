pragma solidity ^0.4.24;

interface IBoostLogicProvider {
    function hasMaxBoostLevel(address account) external view returns (bool);
}
