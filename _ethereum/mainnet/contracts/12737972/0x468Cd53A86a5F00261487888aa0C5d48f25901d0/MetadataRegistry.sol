pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";

contract MetadataRegistry is Ownable {
  using LibSafeMath for uint256;

  mapping(uint256 => mapping(string => Document)) public tokenIdToDocumentMap;
  mapping(address => bool) public permissedWriters;

	struct Document {
		address writer;
		string text;
		uint256 creationTime;
	}

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

  function writeDocuments(uint256 tokenId, string[] memory keys, string[] memory texts, address[] memory writers) public onlyIfPermissed(msg.sender) {
    require(keys.length == texts.length, "keys and txHashes size mismatch");
    require(writers.length == texts.length, "writers and texts size mismatch");
    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      string memory text = texts[i];
      address writer = writers[i];
      tokenIdToDocumentMap[tokenId][key] = Document(writer, text, block.timestamp);
      emit UpdatedDocument(tokenId, writer, key, text); 
    }
  }
}