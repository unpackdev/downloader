// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INamelessTemplateLibrary {
  function getTemplate(uint256 templateIndex) external view returns (bytes32[] memory dataSection, bytes32[] memory codeSection);
  function getContentApis() external view returns (string memory arweaveContentApi, string memory ipfsContentApi);
}
