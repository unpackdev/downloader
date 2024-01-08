pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibString.sol";
import "./MetadataRegistry.sol";
import "./HashRegistry.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./MixinSignature.sol";
import "./MixinPausable.sol";
import "./ReentrancyGuard.sol";

contract SignedTextMetadataWriter is MixinSignature, ReentrancyGuard {

  MetadataRegistry public metadataRegistry;
  ERC1155Mintable public mintableErc1155;
  HashRegistry public hashRegistry;

  constructor(
    address _mintableErc1155,
    address _metadataRegistry,
    address _hashRegistry
  ) {
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    metadataRegistry = MetadataRegistry(_metadataRegistry);
    hashRegistry = HashRegistry(_hashRegistry);
  }

  struct SignedText {
    address writer;
    string text;
    uint256 txHash;
    uint256 fee;
    bytes signature;
    uint256 createdAt;
  }

  event WroteSignedText(
      uint256 indexed tokenId,
      address indexed writer,
      string indexed key,
      string text,
      uint256 txHash,
      uint256 fee,
      bytes signature
  );

  modifier onlyTokenOwner(uint256 tokenId, address owner) {
    require(mintableErc1155.ownerOf(tokenId) == owner, 'do not have permission to write docs');
    _;
  }

  function getSignedTextHash(SignedText memory signedText) public pure returns(bytes32) {
      return keccak256(abi.encodePacked(signedText.writer, signedText.text, signedText.txHash, signedText.fee, signedText.createdAt)) ;
  }

  function verifySignedDocument(SignedText memory signedText) public pure returns(bool) {
    bytes32 signedHash = getSignedTextHash(signedText);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signedText.signature);
    return isSigned(signedText.writer, signedHash, v, r, s);
  }

  function writeDocuments(uint256 tokenId, string[] memory keys, SignedText[] memory signedTexts) public payable nonReentrant() onlyTokenOwner(tokenId, msg.sender) {
    require(keys.length == signedTexts.length, "keys and signedTexts size mismatch");
    address[] memory writers = new address[](keys.length);
    string[] memory texts = new string[](keys.length);

    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      SignedText memory signedText = signedTexts[i];
      require(verifySignedDocument(signedText) == true, 'invalid signature');
      require(hashRegistry.tokenIdToTxHash(tokenId) == signedText.txHash, 'invalid signedText for hash');
      writers[i] = signedText.writer;
      texts[i] = signedText.text;
      signedText.writer.call{value: signedText.fee }("");
      emit WroteSignedText(tokenId, signedText.writer, key, signedText.text, signedText.txHash, signedText.fee, signedText.signature );
    }
    metadataRegistry.writeDocuments(tokenId, keys, texts, writers);
    msg.sender.call{value: address(this).balance }("");
  }
}