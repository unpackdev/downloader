// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;


interface IInstanceRegistryFacade {

    function getContract(bytes32 contractName)
        external
        view
        returns (address contractAddress);
        
}