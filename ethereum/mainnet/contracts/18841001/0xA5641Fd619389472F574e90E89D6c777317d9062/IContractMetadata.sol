// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractMetadata {
    function contractURI() external view returns (string memory);
    function setContractURI(string calldata _uri) external;
    event ContractURIUpdated(string prevURI, string newURI);
}
