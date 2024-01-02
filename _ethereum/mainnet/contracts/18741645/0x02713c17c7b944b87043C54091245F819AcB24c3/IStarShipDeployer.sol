// SPDX-License-Identifier: UNLICENSED
// Powered by Agora

pragma solidity ^0.8.21;


interface IStarShipDeployer {
    error DeploymentError();
    error InvalidID();

    function DeployNewToken(
        bytes32 salt,
        bytes32 hash,
        bytes memory arguments
    ) external payable returns (address erc20Address);
}
