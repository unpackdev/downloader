// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IThreeSpace.sol";
import "./IERC20BurnableUpgradeable.sol";
import "./ERC721NameChangeUpgradeable.sol";
import "./ERC721TradableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title ThreeSpace
 */
contract ThreeSpace is
  Initializable,
  ERC721EnumerableUpgradeable,
  ERC721URIStorageUpgradeable,
  ERC721BurnableUpgradeable,
  ERC721TradableUpgradeable,
  ERC721NameChangeUpgradeable,
  AccessControlUpgradeable,
  IThreeSpace
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  CountersUpgradeable.Counter private _tokenIdCounter;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    address proxyRegistryAddress_,
    address nameChangeToken_,
    uint256 nameChangePrice_
  ) external initializer {
    __ERC721_init('3SPACE ETH', 'SPACE');
    __ERC721Enumerable_init();
    __ERC721URIStorage_init();
    __AccessControl_init();
    __ERC721Burnable_init();
    __ERC721Tradable_init('3SPACE ETH', proxyRegistryAddress_);
    __ERC721NameChange_init(nameChangeToken_, nameChangePrice_);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function updateNameChangeToken(address token) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only Admin can update');
    _nameChangeToken = token;
  }

  function updateNameChangePrice(uint256 price) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only Admin can update');
    _nameChangePrice = price;
  }

  function changeName(uint256 tokenId, string memory newName) public override {
    super.changeName(tokenId, newName);

    IERC20BurnableUpgradeable(nameChangeToken()).burn(nameChangePrice());
  }

  function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
    _safeMint(to, _tokenIdCounter.current());
    _setTokenURI(_tokenIdCounter.current(), uri);
    _tokenIdCounter.increment();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721TradableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(
      ERC721Upgradeable,
      ERC721EnumerableUpgradeable,
      AccessControlUpgradeable,
      ERC721TradableUpgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override(ERC721Upgradeable, ERC721TradableUpgradeable)
    returns (bool)
  {
    return super.isApprovedForAll(owner, operator);
  }

  function _msgSender()
    internal
    view
    override(ContextUpgradeable, ERC721TradableUpgradeable)
    returns (address sender)
  {
    return super._msgSender();
  }
}
