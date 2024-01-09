pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./MixinOwnable.sol";
import "./BaseMetadataRegistry.sol";
import "./HashRegistry.sol";

import "./IMetadataRegistry.sol";

contract MetadataCoordinator is Ownable {
  uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

  string public runnableOffchainScript;

  mapping(uint256 => mapping(uint256 => MetadataRegistryInfo)) public tokenTypeToMetadataRegistries;
  mapping(uint256 => uint256) public tokenTypeToMetadataRegistryMaxIndex;

  HashRegistry public hashRegistry;

	struct MetadataRegistryInfo {
		address registry;
    string key;
    string prefURI;
	}

  constructor(
    address _hashRegistry
  ) {
    hashRegistry = HashRegistry(_hashRegistry);
  }

  event UpdatedMetadataRegistryInfo(
      uint256 indexed tokenType,
      uint256 indexed index,
      address indexed registry,
      bool isBased
  );

  function setTokenTypeToMetadataRegistries(uint256 tokenType, uint256[] memory indexes, MetadataRegistryInfo[] memory infos) public onlyOwner {
    for (uint i = 0; i < indexes.length; ++i) {
      tokenTypeToMetadataRegistries[tokenType][indexes[i]] = infos[i];
    }
  }

  function setTokenTypeToMetadataRegistryMaxIndex(uint256 tokenType, uint256 maxIndex) public onlyOwner {
    tokenTypeToMetadataRegistryMaxIndex[tokenType] = maxIndex;
  }

  function setRunnableOffchainScript(string memory runnableOffchainScript_) public onlyOwner {
    runnableOffchainScript = runnableOffchainScript_;
  }

  function _getNonFungibleBaseType(uint256 id) pure internal returns (uint256) {
    return id & TYPE_MASK;
  }

  function tokenIdToDocuments(uint256 tokenId) public view returns (IMetadataRegistry.Document[] memory, MetadataRegistryInfo[] memory) {
    uint256 tokenType = _getNonFungibleBaseType(tokenId);
    uint256 maxIndex = tokenTypeToMetadataRegistryMaxIndex[tokenType];
    MetadataRegistryInfo[] memory infos = new MetadataRegistryInfo[](maxIndex);
    IMetadataRegistry.Document[] memory documents = new IMetadataRegistry.Document[](maxIndex);
    for (uint i = 0; i < maxIndex; ++i) {
      MetadataRegistryInfo memory info = tokenTypeToMetadataRegistries[tokenType][i];
      infos[i] = info;
      IMetadataRegistry registry = IMetadataRegistry(info.registry);
      IMetadataRegistry.Document memory doc = registry.tokenIdToDocument(tokenId, info.key);
      documents[i] = doc;
    }
    return (documents, infos);
  }

  function txHashToDocuments(uint256 txHash) public view returns (IMetadataRegistry.Document[] memory, MetadataRegistryInfo[] memory) {
    return tokenIdToDocuments(hashRegistry.txHashToTokenId(txHash));
  } 
}
