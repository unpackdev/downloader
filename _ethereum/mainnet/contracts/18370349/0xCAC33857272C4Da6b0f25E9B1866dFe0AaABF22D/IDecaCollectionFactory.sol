// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IDecaCollection.sol";

interface IDecaCollectionFactory {
  error CreatorCannotBeTheZeroAddress();
  error OnlyCreator();
  error OnlyMinter();
  error InterfaceUnsupported();

  /**
   * @notice Emitted when a new DecaCollection is created from this factory.
   * @param collection The address of the new NFT collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param collectionName The name of the collection.
   */
  event DecaCollectionCreated(address indexed collection, address indexed creator, string collectionName);

  /**
   * @notice Emitted when the metadata resolver is updated.
   * @param metadataResolver The address of the new metadata resolver.
   */
  event MetadataResolverUpdated(address indexed metadataResolver);

  /**
   * @notice Emitted when the implementation of DecaCollection is updated.
   * @param decaCollectionImplementation The address of the new implementation.
   * @param newVersion The new version of the implementation.
   */
  event DecaCollectionImplementationUpdated(address decaCollectionImplementation, uint256 newVersion);

  struct CreateDecaCollectionParams {
    address creator;
    uint96 nonce;
    Recipient[] recipients;
    string collectionName;
    string collectionSymbol;
  }

  function createDecaCollection(CreateDecaCollectionParams memory params) external returns (address);

  function tokenUri(address contractAddress, uint256 tokenId) external view returns (string memory);
}
