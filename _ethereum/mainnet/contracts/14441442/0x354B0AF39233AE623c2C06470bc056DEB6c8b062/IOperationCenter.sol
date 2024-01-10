// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OperationCenterInterface {
    function eventCenterAddress() external view returns (address);
    function connectorCenterAddress() external view returns (address);
    function tokenCenterAddress() external view returns (address);
    function protocolCenterAddress() external view returns (address);
    function getOpCodeAddress(bytes4 _sig) external view returns (address);
}