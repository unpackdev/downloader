// SPDX-License-Identifier: MIT
/**
╔╗ ╔╗╔═╗ ╔╗╔═══╗╔═══╗╔═══╗╔═══╗
║║ ║║║║╚╗║║║╔═╗║║╔═╗║╚╗╔╗║║╔══╝
║║ ║║║╔╗╚╝║║║ ╚╝║║ ║║ ║║║║║╚══╗
║║ ║║║║╚╗║║║║ ╔╗║║ ║║ ║║║║║╔══╝
║╚═╝║║║ ║║║║╚═╝║║╚═╝║╔╝╚╝║║╚══╗
╚═══╝╚╝ ╚═╝╚═══╝╚═══╝╚═══╝╚═══╝
 */
pragma solidity ^0.8.4;

import "./ERC721Psi.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./FixedPriceSeller.sol";
import "./SignerManager.sol";
import "./SignatureChecker.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./FPEMap.sol";
import "./Strings.sol";

/**
 @title Uncode Avatars
 @author Uncode GmbH
 @dev Inherits from ERC721Psi and uses FPE-Map and VRF randomized tokenId/metadataId mapping using.
 */
contract UncodeAvatars is
  ERC721Psi,
  ERC2981,
  FixedPriceSeller,
  SignerManager,
  VRFConsumerBaseV2
{
  using SignatureChecker for EnumerableSet.AddressSet;
  using Strings for uint256;

  uint32 public mintAllowlistStartTime;
  uint32 public mintPublicStartTime;

  /// @dev The final inventory (total supply) can only be set once, at the reveal.
  /// @dev It is used to calculate the randomized metadata mapping,
  uint256 private finalInventory = 0;

  string private _baseTokenURI;
  string private _baseTokenURIStaticMetadata;

  mapping(bytes32 => bool) private usedMessages;

  /// @dev Emitted when a Uncode Avatar begins staking.
  event Staked(uint256 indexed tokenId);

  /// @dev Emitted when a Uncode Avatar stops staking; either through standard means or by expulsion.
  event Unstaked(uint256 indexed tokenId);

  /// @dev Emitted when a Uncode Avatar is expelled from the staking.
  event Expelled(uint256 indexed tokenId);

  /// @notice Whether staking is currently allowed.
  /// @dev If false then staking is blocked, but unstaking is always allowed.
  bool public stakingIsOpen = false;

  /// @dev Per-token start time, 0 means not staked at all yet.
  mapping(uint256 => uint256) private stakingStarted;

  /// @dev Cumulative per-token staking time, excluding the current period.
  mapping(uint256 => uint256) private stakingTotal;

  VRFCoordinatorV2Interface private COORDINATOR;

  /// @dev The gas lane to use, which specifies the maximum gas price to bump to.
  bytes32 private immutable vrfKeyHash;
  
  /// @dev The chainlink VRF subscriptionId to use.
  uint64 private immutable vrfSubscriptionId;

  /// @dev Depends on the number of requested values. Storing each word costs about 20,000 gas.
  uint32 private vrfCallbackGasLimit;

  /// @dev Number of confirmations before callback request.
  uint16 private immutable vrfRequestConfirmations;

  /// @dev Prevents requesting a new random seed, can not be unlocked again.
  bool private metadataMapIsLocked = false;

  uint256 public randomSeed = 0;
  uint256 public randomRequestId;

  constructor(
    address payable _beneficiary,
    address payable _royaltyReceiver,
    uint256 _initialInventory,
    address _vrfCoordinator, // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 _vrfKeyHash, // see https://docs.chain.link/docs/vrf-contracts/#configurations
    uint64 _vrfSubscriptionId,
    uint32 _vrfCallbackGasLimit,
    uint16 _vrfRequestConfirmations
  )
    ERC721Psi(unicode"UNCODE Avatars Male", unicode"UNCODE▽")
    VRFConsumerBaseV2(_vrfCoordinator)
    FixedPriceSeller(
      0.3 ether,
      Seller.SellerConfig({
        totalInventory: _initialInventory,
        //we need to increase the total inventory once, to give an additional avatar for all holders who locked their avatar 14 days
        lockTotalInventory: false,
        maxPerAddress: 1,
        maxPerTx: 1,
        freeQuota: 300,
        lockFreeQuota: false,
        reserveFreeQuota: true
      }),
      _beneficiary
    )
  {
    _setDefaultRoyalty(_royaltyReceiver, 500);
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    vrfKeyHash = _vrfKeyHash;
    vrfSubscriptionId = _vrfSubscriptionId;
    vrfCallbackGasLimit = _vrfCallbackGasLimit;
    vrfRequestConfirmations = _vrfRequestConfirmations;
  }

  /// @notice Requires that msg.sender owns or is approved for the token.
  modifier onlyApprovedOrOwner(uint256 tokenId) {
    require(
      ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender(),
      "not approved nor owner"
    );
    _;
  }

  /// @notice Requires that a token with this id exists.
  modifier tokenIdExists(uint256 tokenId) {
    require(_exists(tokenId), "id does not exist");
    _;
  }

  /// @notice Requires that the mint is already open.
  modifier mintIsOpen(uint32 startTime) {
    uint256 _startTime = uint256(startTime);
    require(
      _startTime != 0 && block.timestamp >= _startTime,
      "mint has not started yet"
    );
    _;
  }

  /// @dev Request the random seed for a randomized tokenId/metadataId mapping.
  /// @dev Can only be called once.
  /// @dev Assumes the subscription is funded sufficiently.
  function requestRandomSeed() external onlyOwner {
    require(!metadataMapIsLocked, "already requested");
    // Will revert if subscription is not set and funded.
    randomRequestId = COORDINATOR.requestRandomWords(
      vrfKeyHash,
      vrfSubscriptionId,
      vrfRequestConfirmations,
      vrfCallbackGasLimit,
      1
    );
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords)
    internal
    override
  {
    randomSeed = randomWords[0];
  }

  function lockMetadataMap() external onlyOwner {
    metadataMapIsLocked = true;
  }

  function setVrfCallbackGasLimit(uint32 _vrfCallbackGasLimit)
    external 
    onlyOwner
  {
    vrfCallbackGasLimit = _vrfCallbackGasLimit;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Psi, ERC2981)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721Psi.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  /// @notice Entry point for minting on the public mint.
  function mintPublic(uint16 requested)
    external
    payable
    mintIsOpen(mintPublicStartTime)
  {
    Seller._purchase(msg.sender, requested);
  }

  /// @notice Allowlist Mint.
  function mintAllowlist(
    address to,
    uint16 requested,
    uint32 nonce,
    bytes calldata sig
  ) 
    external
    payable
    mintIsOpen(mintAllowlistStartTime)
  {
    signers.requireValidSignature(
      _signaturePayload(to, nonce),
      sig,
      usedMessages
    );
    Seller._purchase(to, requested);
  }

  function setMintConfig(uint32 allowlistStartTime, uint32 publicStartTime)
    external
    onlyOwner
  {
    mintAllowlistStartTime = allowlistStartTime;
    mintPublicStartTime = publicStartTime;
  }

  function setFinalInventory(uint256 _finalInventory) external onlyOwner {
    require(finalInventory == 0, "already set");
    finalInventory = _finalInventory;
  }

  function allTokensOwnedBy(address ownerAdr)
    external
    view
    returns (uint256[] memory)
  {
    uint256 balance = balanceOf(ownerAdr);
    uint256[] memory tokenIds = new uint256[](balance);

    uint256 idx;
    for (uint256 i = 0; i < ERC721Psi.totalSupply(); i++) {
      if (ownerOf(i) != ownerAdr) {
        continue;
      }
      tokenIds[idx] = i;
      idx++;
    }
    return tokenIds;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setBaseURIStaticMetadata(string calldata baseURIStaticMetadata)
    external
    onlyOwner
  {
    _baseTokenURIStaticMetadata = baseURIStaticMetadata;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function _baseURIStaticMetadata() internal view returns (string memory) {
    return _baseTokenURIStaticMetadata;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    tokenIdExists(tokenId)
    returns (string memory)
  {
    return _tokenURI(tokenId, _baseURI());
  }

  function tokenURIStaticMetadata(uint256 tokenId)
    public
    view
    virtual
    tokenIdExists(tokenId)
    returns (string memory)
  {
    return _tokenURI(tokenId, _baseURIStaticMetadata());
  }

  function _tokenURI(uint256 tokenId, string memory baseURI)
    internal
    view
    returns (string memory)
  {
    require(bytes(baseURI).length > 0, "baseURI not set");
    if (randomSeed == 0 || finalInventory == 0) {
      // collection is still unrevealed, return a special tokenURI
      return string(abi.encodePacked(baseURI, "unrevealed/", tokenId.toString()));
    } else {
      // calculate randomized mapping of tokenId -> metadataId
      uint256 metadataId = FPEMap.fpeMappingFeistelAuto(
        tokenId,
        randomSeed,
        finalInventory
      );
      return string(abi.encodePacked(baseURI, metadataId.toString()));
    }
  }

  /// @notice Internal override of Seller function for handling purchase (i.e. minting).
  function _handlePurchase(
    address to,
    uint256 n,
    bool
  ) internal override {
    _safeMint(to, n);
  }

  /// @dev Prevent transfers while Avatar is staked.
  function _beforeTokenTransfers(
    address,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal view override {
    uint256 tokenId = startTokenId;
    for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
      require(stakingStarted[tokenId] == 0, "is staked");
    }
  }

  /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
  function _signaturePayload(address to, uint32 nonce)
    internal
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(to, nonce);
  }

  /**
    @notice Returns the length of time, in seconds, that the Uncode Avatar has
    been staked.
    @dev Staking is tied to a specific Uncode Avatar, not to the owner, so it doesn't
    reset upon sale.
    @return staking Whether the Uncode Avatar is currently staking. MAY be true with
    zero current staking if in the same block as staking began.
    @return current Zero if not currently staking, otherwise the length of time
    since the most recent staking began.
    @return total Total period of time for which the Uncode Avatar has been staked across
    its life, including the current period.
     */
  function stakingPeriod(uint256 tokenId)
    external
    view
    returns (
      bool staking,
      uint256 current,
      uint256 total
    )
  {
    uint256 start = stakingStarted[tokenId];
    if (start != 0) {
      staking = true;
      current = block.timestamp - start;
    }
    total = current + stakingTotal[tokenId];
  }

  /**
    @notice Enable or disable the staking functionality.
    */
  function setStakingOpen(bool open) external onlyOwner {
    stakingIsOpen = open;
  }

  /**
    @notice Changes a single Avatar's staking status
    */
  function toggleStaking(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
    uint256 start = stakingStarted[tokenId];
    if (start == 0) {
      require(stakingIsOpen, "staking closed");
      stakingStarted[tokenId] = block.timestamp;
      emit Staked(tokenId);
    } else {
      stakingTotal[tokenId] += block.timestamp - start;
      stakingStarted[tokenId] = 0;
      emit Unstaked(tokenId);
    }
  }

  /**
    @notice Changes multiple Avatars' staking status at once
    */
  function toggleStaking(uint256[] calldata tokenIds) external {
    uint256 n = tokenIds.length;
    for (uint256 i = 0; i < n; ++i) {
      toggleStaking(tokenIds[i]);
    }
  }

  /**
    @notice Admin-only ability to unstake an Uncode Avatar.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has staked and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting Avatar to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because staking would then be all-or-nothing for all of a particular owner's
    Uncode Avatars.
    */
  function unstake(uint256 tokenId) external onlyOwner {
    require(stakingStarted[tokenId] != 0, "is not staked");
    stakingTotal[tokenId] += block.timestamp - stakingStarted[tokenId];
    stakingStarted[tokenId] = 0;
    emit Unstaked(tokenId);
    emit Expelled(tokenId);
  }
}
