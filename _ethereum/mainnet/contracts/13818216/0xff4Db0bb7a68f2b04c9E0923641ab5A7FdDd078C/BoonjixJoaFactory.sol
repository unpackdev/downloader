// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./NFTFactory.sol";
import "./IGovernance.sol";

/// @title BoonjixJoaFactory
contract BoonjixJoaFactory is ERC721, ERC721URIStorage, NFTFactory, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  address private zkSyncAddress;

  string private metadataExtension;
  string private baseURI;

  modifier onlyZkSync() {
    require(msg.sender == zkSyncAddress, "BoonjixJoaFactory:: only zkSyncAddress");
    _;
  }

  /// @dev contract contructor
  /// @param name NFT name
  /// @param symbol NFT symbol
  /// @param extension the metadata file extension on Storj
  /// @param __baseURI the metadata base uri
  /// @param _zkSyncAddress contract adddress for zksync
  constructor(
    string memory name,
    string memory symbol,
    string memory extension,
    string memory __baseURI,
    address _zkSyncAddress
  ) ERC721(name, symbol) {
    zkSyncAddress = _zkSyncAddress;

    metadataExtension = extension;
    baseURI = __baseURI;
  }

  /// @dev registers a creator with the zksync Governance contract to bridge tokens from l2
  /// @param governance the zksync Governance contract
  /// @param _creatorAccountId the creator account id on zksync
  /// @param creator a whitelisted creator
  /// @param signature payload signed by creator
  function registerFactory(
    address governance,
    uint32 _creatorAccountId,
    address creator,
    bytes calldata signature
  ) external onlyOwner {
    IGovernance(governance).registerNFTFactoryCreator(_creatorAccountId, creator, signature);
  }

  /// @dev mints a token from zksync l2
  /// @notice only the zksync contract can call
  /// @param creator original minter on l2
  /// @param recipient account to receive token on l1
  /// @param creatorAccountId creator account id on l2
  /// @param serialId enumerable id of tokens minted by the creator
  /// @param contentHash bytes32 hash of token uri
  /// @param tokenId the token id (from l2)
  function mintNFTFromZkSync(
    address creator,
    address recipient,
    uint32 creatorAccountId,
    uint32 serialId,
    bytes32 contentHash,
    uint256 tokenId
  ) external override onlyZkSync {
    _tokenIds.increment(); // just using as a counter for #totalSupply()

    uint256 recoveredTokenId = uint(contentHash);
    _safeMint(recipient, recoveredTokenId);
    _setTokenURI(recoveredTokenId, _getURI(recoveredTokenId, metadataExtension));

    emit MintNFTFromZkSync(creator, recipient, creatorAccountId, serialId, contentHash, tokenId);
  }

  /// @dev returns the metadata uri for a given token
  /// @param tokenId the token id
  function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns(string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }

  /// @dev returns the number to tokens minted
  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  /// @dev allows the contract owner to set the baseURI
  /// @param __baseURI the new base uri
  function setBaseURI(string memory __baseURI) external onlyOwner {
    baseURI = __baseURI;
  }

  /// @dev allows the contract owner to set the zksync address
  /// @param _zkSyncAddress the new zk sync address
  function setZkSyncAddress(address _zkSyncAddress) external onlyOwner {
    zkSyncAddress = _zkSyncAddress;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _getURI(uint256 tokenId, string memory fileExtension) internal pure returns (string memory) {
    return string(abi.encodePacked(Strings.toString(tokenId), fileExtension));
  }

  /// @dev not actually used, just need to appease the overrides
  function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
    ERC721URIStorage._burn(tokenId);
  }
}
