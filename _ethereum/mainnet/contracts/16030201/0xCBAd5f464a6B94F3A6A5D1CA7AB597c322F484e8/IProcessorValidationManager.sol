// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IProcessorValidationManager {
    function validProcessors(address) external returns (bool);

    function validateProcessors(address[] calldata) external;

    function invalidateProcessors(address[] calldata) external;
}
