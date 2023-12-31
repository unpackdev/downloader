// SPDX-License-Identifier: MIT
// Archetype v0.6.0 - ERC1155-Random
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.4;

import "./ArchetypeLogic.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC2981Upgradeable.sol";
import "./LibString.sol";
import "./OperatorFilterer.sol";

contract Archetype is
  Initializable,
  ERC1155Upgradeable,
  OperatorFilterer,
  OwnableUpgradeable,
  ERC2981Upgradeable
{
  //
  // EVENTS
  //
  event Invited(bytes32 indexed key, bytes32 indexed cid);
  event Referral(address indexed affiliate, address token, uint128 wad, uint256 numMints);
  event Withdrawal(address indexed src, address token, uint128 wad);

  //
  // VARIABLES
  //
  mapping(bytes32 => DutchInvite) public invites;
  mapping(address => mapping(bytes32 => uint256)) private _minted;
  mapping(bytes32 => uint256) private _listSupply;
  mapping(address => OwnerBalance) private _ownerBalance;
  mapping(address => mapping(address => uint128)) private _affiliateBalance;

  uint256 public totalSupply;

  Config public config;
  BurnConfig public burnConfig;
  Options public options;

  string public name;
  string public symbol;

  // chainlink
  VrfConfig public vrfConfig;
  mapping(uint256 => VrfMintInfo) public requestIdMintInfo;
  VRFCoordinatorV2Interface internal vrfCoordinator;

  //
  // METHODS
  //
  function initialize(
    string memory _name,
    string memory _symbol,
    Config calldata config_,
    address _receiver
  ) external initializer {
    name = _name;
    symbol = _symbol;
    __ERC1155_init("");

    vrfCoordinator = VRFCoordinatorV2Interface(VRF_CORDINATOR);

    // check max bps not reached and min platform fee.
    if (
      config_.affiliateFee > MAXBPS ||
      config_.platformFee > MAXBPS ||
      config_.platformFee < 500 ||
      config_.discounts.affiliateDiscount > MAXBPS ||
      config_.affiliateSigner == address(0) ||
      config_.maxBatchSize == 0
    ) {
      revert InvalidConfig();
    }
    // ensure mint tiers are correctly ordered from highest to lowest.
    for (uint256 i = 1; i < config_.discounts.mintTiers.length; i++) {
      if (
        config_.discounts.mintTiers[i].mintDiscount > MAXBPS ||
        config_.discounts.mintTiers[i].numMints > config_.discounts.mintTiers[i - 1].numMints
      ) {
        revert InvalidConfig();
      }
    }
    config = config_;
    __Ownable_init();

    if (config.ownerAltPayout != address(0)) {
      setDefaultRoyalty(config.ownerAltPayout, config.defaultRoyalty);
    } else {
      setDefaultRoyalty(_receiver, config.defaultRoyalty);
    }
  }

  //
  // PUBLIC
  //

  function mint(
    Auth calldata auth,
    uint256 quantity,
    address affiliate,
    bytes calldata signature
  ) external payable {
    mintTo(auth, quantity, _msgSender(), affiliate, signature);
  }

  function mintTo(
    Auth calldata auth,
    uint256 quantity,
    address to,
    address affiliate,
    bytes calldata signature
  ) public payable {
    DutchInvite storage i = invites[auth.key];

    if (i.unitSize > 1) {
      quantity = quantity * i.unitSize;
    }

    ValidationArgs memory args = ValidationArgs({
        owner: owner(),
        affiliate: affiliate,
        quantity: quantity,
        curSupply: totalSupply
    });

    ArchetypeLogic.validateMint(
      i,
      config,
      auth,
      _minted,
      _listSupply,
      signature,
      args
    );

    if(vrfConfig.enabled) {
        uint256 requestId = requestRandomness(); // request randomness from Chainlink VRF
        requestIdMintInfo[requestId] = VrfMintInfo({
          key: auth.key,
          to: to,
          quantity: quantity
        });
    } else {
      uint16[] memory tokenIds;
      uint256 seed = ArchetypeLogic.random();
      tokenIds = ArchetypeLogic.getRandomTokenIds(
        config.tokenPool,
        i.tokenIdsExcluded,
        quantity,
        seed
      );

      for (uint256 j = 0; j < tokenIds.length; j++) {
        bytes memory _data;
        _mint(to, tokenIds[j], 1, _data);
      }
    }

    totalSupply += quantity;
    if (i.limit < i.maxSupply) {
      _minted[_msgSender()][auth.key] += quantity;
    }
    if (i.maxSupply < 2**32 - 1) {
      _listSupply[auth.key] += quantity;
    }

    ArchetypeLogic.updateBalances(i, config, _ownerBalance, _affiliateBalance, affiliate, quantity);
  }

  // simple 1 to 1 burn to mint.
  function burnToMint(uint256[] calldata tokenIdList, uint256[] calldata quantityList) external {

    if(burnConfig.tokenAddress == address(0)) {
      revert BurnToMintDisabled();
    }

    if (quantityList.length != tokenIdList.length) {
      revert InvalidConfig();
    }

    address msgSender = _msgSender();
    uint256 quantity = 0;
    for (uint256 i; i < tokenIdList.length; i++) {
      address burnAddress = burnConfig.burnAddress != address(0)
        ? burnConfig.burnAddress
        : address(0x000000000000000000000000000000000000dEaD);

      bytes memory _data;
      IERC1155Upgradeable(burnConfig.tokenAddress).safeTransferFrom(msgSender, burnAddress, tokenIdList[i], quantityList[i], _data);
      _mint(msgSender, tokenIdList[i], quantityList[i], _data);
      quantity += quantityList[i];
    }

    if ((totalSupply + quantity) > config.maxSupply) {
      revert MaxSupplyExceeded();
    }
    totalSupply += quantity;
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    return
      bytes(config.baseUri).length != 0
        ? string(abi.encodePacked(config.baseUri, LibString.toString(tokenId)))
        : "";
  }

  function withdraw() external {
    address[] memory tokens = new address[](1);
    tokens[0] = address(0);
    withdrawTokens(tokens);
  }

  function withdrawTokens(address[] memory tokens) public {
    ArchetypeLogic.withdrawTokens(config, _ownerBalance, _affiliateBalance, owner(), tokens);
  }

  function ownerBalance() external view returns (OwnerBalance memory) {
    return _ownerBalance[address(0)];
  }

  function ownerBalanceToken(address token) external view returns (OwnerBalance memory) {
    return _ownerBalance[token];
  }

  function affiliateBalance(address affiliate) external view returns (uint128) {
    return _affiliateBalance[affiliate][address(0)];
  }

  function affiliateBalanceToken(address affiliate, address token) external view returns (uint128) {
    return _affiliateBalance[affiliate][token];
  }

  function minted(address minter, bytes32 key) external view returns (uint256) {
    return _minted[minter][key];
  }

  function listSupply(bytes32 key) external view returns (uint256) {
    return _listSupply[key];
  }

  function platform() external pure returns (address) {
    return PLATFORM;
  }

  function tokenPool() external view returns (uint16[] memory) {
    return config.tokenPool;
  }

  function computePrice(
    bytes32 key,
    uint256 quantity,
    bool affiliateUsed
  ) external view returns (uint256) {
    DutchInvite storage i = invites[key];
    return ArchetypeLogic.computePrice(i, config.discounts, quantity, affiliateUsed);
  }

  //
  // OWNER ONLY
  //

  function airdropTo(
    address[] calldata toList,
    uint256[] calldata quantityList,
    uint256[] calldata tokenIdList
  ) external _onlyOwner {

    if (options.airdropLocked) {
      revert LockedForever();
    }

    if (quantityList.length != toList.length || quantityList.length != tokenIdList.length) {
      revert InvalidConfig();
    }

    uint256 quantity = 0;
    for (uint256 i = 0; i < toList.length; i++) {
      bytes memory _data;
      _mint(toList[i], tokenIdList[i], quantityList[i], _data);
      quantity += quantityList[i];
    }

    if ((totalSupply + quantity) > config.maxSupply) {
      revert MaxSupplyExceeded();
    }
    totalSupply += quantity;
  }

  /// @notice the password is "forever"
  function lockAirdrop(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.airdropLocked = true;
  }

  function setBaseURI(string memory baseUri) external _onlyOwner {
    if (options.uriLocked) {
      revert LockedForever();
    }

    config.baseUri = baseUri;
  }

  /// @notice the password is "forever"
  function lockURI(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.uriLocked = true;
  }

  /// @notice the password is "forever"
  // token pool will be appended. Be careful changing.
  function appendTokenPool(uint16[] memory newTokens, string memory password) public _onlyOwner {
    _checkPassword(password);
    if (options.tokenPoolLocked) {
      revert LockedForever();
    }

    for (uint256 i = 0; i < newTokens.length; i++) {
      config.tokenPool.push(newTokens[i]);
    }
  }

  /// @notice the password is "forever"
  // token pool will be completely replaced. Be careful changing.
  function replaceTokenPool(uint16[] memory newTokens, string memory password) external _onlyOwner {
    _checkPassword(password);
    if (options.tokenPoolLocked) {
      revert LockedForever();
    }

    config.tokenPool = newTokens;
  }

  /// @notice the password is "forever"
  function lockTokenPool(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.tokenPoolLocked = true;
  }

  /// @notice the password is "forever"
  // max supply cannot subceed total supply. Be careful changing.
  function setMaxSupply(uint32 maxSupply, string memory password) external _onlyOwner {
    _checkPassword(password);
    if (options.maxSupplyLocked) {
      revert LockedForever();
    }

    if (maxSupply < totalSupply) {
      revert MaxSupplyExceeded();
    }

    config.maxSupply = maxSupply;
  }

  /// @notice the password is "forever"
  function lockMaxSupply(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.maxSupplyLocked = true;
  }


  function setAffiliateFee(uint16 affiliateFee) external _onlyOwner {
    if (options.affiliateFeeLocked) {
      revert LockedForever();
    }
    if (affiliateFee > MAXBPS) {
      revert InvalidConfig();
    }

    config.affiliateFee = affiliateFee;
  }

  /// @notice the password is "forever"
  function lockAffiliateFee(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.affiliateFeeLocked = true;
  }

  function setDiscounts(Discount calldata discounts) external _onlyOwner {
    if (options.discountsLocked) {
      revert LockedForever();
    }

    if (discounts.affiliateDiscount > MAXBPS) {
      revert InvalidConfig();
    }

    // ensure mint tiers are correctly ordered from highest to lowest.
    for (uint256 i = 1; i < discounts.mintTiers.length; i++) {
      if (
        discounts.mintTiers[i].mintDiscount > MAXBPS ||
        discounts.mintTiers[i].numMints > discounts.mintTiers[i - 1].numMints
      ) {
        revert InvalidConfig();
      }
    }

    config.discounts = discounts;
  }

  /// @notice the password is "forever"
  function lockDiscounts(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.discountsLocked = true;
  }

  function setOwnerAltPayout(address ownerAltPayout) external _onlyOwner {
    if (options.ownerAltPayoutLocked) {
      revert LockedForever();
    }

    config.ownerAltPayout = ownerAltPayout;
  }

  /// @notice the password is "forever"
  function lockOwnerAltPayout(string memory password) external _onlyOwner {
    _checkPassword(password);
    options.ownerAltPayoutLocked = true;
  }

  function setMaxBatchSize(uint16 maxBatchSize) external _onlyOwner {
    config.maxBatchSize = maxBatchSize;
  }

  function enableChainlinkVRF(uint64 subId) external _onlyOwner {
    vrfConfig = VrfConfig({
      enabled: true,
      subId: subId
    });
  }

  function disableChainlinkVRF() external _onlyOwner {
    vrfConfig = VrfConfig({
      enabled: false,
      subId: 0
    });
  }

  function setInvite(
    bytes32 _key,
    bytes32 _cid,
    Invite calldata _invite
  ) external _onlyOwner {
    invites[_key] = DutchInvite({
      price: _invite.price,
      reservePrice: _invite.price,
      delta: 0,
      start: _invite.start,
      end: _invite.end,
      limit: _invite.limit,
      maxSupply: _invite.maxSupply,
      interval: 0,
      unitSize: _invite.unitSize,
      tokenAddress: _invite.tokenAddress,
      tokenIdsExcluded: _invite.tokenIdsExcluded
    });
    emit Invited(_key, _cid);
  }

  function setDutchInvite(
    bytes32 _key,
    bytes32 _cid,
    DutchInvite memory _dutchInvite
  ) external _onlyOwner {
    if (_dutchInvite.start < block.timestamp) {
      _dutchInvite.start = uint32(block.timestamp);
    }
    invites[_key] = _dutchInvite;
    emit Invited(_key, _cid);
  }

  function enableBurnToMint(
    address tokenAddress,
    address burnAddress
  ) external _onlyOwner {
    burnConfig = BurnConfig({
      tokenAddress: tokenAddress,
      burnAddress: burnAddress
    });
  }

  function disableBurnToMint() external _onlyOwner {
    burnConfig = BurnConfig({
      tokenAddress: address(0),
      burnAddress: address(0)
    });
  }

  //
  // PLATFORM ONLY
  //
  function setSuperAffiliatePayout(address superAffiliatePayout) external _onlyPlatform {
    config.superAffiliatePayout = superAffiliatePayout;
  }

  //
  // VRF
  //

  // Request randomness
  function requestRandomness() internal returns (uint256 requestId) {
      // The gas lane to use, which specifies the maximum gas price to bump to.
      // For a list of available gas lanes on each network,
      // see https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations
      bytes32 keyHash = VRF_KEYHASH;

      uint16 minimumRequestConfirmations = 5;
      uint32 callbackGasLimit = 2500000; // max limit

      // Requesting random numbers
      requestId = vrfCoordinator.requestRandomWords(
          keyHash,
          vrfConfig.subId,
          minimumRequestConfirmations,
          callbackGasLimit,
          1
      );
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  function rawFulfillRandomWords(
      uint256 requestId,
      uint256[] memory randomWords
  ) external {
      // Allow owner and platform to fulfill as backup
      address msgSender = _msgSender();
      if(msgSender == VRF_CORDINATOR || msgSender == PLATFORM || msgSender == owner()) {
        fulfillRandomWords(requestId, randomWords);
      } else {
        revert NotVRF();
      }
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal {
    VrfMintInfo memory mintInfo = requestIdMintInfo[requestId];
    if(mintInfo.quantity == 0) {
      revert InvalidRequestId();
    }

    uint16[] memory tokenIds;
    tokenIds = ArchetypeLogic.getRandomTokenIds(
      config.tokenPool,
      invites[mintInfo.key].tokenIdsExcluded,
      mintInfo.quantity,
      randomness[0]
    );

    for (uint256 j = 0; j < tokenIds.length; j++) {
      bytes memory _data;
      _mint(mintInfo.to, tokenIds[j], 1, _data);
    }

    delete requestIdMintInfo[requestId];
  }

  //
  // INTERNAL
  //
  function _startTokenId() internal view virtual returns (uint256) {
    return 1;
  }

  function _msgSender() internal view override returns (address) {
    return msg.sender == BATCH? tx.origin: msg.sender;
  }

  function _checkPassword(string memory password) internal pure {
    if (keccak256(abi.encodePacked(password)) != keccak256(abi.encodePacked("forever"))) {
      revert WrongPassword();
    }
  }

  function _isOwner() internal view {
    if (_msgSender() != owner()) {
      revert NotOwner();
    }  
  }


  modifier _onlyPlatform() {
    if (_msgSender() != PLATFORM) {
      revert NotPlatform();
    }
    _;
  }

  modifier _onlyOwner() {
    _isOwner();
    _;
  }

  //ERC2981 ROYALTY
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC1155Upgradeable.supportsInterface(interfaceId) ||
      ERC2981Upgradeable.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint16 feeNumerator) public _onlyOwner {
    config.defaultRoyalty = feeNumerator;
    _setDefaultRoyalty(receiver, feeNumerator);
  }
}
