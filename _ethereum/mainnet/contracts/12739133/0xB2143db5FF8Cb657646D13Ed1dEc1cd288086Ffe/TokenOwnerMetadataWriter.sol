pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibString.sol";
import "./MetadataRegistry.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinSignature.sol";
import "./MixinPausable.sol";

contract TokenOwnerMetadataWriter {

  MetadataRegistry public metadataRegistry;
  ERC1155Mintable public mintableErc1155;

  constructor(
    address _mintableErc1155,
    address _metadataRegistry
  ) {
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    metadataRegistry = MetadataRegistry(_metadataRegistry);
  }

  modifier onlyTokenOwner(uint256 tokenId, address owner) {
    require(mintableErc1155.ownerOf(tokenId) == owner, 'do not have permission to write docs');
    _;
  }

  function writeDocuments(uint256 tokenId, string[] memory keys, string[] memory texts) public onlyTokenOwner(tokenId, msg.sender) {
    require(keys.length == texts.length, "keys and texts size mismatch");
    address[] memory writers = new address[](keys.length);
    for (uint256 i = 0; i < keys.length; ++i) {
      writers[i] = msg.sender;
    }
    metadataRegistry.writeDocuments(tokenId, keys, texts, writers);
  }

}