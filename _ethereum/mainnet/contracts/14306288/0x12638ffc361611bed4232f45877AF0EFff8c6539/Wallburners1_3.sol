// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./WBLibrary2.sol";

contract Wallburners1_3 is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC721PausableUpgradeable,
    EIP712Upgradeable
{
  // For Opensea 2ndary sales, waiting for EIP2981. See
  // https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public pure returns (string memory) {
    return "https://wallburners.art/metacontract";
  }

  event Mint(uint256 indexed tokenId, uint64 indexed editionId, uint32 rank);

  bytes32 public constant BURN_OPERATOR_ROLE = keccak256("BURN_OPERATOR_ROLE");

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __ERC721_init_unchained("Wallburners", "WBR");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();
    __AccessControl_init();
    __EIP712_init("Wallburners", "1");
    __UUPSUpgradeable_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(BURN_OPERATOR_ROLE, _msgSender());
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override {
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: tokenURI token !exists");
    return WBLibrary2.uri(tokenId);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(
      ERC721PausableUpgradeable
  ) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function mint(uint64 editionId, uint32 rank)
    public onlyRole(BURN_OPERATOR_ROLE) returns (uint256) {
    return _mintBurn(editionId, rank);
  }

  function _mintBurn(uint64 editionId, uint32 rank) private returns (uint256) {
    uint256 tokenId = 2 ** 32 * editionId + rank;
    emit Mint(tokenId, editionId, rank);
    _mint(_msgSender(), tokenId);
    return tokenId;
  }

  function buyAtPrice(
    uint256 tokenId,
    uint256 price,
    address owner,
    uint256 deadline,
    uint256 cutAmount,
    address cutAccount,
    bytes memory signature
  ) public payable {
    bool tokenExists = _exists(tokenId);
    address currentOwner;
    if (tokenExists) {
      currentOwner = ownerOf(tokenId);
    }
    address signer = WBLibrary2.checkTokenAndGetSigner(
      tokenId, price, owner, _msgSender(), deadline, cutAmount,
      cutAccount, signature,
      _domainSeparatorV4(), tokenExists, currentOwner
    );
    require(
      hasRole(BURN_OPERATOR_ROLE, signer),
      "WBR: price signer must be burn operator"
    );
    address payable seller;
    if (tokenExists) {
      seller = payable(currentOwner);
      _safeTransfer(seller, _msgSender(), tokenId, "");
    } else {
      //  Directly mints to the _msgSender()
      _mintBurn(uint64(tokenId >> 32), uint32(tokenId));
      seller = payable(signer);
    }
    if (price > 0) {
      require(price - cutAmount > cutAmount, 'WBR: cut percent must <50%');
      if (cutAmount > 0) {
        require(cutAccount != address(0), 'WBR: cut but no account');
        payable(cutAccount).transfer(cutAmount);
      }
      seller.transfer(price - cutAmount);
    }
  }

  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function supportsInterface(bytes4 interfaceId) public view override(
      AccessControlUpgradeable,
      ERC721Upgradeable
  ) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

}
