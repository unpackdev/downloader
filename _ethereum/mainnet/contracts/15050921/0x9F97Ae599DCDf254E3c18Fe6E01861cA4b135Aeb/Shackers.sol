// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract Shackers is
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
ERC721BurnableUpgradeable,
ERC721URIStorageUpgradeable,
AccessControlUpgradeable,
UUPSUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // season one shackers can be migrated from the OpenSea contract, consider them reserved/minted
  uint256 public constant LEGACY_SHACKERS_MAX_ID = 128;

  event ShackerMinted(address account, uint256 tokenId);

  // region storage
  // once declared the types, order etc of variables MUST NOT BE changed
  // (constants are excluded since there is no storage space for those)
  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable

  uint256 _currentTokenId;

  string public baseUri;

  // endregion

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address minterAddress,
    string calldata _baseUri
  ) public initializer {
    __ERC721_init("Shackers", "SHACKERS");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();
    __ERC721URIStorage_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, minterAddress);

    _currentTokenId = LEGACY_SHACKERS_MAX_ID;

    baseUri = _baseUri;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  // region metadata

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  /*
   * @notice Sets a new metadata base uri.
   */
  function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseUri = newBaseURI;
  }

  // endregion

  // region minting

  /**
   * @notice Mints multiple Shackers to sender.
   */
  function mintMultiple(uint256 amount) external onlyRole(MINTER_ROLE) {
    for (uint256 i; i < amount; i++) {
      mint(msg.sender, ++_currentTokenId, "");
    }
  }

  /**
   * @notice Mints a single Shacker to sender. ID will be determined by the internal counter.
   */
  function mintSingle(string calldata tokenUri) public onlyRole(MINTER_ROLE) {
    mint(msg.sender, ++_currentTokenId, tokenUri);
  }

  /**
   * @notice Mints a single Shacker for a given token id.
   */
  function mint(address to, uint256 tokenId, string memory tokenUri) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
    if (bytes(tokenUri).length > 0) {
      _setTokenURI(tokenId, tokenUri);
    }
    emit ShackerMinted(to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
    return super._burn(tokenId);
  }

  // endregion

  // region withdraw funds and tokens

  // we don't expect ETH landing in this contract, but if it does allow to withdraw it
  function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
    AddressUpgradeable.sendValue(payable(msg.sender), address(this).balance);
  }

  // @dev allow to retrieve ERC20 tokens sent to the contract
  function withdrawERC20(IERC20 token, address toAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.transfer(toAddress, amount);
  }

  // @dev allow to retrieve ERC721 tokens sent to the contract
  function withdrawERC721(IERC721 token, address toAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.transferFrom(address(this), toAddress, tokenId);
  }

  // @dev allow to retrieve ERC1155 tokens (wrongfully) sent to the contract
  function withdrawERC1155(IERC1155 token, address toAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.safeTransferFrom(address(this), toAddress, tokenId, token.balanceOf(address(this), tokenId), "");
  }

  receive() external payable {}

  // endregion

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal
  override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
