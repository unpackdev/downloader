// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IAuction_House_V1_0.sol";

contract Auction_House_V1_0 is Initializable, ERC721Upgradeable, AccessControlUpgradeable, UUPSUpgradeable, IAuction_House_V1_0 {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


  mapping(uint256 => bool) public pausedTokens;

  string baseURI;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {}

  function initialize(string memory name, string memory symbol) public initializer {
    __ERC721_init(name, symbol);
    __UUPSUpgradeable_init();
    __AccessControl_init();

    baseURI = 'https://iyk.app/api/metadata/1155/';

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPGRADER_ROLE, msg.sender);
    _setupRole(URI_SETTER_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
  }

  // Overidden to guard against which users can access - gated to UPGRADER_ROLE
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {}

  function setBaseURI(string memory uri) external onlyRole(URI_SETTER_ROLE) {
    baseURI = uri;
  }

  function mint(address recipient, uint256 tokenId) external onlyRole(MINTER_ROLE) {
    _safeMint(recipient, tokenId);
  }


  function togglePause(uint256 tokenId) external override onlyRole(PAUSER_ROLE) {
    emit Pause(tokenId, pausedTokens[tokenId] = !pausedTokens[tokenId]);
  }

  function redeem(uint256 tokenId) external override {
    require(!pausedTokens[tokenId], 'Token has already been paused');
    require(ownerOf(tokenId) == msg.sender, 'Only the token owner can pause a token');
    pausedTokens[tokenId] = true;
    emit Pause(tokenId, true);
    emit Redeem(tokenId, msg.sender);
  }

  function isPaused(uint256 tokenId) external override view returns(bool) {
    return pausedTokens[tokenId];
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(!pausedTokens[tokenId], 'Paused: intermediate token has been paused');
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }
}
