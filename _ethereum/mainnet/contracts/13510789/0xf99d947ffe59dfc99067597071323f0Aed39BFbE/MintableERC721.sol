// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./MyPausableUpgradeable.sol";

/**
 * @title MintableERC721
 * This is the base contract for LP tokens that are created by the CrossChainBridgeERC721 contract
 */
contract MintableERC721 is ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, MyPausableUpgradeable {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant MANAGE_TOKEN_ROLE = keccak256('MANAGE_TOKEN_ROLE');

  string private _internalBaseURI;
  string private _customName;
  string private _customSymbol;

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   *
   * @dev can only be called once after deployment of the contract
   * @param initName The name of the token to be created
   * @param initSymbol The symbol of the token to be created
   */
  function initialize(
    string memory initName,
    string memory initSymbol,
    string memory baseURI
  ) external initializer {
    // call parent initializers
    __ERC721_init_unchained(initName, initSymbol); // must be called here since there is no such call in the parent contracts
    __ERC721Enumerable_init();
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(MANAGE_TOKEN_ROLE, _msgSender());
    _internalBaseURI = baseURI;
    _customName = initName;
    _customSymbol = initSymbol;
  }

  function burn(uint256 tokenId) external virtual whenNotPaused {
    require(_isApprovedOrOwner(_msgSender(), tokenId), 'MintableERC721: caller is neither owner nor approved');
    _burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721EnumerableUpgradeable, AccessControlUpgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory newBaseUri) external {
    require(
      hasRole(MANAGE_TOKEN_ROLE, _msgSender()),
      'MintableERC721: must have MANAGE_TOKEN_ROLE to execute this function'
    );
    _internalBaseURI = newBaseUri;
  }

  function mint(address to, uint256 tokenId) public virtual whenNotPaused {
    require(hasRole(MINTER_ROLE, _msgSender()), 'MintableERC721: must have MINTER_ROLE to execute this function');
    _mint(to, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    whenNotPaused
  {
    super._burn(tokenId);
  }

  function _baseURI() internal view override returns (string memory) {
    return _internalBaseURI;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
    require(
      hasRole(MANAGE_TOKEN_ROLE, _msgSender()),
      'MintableERC721: must have MANAGE_TOKEN_ROLE to execute this function'
    );
    super._setTokenURI(tokenId, _tokenURI);
  }

  function setName(string memory newName) external {
    require(
      hasRole(MANAGE_TOKEN_ROLE, _msgSender()),
      'MintableERC721: must have MANAGE_TOKEN_ROLE to execute this function'
    );
    _customName = newName;
  }

  function setSymbol(string memory newSymbol) external {
    require(
      hasRole(MANAGE_TOKEN_ROLE, _msgSender()),
      'MintableERC721: must have MANAGE_TOKEN_ROLE to execute this function'
    );
    _customSymbol = newSymbol;
  }

  function name() public view override returns (string memory) {
    return _customName;
  }

  function symbol() public view override returns (string memory) {
    return _customSymbol;
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    super.safeTransferFrom(from, to, tokenId);
  }
}
