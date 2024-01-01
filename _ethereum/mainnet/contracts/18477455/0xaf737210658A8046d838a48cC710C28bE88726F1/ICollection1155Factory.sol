// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollection1155Factory {
    function createCollection(
        string memory uri,
        string memory collectionName, 
        string memory collectionSymbol
    ) external returns (address clone_);
    function getImplementationContract() external view returns (address);
    function setImplementationContract(address implementationContract_) external;
}
