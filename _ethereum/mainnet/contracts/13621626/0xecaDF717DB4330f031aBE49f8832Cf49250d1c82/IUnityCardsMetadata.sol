// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUnityCardsMetadata {
  function setContractURI(string calldata URI) external;

  function setBaseURI(string calldata URI) external;

  function setRevealedBaseURI(string calldata revealedBaseURI) external;

  function contractURI() external view returns(string memory);
}