// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract SnapshotNft is
  Initializable,
  ERC721URIStorageUpgradeable,
  UUPSUpgradeable,
  AccessControlUpgradeable,
  PausableUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  CountersUpgradeable.Counter private _tokenIds;
  EnumerableSetUpgradeable.UintSet private _frozenTokenIds;
  string private _baseUri;
  address payable private _owner;
  uint256 public mintCost;
  uint256 public maxMints;

  uint256 public whitelistMintCost;
  bytes32 private _whitelistMerkleRoot;
  mapping(address => uint256) private _whitelistBalances;

  bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

  event PermanentURI(string _value, uint256 indexed _id);
  event OwnershipTransferred(address previousOwner, address newOwner);

  function initialize(
    address owner,
    address[] calldata mods,
    string calldata baseUri,
    uint256 initMaxMints,
    uint256 initMintCost,
    uint256 initWhitelistMintCost,
    bytes32 whitelistMerkleRoot
  ) public initializer
  {
    __ERC721_init("Machinations", "MACH");
    __UUPSUpgradeable_init();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ERC721URIStorage_init_unchained();

    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    for (uint256 i = 0; i < mods.length; ++i) {
      _grantRole(MOD_ROLE, mods[i]);
    }

    _owner = payable(owner);
    _baseUri = baseUri;
    maxMints = initMaxMints;
    mintCost = initMintCost;
    whitelistMintCost = initWhitelistMintCost;
    _whitelistMerkleRoot = whitelistMerkleRoot;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {} // solhint-disable-line no-empty-blocks

  function setWhitelistMerkleRoot(bytes32 newWhitelistMerkleRoot) public
    onlyRole(MOD_ROLE)
  {
    _whitelistMerkleRoot = newWhitelistMerkleRoot;
  }

  function _whitelistLeaf(address address_, uint256 allowance) internal pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(allowance, address_));
  }

  function _verifyWhitelist(
    bytes32[] calldata proof,
    address address_,
    uint256 allowance
  ) internal view returns (bool) {
    return MerkleProofUpgradeable.verify(
      proof,
      _whitelistMerkleRoot,
      _whitelistLeaf(address_, allowance)
    );
  }

  function whitelistMint(bytes32[] calldata proof, uint256 allowance) public payable {
    require(_verifyWhitelist(proof, _msgSender(), allowance),
            "Whitelist Merkle proof invalid");
    require(_whitelistBalances[_msgSender()] < allowance,
            "Minted max number of whitelisted works");

    ++_whitelistBalances[_msgSender()];
    _mintWithCost(_msgSender(), whitelistMintCost);
  }

  function setWhitelistMintCost(uint256 newMintCost) public onlyRole(MOD_ROLE) {
    whitelistMintCost = newMintCost;
  }

  function mint(address toAddress) public payable {
    _mintWithCost(toAddress, mintCost);
  }

  function _mintWithCost(address toAddress, uint256 cost) internal {
    require(msg.value >= cost, "Mint payment too low");
    uint256 newItemId = _tokenIds.current();
    require(newItemId < maxMints, "Max number of mints reached");

    _safeMint(toAddress, newItemId);
    _setTokenURI(
      newItemId,
      string(abi.encodePacked(
        _baseUri,
        StringsUpgradeable.toString(newItemId),
        ".json"))
    );
    _tokenIds.increment();
  }

  function setMintCost(uint256 newMintCost) public onlyRole(MOD_ROLE) {
    mintCost = newMintCost;
  }

  function setBaseUri(string calldata baseUri) public onlyRole(MOD_ROLE) {
    _baseUri = baseUri;
  }

  function pause() public onlyRole(MOD_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(MOD_ROLE) {
    _unpause();
  }

  function freeze(uint256 tokenId, string calldata tokenUri) public
    onlyRole(MOD_ROLE)
  {
    require(!_frozenTokenIds.contains(tokenId), "Tokens can only be frozen once");

    _setTokenURI(tokenId, tokenUri);
    _frozenTokenIds.add(tokenId);

    emit PermanentURI(tokenUri, tokenId);
  }

  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner or approved");
    _burn(tokenId);
  }

  function batchSafeTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds
  ) public {
    batchSafeTransferFrom(from, to, tokenIds, "");
  }

  function batchSafeTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    bytes memory _data
  ) public {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      safeTransferFrom(from, to, tokenIds[i], _data);
    }
  }

  function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
    AddressUpgradeable.sendValue(_owner, address(this).balance);
  }

  function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
    address previousOwner = _owner;
    _owner = payable(newOwner);

    emit OwnershipTransferred(previousOwner, newOwner);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal virtual override
  {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(), "Token transfer while paused");
  }

  function _authorizeUpgrade(address) internal override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {} // solhint-disable-line no-empty-blocks
}
