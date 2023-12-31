// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./InfluenceRoles.sol";


/**
 * @dev Contract that models each crew member as an ERC721, non-fungible token.
 */
contract CrewmateToken is ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, AccessControlUpgradeable, OwnableUpgradeable, ERC721PausableUpgradeable {
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  CountersUpgradeable.Counter private _tokenIdTracker;

  // Base URI
  string private __baseURI;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  function initialize (string memory name_, string memory symbol_) public initializer {
    __ERC721_init(name_, symbol_);

    __Pausable_init();

    __Ownable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(InfluenceRoles.MANAGER_ROLE, _msgSender());

    // Start our ids from 1
    _tokenIdTracker.increment();
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC165Upgradeable, IERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Pauses the contract and prevents transfers / burns
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses the contract allowing transfers / burns
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Allowed managers (including sale contract) can mint initial asterodis
   * @param _to The purchaser's address
   * @param _tokenId The token ID to mint
   */
  function mint(address _to, uint256 _tokenId) external onlyRole(InfluenceRoles.MANAGER_ROLE) {
    _safeMint(_to, _tokenId);
  }

  /**
   * @dev Burns a token
   * @param _tokenId uint256 ID of the token being burned
   */
  function burn(uint256 _tokenId) external onlyRole(InfluenceRoles.MANAGER_ROLE) {
    _burn(_tokenId);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view override(IERC721MetadataUpgradeable, ERC721Upgradeable) returns (string memory) {
    string memory base = baseURI();
    return string(abi.encodePacked(base, tokenId.toString()));
  }

  /**
   * @dev External interface to set the base URI for all token IDs.
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    _setBaseURI(baseURI_);
  }

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a prefix in {tokenURI} to each token's URI, or
  * to the token ID if no specific URI is set for that token ID.
  */
  function baseURI() public view returns (string memory) {
    return __baseURI;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}. Enumerable extension is not implemented fully,
   * but totalSupply is included for better compatibility.
   */
  function totalSupply() public view returns (uint256) {
    return _tokenIdTracker.current() - 1;
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal override whenNotPaused {
    require(tokenId > 0, "ERC721: invalid token ID");
    super._mint(to, tokenId);
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal {
    __baseURI = baseURI_;
  }
}
