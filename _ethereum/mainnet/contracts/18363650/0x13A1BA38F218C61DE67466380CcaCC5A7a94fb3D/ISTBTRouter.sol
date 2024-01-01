// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISTBTRouter {
    function executeWithData(
        address externalRouter,
        address fromTokenAddress, 
        address toTokenAddress, 
        uint256 amount, 
        address receiver,
        bytes memory data, 
        bool restriction
    ) external;
}