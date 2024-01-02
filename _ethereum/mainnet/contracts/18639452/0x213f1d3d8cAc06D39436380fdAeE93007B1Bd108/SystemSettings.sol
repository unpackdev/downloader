pragma solidity ^0.8.20;

interface SystemSettings {
    function issuanceRatio() external view returns (uint);

    function targetThreshold() external view returns (uint);
}
