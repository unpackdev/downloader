pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinSignature.sol";

contract TokenMetadataRegistry is Ownable, MixinSignature {
  using LibSafeMath for uint256;

  ERC1155Mintable public mintableErc1155;

  mapping(uint256 => mapping(string => Document)) public tokenIdToDocumentMap;

	struct Document {
		address writer;
		string text;
		uint creationTime;
	}

  struct SignedText {
    address writer;
    string text;
    uint256 salt;
    bytes signature;
  }

  constructor(
    address _mintableErc1155
  ) {
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
  }

  event UpdatedDocument(
      uint256 tokenId,
      address writer,
      string key,
      string text,
      uint256 salt,
      bytes signature
  );

  function getSignedTextHash(SignedText memory signedText) public pure returns(bytes32) {
      return keccak256(abi.encodePacked(signedText.writer, signedText.text, signedText.salt)) ;
  }

  function verifySignedDocument(SignedText memory signedText) public pure returns(bool) {
    bytes32 signedHash = getSignedTextHash(signedText);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signedText.signature);
    return isSigned(signedText.writer, signedHash, v, r, s);
  }

  modifier onlyTokenOwner(uint256 tokenId, address owner) {
    require(mintableErc1155.ownerOf(tokenId) == owner, 'do not have permission to write docs');
    _;
  }

  function writeAndVerifyDocuments(uint256 tokenId, string[] memory keys, SignedText[] memory signedTexts) public onlyTokenOwner(tokenId, msg.sender) {
    require(keys.length == signedTexts.length, "tokenIds and txHashes size mismatch");
    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      SignedText memory signedText = signedTexts[i];
      require(verifySignedDocument(signedText) == true, 'invalid signature');
      tokenIdToDocumentMap[tokenId][key] = Document(signedText.writer, signedText.text, block.timestamp);
      emit UpdatedDocument(tokenId, signedText.writer, key, signedText.text, signedText.salt, signedText.signature ); 
    }
  } 

  function writeDocuments(uint256 tokenId, string[] memory keys, string[] memory texts) public onlyTokenOwner(tokenId, msg.sender) {
    require(keys.length == texts.length, "tokenIds and txHashes size mismatch");
    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      string memory text = texts[i];
      tokenIdToDocumentMap[tokenId][key] = Document(msg.sender, text, block.timestamp);
      emit UpdatedDocument(tokenId, msg.sender, key, text, 0, ""); 
    }
  }
}