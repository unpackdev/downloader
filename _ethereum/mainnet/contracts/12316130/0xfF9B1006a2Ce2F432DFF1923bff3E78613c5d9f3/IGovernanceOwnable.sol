// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IGovernanceOwnable {
    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    function governance() external view returns (address);
    function setGovernance(address newGovernance) external;
}