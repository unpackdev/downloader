// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IMaviaNFT.sol";
import "./IMaviaCreator.sol";
import "./OpenseaDelegate.sol";

/**
 * @title Mavia NFT
 *
 * @notice This contract contains base implementation of Mavia NFT contracts
 *
 * @dev This contract will have all the base functions related to ERC721 NFT
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract MaviaNFT is ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, IMaviaNFT, IMaviaCreator {
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

  mapping(uint256 => address) private _creators;
  mapping(uint256 => uint256) private _ownTime;

  string public uri;

  address public proxyRegistryAddress;
  bool public isOpenSeaProxyActive;

  event SetURI(string _uri);

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
    return
      _interfaceId == type(IMaviaNFT).interfaceId ||
      _interfaceId == type(IMaviaCreator).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * @dev Upgradable initializer
   * @param _pName Token name
   * @param _pSymbol Token symbol
   * @param _pUri URI string
   */
  function __MaviaNFT_init(
    string memory _pName,
    string memory _pSymbol,
    string memory _pUri
  ) public initializer {
    __Ownable_init();
    __AccessControl_init();
    __ERC721_init(_pName, _pSymbol);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    fSetURI(_pUri);
  }

  /**
   * @dev Return of base uri
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  /**
   * @notice Active opensea proxy - Emergency case
   * @dev This function is only callable by owner
   * @param _pProxyRegistryAddress Address of opensea proxy
   * @param _pIsOpenSeaProxyActive Active opensea proxy by assigning true value
   */
  function fActiveOpenseaProxy(address _pProxyRegistryAddress, bool _pIsOpenSeaProxyActive) public onlyOwner {
    proxyRegistryAddress = _pProxyRegistryAddress;
    isOpenSeaProxyActive = _pIsOpenSeaProxyActive;
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * @dev This function is only callable by owner
   * @param _pUri String of uri
   */
  function fSetURI(string memory _pUri) public onlyOwner {
    uri = _pUri;

    emit SetURI(_pUri);
  }

  /**
   * @dev Mint a new NFT
   * @param _pTo Address of the token owner
   * @param _pId token id
   */
  function fMint(address _pTo, uint256 _pId) external override onlyRole(MINTER_ROLE) {
    _mint(_pTo, _pId);
  }

  /**
   * @dev Mint a Bulk NFT
   * @param _pTo Address of the token owner
   * @param _pFromId token id from
   * @param _pToId token id to
   */
  function fBulkMint(
    address _pTo,
    uint256 _pFromId,
    uint256 _pToId
  ) external override onlyRole(MINTER_ROLE) {
    for (uint256 id_ = _pFromId; id_ <= _pToId; id_++) {
      _mint(_pTo, id_);
    }
  }

  /**
   * @notice Burn an NFT
   * @dev Burn an NFT by the token owner and Burner role
   * @param _pId Token id
   * Required Statements
   * - MaviaNFT:01 Only owner of NFT or whoever has burner role can burn
   */
  function fBurn(uint256 _pId) external override {
    require(ownerOf(_pId) == _msgSender() || hasRole(BURNER_ROLE, _msgSender()), "MaviaNFT:01");
    _burn(_pId);
  }

  /**
   * @notice Burn a Bulk NFT
   * @dev Burn an NFT by the token owner and Burner role
   * @param _pFromId Token id
   * @param _pToId Token id
   * Required Statements
   * - MaviaNFT:01 Only burner role can burn
   */
  function fBulkBurn(uint256 _pFromId, uint256 _pToId) external override onlyRole(BURNER_ROLE) {
    for (uint256 id_ = _pFromId; id_ <= _pToId; id_++) {
      _burn(id_);
    }
  }

  /**
   * @notice Set creator
   * @dev Whoever has creator role, can change creator
   * @param _pId Token ID
   * @param _pAccount Token creator
   */
  function fSetCreator(uint256 _pId, address _pAccount) external override onlyRole(CREATOR_ROLE) {
    _creators[_pId] = _pAccount;
  }

  /**
   * @dev Get creator
   * @param _pId token ID
   */
  function fGetCreator(uint256 _pId) external view override returns (address) {
    return _creators[_pId];
  }

  /**
   * @dev Get own Time
   * @param _pId token ID
   */
  function fGetOwnTime(uint256 _pId) external view returns (uint256) {
    return _ownTime[_pId];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   * @param _pAccount Address of Owner
   * @param _pOperator Address of operator
   */
  function isApprovedForAll(address _pAccount, address _pOperator) public view override returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (isOpenSeaProxyActive && address(proxyRegistry.proxies(_pAccount)) == _pOperator) {
      return true;
    }

    return hasRole(APPROVER_ROLE, _pOperator) || super.isApprovedForAll(_pAccount, _pOperator);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address _pFrom,
    address _pTo,
    uint256 _pTokenId
  ) internal override {
    _ownTime[_pTokenId] = block.timestamp;
    super._transfer(_pFrom, _pTo, _pTokenId);
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
  function _mint(address _pTo, uint256 _pTokenId) internal override {
    _creators[_pTokenId] = _pTo;
    _ownTime[_pTokenId] = block.timestamp;
    super._mint(_pTo, _pTokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 _pTokenId) internal override {
    _ownTime[_pTokenId] = block.timestamp;
    super._burn(_pTokenId);
  }
}
