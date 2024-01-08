pragma solidity 0.5.15;

interface ISystemSettings {
    function issuanceRatio() external view returns(uint);
}