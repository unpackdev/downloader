pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./MixinOwnable.sol";
import "./LibString.sol";
import "./IMetadataRegistry.sol";

contract DerivedMetadataRegistry is Ownable, IMetadataRegistry {
  IMetadataRegistry public immutable sourceRegistry;

  mapping(uint256 => mapping(string => IMetadataRegistry.Document)) public tokenIdToDocumentMap;
  mapping(address => bool) public permissedWriters;

  constructor(address sourceRegistry_) {
    sourceRegistry = IMetadataRegistry(sourceRegistry_);
  }

  event UpdatedDocument(
      uint256 indexed tokenId,
      address indexed writer,
      string indexed key,
      string text
  );

  function updatePermissedWriterStatus(address _writer, bool status) public onlyOwner {
    permissedWriters[_writer] = status;
  }

  modifier onlyIfPermissed(address writer) {
    require(permissedWriters[writer] == true, "writer can't write to registry");
    _;
  }

  function writeDocuments(uint256 tokenId, string[] memory keys, string[] memory texts, address[] memory writers) public onlyIfPermissed(msg.sender) {
    require(keys.length == texts.length, "keys and txHashes size mismatch");
    require(writers.length == texts.length, "writers and texts size mismatch");
    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      string memory text = texts[i];
      address writer = writers[i];
      tokenIdToDocumentMap[tokenId][key] = IMetadataRegistry.Document(writer, text, block.timestamp);
      emit UpdatedDocument(tokenId, writer, key, text); 
    }
  }

  function tokenIdToDocument(uint256 tokenId, string memory key) override external view returns (IMetadataRegistry.Document memory) {
    IMetadataRegistry.Document memory sourceDoc = sourceRegistry.tokenIdToDocument(tokenId, key);
    if (bytes(sourceDoc.text).length == 0) {
      return IMetadataRegistry.Document(address(0), "", 0);
    }
    IMetadataRegistry.Document memory doc = tokenIdToDocumentMap[tokenId][sourceDoc.text];
    return doc; 
  }
}