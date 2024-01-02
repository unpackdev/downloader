// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SNS.sol";
import "./ControllableUpgradeable.sol";
import "./IBaseRegistrar.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";

contract BaseRegistrar is
  IBaseRegistrar,
  Initializable,
  ControllableUpgradeable,
  ERC721Upgradeable
{
  SNS public sns;

  bytes32 public rootNode;

  uint256 private _nextTokenId;

  // for example: "abcd.seedao" => 1, the mapping is:
  //     labelToTokenId[namehash('abcd')] = 1
  //     tokenIdToLabel[1] = namehash('abcd')
  // not `namehash('abcd.seedao')` !!
  // so the name is `labelToTokenId` not `nodeToTokenId`
  mapping(bytes32 => uint256) public labelToTokenId;
  mapping(uint256 => bytes32) public tokenIdToLabel;

  // ERC721 token's baseURI
  string public baseURI;
  // enable/disable ERC721 transfer feature flag
  bool public transferable;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    SNS _sns,
    bytes32 node,
    string memory tokenName,
    string memory tokenSymbol
  ) public initializer {
    __Controllable_init();
    __ERC721_init(tokenName, tokenSymbol);

    sns = _sns;
    rootNode = node;
  }

  function available(bytes32 label) public view returns (bool) {
    bytes32 subnode = keccak256(abi.encodePacked(rootNode, label));
    // return !sns.recordExists(subnode);
    return sns.owner(subnode) == address(0);
  }

  function nextTokenId() public view override returns (uint256) {
    return _nextTokenId;
  }

  function register(
    bytes32 label,
    address owner,
    address resolver
  ) public onlyController {
    bytes32 subnode = keccak256(abi.encodePacked(rootNode, label));

    // or call `available(label)` function instead
    require(sns.owner(subnode) == address(0), "Name already registered");

    // register sns
    sns.setSubnodeRecord(rootNode, label, owner, resolver, 0);

    // mint ERC721
    uint256 tokenId = _nextTokenId++;
    _mint(owner, tokenId);

    // save mapping data of label and tokenId
    labelToTokenId[label] = tokenId;
    tokenIdToLabel[tokenId] = label;

    emit NameRegistered(tokenId, owner);
  }

  function reclaim(bytes32 label, address newSNSOwner) public onlyController {
    // change sns owner
    sns.setSubnodeOwner(rootNode, label, newSNSOwner);

    // transfer ERC721
    uint256 tokenId = labelToTokenId[label];
    _transfer(_ownerOf(tokenId), newSNSOwner, tokenId);

    emit NameReclaimed(tokenId, newSNSOwner);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ token URI

  /// @dev set NFT URI base, must include the last "/"
  /// e.g：https://metadata.seedao.xyz/
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ enable/disable transfer feature

  function enableTransferable() public onlyOwner {
    transferable = true;
  }

  function disableTransferable() public onlyOwner {
    transferable = false;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ override `transferFrom` functions

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    require(transferable, "Transfer feature disabled");

    // change sns owner
    bytes32 label = tokenIdToLabel[tokenId];
    sns.setSubnodeOwner(rootNode, label, to);

    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override {
    require(transferable, "Transfer feature disabled");

    // change sns owner
    bytes32 label = tokenIdToLabel[tokenId];
    sns.setSubnodeOwner(rootNode, label, to);

    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view override(ERC721Upgradeable) returns (bool) {
    return
      interfaceID == type(IBaseRegistrar).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
