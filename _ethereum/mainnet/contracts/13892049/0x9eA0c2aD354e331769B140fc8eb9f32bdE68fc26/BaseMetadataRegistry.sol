pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./MixinOwnable.sol";
import "./LibString.sol";
import "./IMetadataRegistry.sol";

contract BaseMetadataRegistry is Ownable, IMetadataRegistry {
  uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

  mapping(uint256 => mapping(string => IMetadataRegistry.Document)) public tokenTypeToBaseURIMap;
  mapping(address => bool) public permissedWriters;

  constructor(
  ) {
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

  function writeDocuments(uint256 tokenType, string[] memory keys, string[] memory texts, address[] memory writers) public onlyIfPermissed(msg.sender) {
    require(keys.length == texts.length, "keys and txHashes size mismatch");
    require(writers.length == texts.length, "writers and texts size mismatch");
    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      string memory text = texts[i];
      address writer = writers[i];
      tokenTypeToBaseURIMap[tokenType][key] = IMetadataRegistry.Document(writer, text, block.timestamp);
      emit UpdatedDocument(tokenType, writer, key, text); 
    }
  }

  function _getNonFungibleBaseType(uint256 id) pure internal returns (uint256) {
    return id & TYPE_MASK;
  }

  function tokenIdToDocument(uint256 tokenId, string memory key) override external view returns (IMetadataRegistry.Document memory) {
    IMetadataRegistry.Document memory doc = tokenTypeToBaseURIMap[_getNonFungibleBaseType(tokenId)][key];
    string memory text =  LibString.strConcat(
        doc.text,
        LibString.uint2hexstr(tokenId)
    );
    return IMetadataRegistry.Document(doc.writer, text, doc.creationTime); 
  }
}