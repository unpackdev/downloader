// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IRegistry.sol";
import "./IMapNFT.sol";

error NonExistentToken();
error NotAuthorizedToClaim();
error UnauthorizedOwnerOfOg();
error MismatchedSignature();
error TokenStaked();
error ClaimNotActive();

/**
 * @title The WYRD ERC-721 Smart Contract
 */
contract TheWYRD is
  ERC721Upgradeable,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using StringsUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  bool public claimIsActive;
  bool public mintIsActive;
  bool public canStake;

  uint256 public totalSupply;
  uint256 public maxSupply;
  uint256 public mintPrice;
  uint256 private devFee;
  
  uint256 private tokenIdCounter;

  string private baseURI;

  IRegistry public registry;
  IMapNFT public mapNFT;

  address private projectTreasury;
  address private devAddress;

  mapping(uint256 => uint256) public tokensLastStakedAt;

  event ClaimActivation(bool isActive);
  event MintActivation(bool isActive);
  event WyrdFromMapClaimed(address claimer, uint256 tokenId);
  event Stake(uint256 tokenId, address by, uint256 stakedAt);
  event Unstake(
    uint256 tokenId,
    address by,
    uint256 stakedAt,
    uint256 unstakedAt
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _registryContract,
    address _mapContract
  )
  external
  initializer
  {
    __ERC721_init("The WYRD", "WYRD");
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
    __AccessControlEnumerable_init();
    __Pausable_init();

    registry = IRegistry(_registryContract);
    mapNFT = IMapNFT(_mapContract);

    claimIsActive = false;
    mintIsActive = false;
    maxSupply = 10000;
    canStake = false;
    mintPrice = 0.05 ether;

    baseURI = "https://club101.s3.us-east-2.amazonaws.com/wyrd/metadata/metadata/";

    projectTreasury = 0x18D975911e9D6EFbafc4857dE1e8E84842218729;
    devAddress = 0x4464FC02d751938B987745B2ff34860Ea1De00a0;
    devFee = 20;
    tokenIdCounter = 2713;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);
  }

  function version()
  external
  pure
  virtual
  returns (string memory)
  {
    return "1.0.0";
  }

  function claimWyrdFromMaps(
    uint256[] calldata mapIds
  )
  external
  nonReentrant
  {
    if (!claimIsActive) {
      revert ClaimNotActive();
    }

    uint256 mapIdsLength = mapIds.length;

    for (uint256 i = 0; i < mapIdsLength; i++) {
      _claimWyrdFromMap(mapIds[i]);
    }

    unchecked {
      totalSupply += mapIdsLength;
    }
  }

  function _claimWyrdFromMap(
    uint256 mapId
  )
  internal
  {
    if (mapNFT.ownerOf(mapId) != msg.sender) {
      revert NotAuthorizedToClaim();
    }

    mapNFT.transferFrom(
      msg.sender,
      0x000000000000000000000000000000000000dEaD,
      mapId
    );
    _safeMint(msg.sender, mapId);
    emit WyrdFromMapClaimed(msg.sender, mapId);
  }

  function tokenURI(uint256 tokenId)
  public
  view
  virtual
  override
  returns (string memory)
  {
    if (!_exists(tokenId)) {
      revert NonExistentToken();
    }

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : "";
  }

  function _baseURI()
  internal
  view
  override
  returns (string memory)
  {
    return baseURI;
  }

  function setBaseURI(string memory uri)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseURI = uri;
  }

  function toggleClaimStatus() public onlyRole(DEFAULT_ADMIN_ROLE) {
    claimIsActive = !claimIsActive;
    emit ClaimActivation(claimIsActive);
  }

  function toggleMintStatus() public onlyRole(DEFAULT_ADMIN_ROLE) {
    mintIsActive = !mintIsActive;
    emit MintActivation(mintIsActive);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

function publicMint(uint256 _count) public payable {
    require(_count > 0, "Count must be a positive integer.");
    require(totalSupply + _count <= maxSupply, "Total supply exceeded.");
    require(tokenIdCounter + _count <= maxSupply, "Token ID limit exceeded.");
    require(mintPrice * _count == msg.value, "Incorrect ETH amount sent.");

    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        require(mintIsActive, "Minting is not active currently.");
    }

    for (uint256 i = 0; i < _count; i++) {
        uint256 newTokenId = tokenIdCounter + 1;
        _safeMint(msg.sender, newTokenId);
        tokenIdCounter = newTokenId;
    }

    payable(devAddress).transfer(msg.value * devFee / 100);
    unchecked {
      totalSupply += _count;
    }
}

  function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
    totalSupply += 1;
  }

  function _safeMint(address to, uint256 tokenId) internal virtual override {
    require(totalSupply + 1 <= maxSupply, "Maximum Supply reached");
    super._safeMint(to, tokenId, "");
  }

  function adminBurner(uint256[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i; i < tokenIds.length; i++) {
        _burn(tokenIds[i]);
    }
  }

  function changeMaxSupply(uint256 number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxSupply = number;
  }

  function setPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
    mintPrice = _price;
  }

  function getPrice() external view returns (uint256) {
    return mintPrice;
  }

  function setMarketplaceRegistry(address _registryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        registry = IRegistry(_registryAddress);
  }

  function setTreasuryAddress(address _projectTreasury) public onlyRole(DEFAULT_ADMIN_ROLE) {
    projectTreasury = _projectTreasury;
  }

  function setDevAddress(address _devAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    devAddress = _devAddress;
  }

  function setDevFee(uint256 _devFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
    devFee = _devFee;
  }

  // ---- STAKING ----
  function setCanStake(bool _canStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
    canStake = _canStake;
  }

  function stake(uint256 tokenId) public {
    require(canStake, "staking not open");
    require(
      msg.sender == ownerOf(tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "caller must be owner of token or contract owner"
    );
    require(tokensLastStakedAt[tokenId] == 0, "already staking");
    tokensLastStakedAt[tokenId] = block.timestamp;
    emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
  }

  function unstake(uint256 tokenId) public {
    require(
      msg.sender == ownerOf(tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "caller must be owner of token or contract owner"
    );
    require(tokensLastStakedAt[tokenId] > 0, "not staking");
    uint256 lsa = tokensLastStakedAt[tokenId];
    tokensLastStakedAt[tokenId] = 0;
    emit Unstake(tokenId, msg.sender, block.timestamp, lsa);
  }

  function setTokensStakeStatus(uint256[] memory tokenIds, bool setStake) external {
    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (setStake) {
        stake(tokenId);
      } else {
        unstake(tokenId);
      }
    }
  }

  /**
    * @notice Checks whether operator is valid on the registry. Will return true if registry isn't active.
    * @param operator - Operator address
    */
  function _isValidAgainstRegistry(address operator)
  internal
  view
  returns (bool)
  {
    return registry.isAllowedOperator(operator);
  }

  /**
    * @notice Checks whether msg.sender is valid on the registry. If not, it will
    * block the transfer of the token.
    * @param from - Address token is transferring from
    * @param to - Address token is transferring to
    * @param tokenId - Token ID being transfered
    * @param batchSize - Batch size
    */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  )
  internal
  whenNotPaused
  override
  {
    if (tokensLastStakedAt[tokenId] != 0){
      revert TokenStaked();
    }
    if (_isValidAgainstRegistry(msg.sender)) {
      super._beforeTokenTransfer(
        from,
        to,
        tokenId,
        batchSize
      );
    } else {
      revert IRegistry.NotAllowed();
    }
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC721Upgradeable, AccessControlEnumerableUpgradeable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(UPGRADER_ROLE)
  {}
    
  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint balance = address(this).balance;
    payable(projectTreasury).transfer(balance);
  }
}