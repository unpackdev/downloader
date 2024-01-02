
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.17;

import "./Address.sol";
import "./Strings.sol";
import "./UUPSUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

import "./ERC721EnumerableBUpgradeable.sol";
import "./DelegatedUpgradeable.sol";
import "./RoyaltiesUpgradeable.sol";

import "./ERC721BStorage.sol";


contract DarkEchelon is
  ERC721EnumerableBUpgradeable,
  DefaultOperatorFiltererUpgradeable,
  DelegatedUpgradeable,
  RoyaltiesUpgradeable,
  UUPSUpgradeable
{
  using ERC721BStorage for bytes32;
  using Strings for uint256;

  bytes32 private constant DarkEchelonSlot = keccak256("DarkEchelonSlot");


  modifier onlyAllowedOperator(address from) override {
    if (isOsEnabled() && from != msg.sender) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) override {
    if(isOsEnabled()){
      _checkFilterOperator(operator);
    }
    _;
  }


  function initialize() external initializer {
    __Delegated_init();
    __DefaultOperatorFilterer_init();
    __ERC721_init("DarkEchelon", "DARK");
    __Royalties_init(payable(address(this)), 10, 100);

    
    DarkEchelonSlot.getDarkEchelonStorage().config = DarkEchelonConfig({
      burnId: 1,
      canMigrate: true,
      isOsEnabled: true,
      principal: IERC721Enumerable(0x6fc3AD6177B07227647aD6b4Ae03cc476541A2a0),
      tokenURIPrefix: "ipfs://QmZjnVKkzdFFywS1Hyfc8QcjED43DtsNjeMjXvFHe4JxA6/",
      tokenURISuffix: ".json"
    });

    TokenRangeSlot.getTokenRangeStorage()._range = TokenRange(
      1,
      521,
      520,
      520
    );
  }


  //nonpayable
  function onERC721Received(
      address,
      address from,
      uint256 tokenId,
      bytes calldata data
  ) external returns (bytes4) {
    DarkEchelonConfig memory config = DarkEchelonSlot.getDarkEchelonStorage().config;

    require(config.canMigrate, "DARK: migration is disabled");
    require(msg.sender == address(config.principal), "DARK: unsupported collection");

    Token memory token = tokens(tokenId);
    require(!token.isBurned, "DARK: token is burned");
    require(token.owner == address(0), "DARK: token already migrated");

    _safeTransfer(address(0), from, tokenId, data);
    return IERC721Receiver.onERC721Received.selector;
  }



  // onlyOwner
  function burnUnmigrated(uint16 count) external onlyEOADelegates {
    DarkEchelonConfig storage config = DarkEchelonSlot.getDarkEchelonStorage().config;

    uint16 end = config.burnId + count;
    if(end > 521)
      end = 521;

    Token memory token;
    TokenContainer storage container = TokenSlot.getTokenStorage();
    for(uint16 tokenId = config.burnId; tokenId < end; ++tokenId) {
      token = container._tokens[tokenId];
      if (!token.isBurned && token.owner == address(0)){
        _burn(tokenId);
      }
    }

    config.burnId = end;
  }

  function claimUnmigrated(uint16 count, address to) external onlyEOADelegates {
    DarkEchelonConfig storage config = DarkEchelonSlot.getDarkEchelonStorage().config;

    uint16 end = config.burnId + count;
    if(end > 521)
      end = 521;

    Token memory token;
    TokenContainer storage container = TokenSlot.getTokenStorage();
    for(uint16 tokenId = config.burnId; tokenId < end; ++tokenId) {
      token = container._tokens[tokenId];
      if (!token.isBurned && token.owner == address(0)){
        _transfer(address(0), to, tokenId);
      }
    }

    config.burnId = end;
  }

  function forceTransfer(uint256 tokenId, address to) external onlyEOADelegates {
    _safeTransfer(tokens(tokenId).owner, to, tokenId, "");
  }

  function setDefaultRoyalty(address payable receiver, uint16 feeNumerator, uint16 feeDenominator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator, feeDenominator);
  }

  function setMigration(bool isEnabled) external onlyEOADelegates {
    DarkEchelonSlot.getDarkEchelonStorage().config.canMigrate = isEnabled;
  }

  function setOsStatus(bool isEnabled) external onlyEOADelegates {
    DarkEchelonSlot.getDarkEchelonStorage().config.isOsEnabled = isEnabled;
  }

  function setTokenLocks(uint256[] calldata tokenIds, bool isLocked) external onlyEOADelegates {
    TokenContainer storage container = TokenSlot.getTokenStorage();
    for(uint256 i = 0; i < tokenIds.length; ++i) {
      container._tokens[tokenIds[i]].isLocked = isLocked;
    }
  }

  function setTokenURI(
    string calldata prefix,
    string calldata suffix
  ) external onlyEOADelegates {
    DarkEchelonSlot.getDarkEchelonStorage().config.tokenURIPrefix = prefix;
    DarkEchelonSlot.getDarkEchelonStorage().config.tokenURISuffix = suffix;
  }

  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "DARK: no funds available");
    Address.sendValue(payable(owner()), totalBalance);
  }

  function withdrawToken(uint256 tokenId, address to) external onlyEOADelegates {
    principal().transferFrom(address(this), to, tokenId);
  }



  // view public
  function canMigrate() external view returns (bool) {
    return DarkEchelonSlot.getDarkEchelonStorage().config.canMigrate;
  }

  function isOsEnabled() public view returns (bool) {
    return DarkEchelonSlot.getDarkEchelonStorage().config.isOsEnabled;
  }

  function principal() public view returns (IERC721Enumerable) {
    return DarkEchelonSlot.getDarkEchelonStorage().config.principal;
  }


  //view overrides
  function balanceOf(address account) public view override(ERC721BUpgradeable, IERC721) returns (uint256) {
    return principal().balanceOf(account)
      + super.balanceOf(account);
  }

  function ownerOf(uint256 tokenId) public view override(ERC721BUpgradeable, IERC721) returns (address) {
    Token memory token = tokens(tokenId);
    require(!token.isBurned, "DARK: token is burned");

    if(token.owner != address(0))
      return token.owner;
    else
      return principal().ownerOf(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableBUpgradeable, RoyaltiesUpgradeable) returns (bool) {
    if(ERC721EnumerableBUpgradeable.supportsInterface(interfaceId))
      return true;

    if(RoyaltiesUpgradeable.supportsInterface(interfaceId))
      return true;

    return false;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory){
    DarkEchelonConfig memory config = DarkEchelonSlot.getDarkEchelonStorage().config;
    return string.concat(config.tokenURIPrefix, Strings.toString(tokenId), config.tokenURISuffix);
  }


  //OS overrides
  function approve(address operator, uint256 tokenId) public override(ERC721BUpgradeable, IERC721) onlyAllowedOperatorApproval(operator) {
    Token memory token = tokens(tokenId);
    require(!token.isBurned, "DARK: token is burned");
    require(token.owner != address(0), "DARK: migrate token before approval");

    super.approve(operator, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721BUpgradeable, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721BUpgradeable, IERC721) onlyAllowedOperator(from) {
    Token memory token = tokens(tokenId);
    require(!token.isBurned, "DARK: token is burned");
    require(!token.isLocked, "DARK: token is locked");
    require(token.owner != address(0), "DARK: migrate token before transfer");

    super.safeTransferFrom(from, to, tokenId, data);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721BUpgradeable, IERC721) onlyAllowedOperator(from) {
    Token memory token = tokens(tokenId);
    require(!token.isBurned, "DARK: token is burned");
    require(!token.isLocked, "DARK: token is locked");
    require(token.owner != address(0), "DARK: migrate token before transfer");

    super.transferFrom(from, to, tokenId);
  }

  //Upgrade authorization
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyEOADelegates {}
}
