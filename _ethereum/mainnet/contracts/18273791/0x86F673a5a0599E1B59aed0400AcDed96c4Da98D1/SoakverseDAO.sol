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
import "./ISoakverseOG.sol";

error NonExistentToken();
error NotAuthorizedToClaim();
error UnauthorizedOwnerOfOg();
error MismatchedSignature();
error TokenStaked();
error ClaimNotActive();

/**
 * @title Soakverse DAO ERC-721 Smart Contract
 */
contract SoakverseDAO is
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
  bool public canStake;

  uint256 public totalSupply;
  uint256 public maxSupply;

  string private baseURI;

  IRegistry public registry;
  ISoakverseOG public soakverseOg;

  mapping(uint256 => uint256) public tokensLastStakedAt;

  address private signer;

  event ClaimActivation(bool isActive);
  event DaoPassClaimed(address claimer, uint256 tokenId);
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
    address _soakverseOgContract
  )
  external
  initializer
  {
    __ERC721_init("Soakverse DAO", "SOAKDAO");
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
    __AccessControlEnumerable_init();
    __Pausable_init();

    registry = IRegistry(_registryContract);
    soakverseOg = ISoakverseOG(_soakverseOgContract);

    claimIsActive = false;
    maxSupply = 365;
    canStake = false;

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

  function claimSoakverseDAOPasses(
    uint256[] calldata ogIds,
    bytes memory signature
  )
  external
  nonReentrant
  {
    if (!claimIsActive) {
      revert ClaimNotActive();
    }
    if (!_verify(msg.sender, ogIds, signature)) {
      revert MismatchedSignature();
    }

    uint256 ogIdsLength = ogIds.length;

    for (uint256 i; i < ogIdsLength;) {
      _claimSoakverseDAOPass(ogIds[i]);

      unchecked {
        ++i;
      }
    }

    unchecked {
      totalSupply += ogIdsLength;
    }
  }

  function _claimSoakverseDAOPass(
    uint256 ogId
  )
  internal
  {
    if (soakverseOg.ownerOf(ogId) != msg.sender) {
      revert NotAuthorizedToClaim();
    }

    soakverseOg.transferFrom(
      msg.sender,
      address(0),
      ogId
    );
    _mint(msg.sender, ogId);
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

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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

  function setSigner(address _signer)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    signer = _signer;
  }

  function _verify(
    address wallet,
    uint256[] calldata ogIds,
    bytes memory signature
  )
  internal
  view
  returns (bool)
  {
    return signer == keccak256(abi.encodePacked(
      wallet,
      ogIds
    )).toEthSignedMessageHash().recover(signature);
  }

  function toggleClaimStatus() public onlyRole(DEFAULT_ADMIN_ROLE) {
    claimIsActive = !claimIsActive;
    emit ClaimActivation(claimIsActive);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(to, tokenId);
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
}