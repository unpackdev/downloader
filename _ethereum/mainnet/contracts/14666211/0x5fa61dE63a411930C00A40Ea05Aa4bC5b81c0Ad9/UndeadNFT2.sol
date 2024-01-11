// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract UndeadNFT2 is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string public baseUri;
  mapping(uint256 => uint256) public packageIds;
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

  event EBaseUri(string uri);
  event EPackage(uint256 tokenId, uint256 pkgId);

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  function __UndeadNFT2_init() external initializer {
    __Ownable_init();
    __ERC721_init("Undead Blocks Weapon Apocalypse", "WEAPONS");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    __AccessControl_init();
    __ReentrancyGuard_init();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }

  function setBaseUri(string memory uri) external onlyRole(EDITOR_ROLE) {
    baseUri = uri;
    emit EBaseUri(uri);
  }

  function multipleMint(
    address to,
    uint256 fromId,
    uint256 toId,
    uint256 pkgId
  ) external nonReentrant onlyRole(MINTER_ROLE) {
    for (uint256 i = fromId; i <= toId; i++) {
      _mint(to, i);
      packageIds[i] = pkgId;
    }
  }

  function mint(
    uint256 tokenId,
    address to,
    uint256 pkgId
  ) external nonReentrant onlyRole(MINTER_ROLE) {
    _mint(to, tokenId);
    packageIds[tokenId] = pkgId;
  }

  function setPackage(uint256 tokenId, uint256 pkgId) external onlyRole(EDITOR_ROLE) {
    packageIds[tokenId] = pkgId;
    emit EPackage(tokenId, pkgId);
  }

  function bulkBurn(uint256 fromId, uint256 toId) external onlyRole(BURNER_ROLE) {
    for (uint256 id = fromId; id <= toId; id++) {
      _burn(id);
    }
  }
}
