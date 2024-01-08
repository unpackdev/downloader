pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./MixinOwnable.sol";
import "./LibString.sol";
import "./IMetadataRegistry.sol";
import "./MetadataRegistry.sol";

contract LegacyProxyMetadataRegistry is Ownable, IMetadataRegistry {

  MetadataRegistry public immutable legacyRegistry;

  constructor(
    address legacyRegistry_
  ) {
    legacyRegistry = MetadataRegistry(legacyRegistry_); 
  }

  function tokenIdToDocument(uint256 tokenId, string memory key) override external view returns (IMetadataRegistry.Document memory) {
    (address writer, string memory text, uint creationTime) = legacyRegistry.tokenIdToDocumentMap(tokenId, key);
    IMetadataRegistry.Document memory doc = IMetadataRegistry.Document(writer, text, creationTime); 
    return doc; 
  }
}