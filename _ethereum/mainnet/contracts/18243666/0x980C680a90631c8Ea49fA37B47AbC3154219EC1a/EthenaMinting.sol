// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./EnumerableSetUpgradeable.sol";

import "./IUSDe.sol";
import "./IEthenaMinting.sol";

/**
 * @title Ethena Minting
 * @notice This contract mints and redeems USDe in a single, atomic, trustless transaction
 */
contract EthenaMinting is IEthenaMinting, Ownable, AccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  /* --------------- CONSTANTS --------------- */

  /// @notice EIP712 domain
  bytes32 public constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  /// @notice route type
  bytes32 public constant ROUTE_TYPE = keccak256('Route(address[] addresses,uint256[] ratios)');

  /// @notice order type
  bytes32 public constant ORDER_TYPE =
    keccak256(
      'Order(uint8 order_type,uint256 expiry,uint256 nonce,address benefactor,address beneficiary,address collateral_asset,uint256 collateral_amount,uint256 usde_amount)'
    );

  // keccak256('MINTER_ROLE');
  bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;

  // keccak256('REDEEMER_ROLE');
  bytes32 public constant REDEEMER_ROLE = 0x44ac9762eec3a11893fefb11d028bb3102560094137c3ed4518712475b2577cc;

  // keccak256('GATEKEEPER_ROLE');
  bytes32 public constant GATEKEEPER_ROLE = 0x3c63e605be3290ab6b04cfc46c6e1516e626d43236b034f09d7ede1d017beb0c;

  /// @notice EIP712 domain hash
  bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));

  /// @notice address denoting native ether
  address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice holds EIP712 revision
  bytes32 private constant _EIP712_REVISION = keccak256('1');

  /* --------------- STATE VARIABLES --------------- */

  /// @notice usde stablecoin
  IUSDe public usde;

  /// @notice Supported assets
  EnumerableSetUpgradeable.AddressSet internal _supportedAssets;

  // @notice custodian addresses
  EnumerableSetUpgradeable.AddressSet internal _custodianAddresses;

  /// @notice holds computable chain id
  uint256 private immutable _chainId;

  /// @notice holds computable domain separator
  bytes32 private immutable _domainSeparator;

  /// @notice user deduplication
  mapping(address => mapping(uint256 => uint256)) private _orderBitmaps;

  /// @notice USDe minted per block
  mapping(uint256 => uint256) public mintedPerBlock;
  /// @notice USDe redeemed per block
  mapping(uint256 => uint256) public redeemedPerBlock;

  /// @notice For smart contracts to delegate signing to EOA address
  mapping(address => address) public delegatedSigner;

  /// @notice max minted USDe allowed per block
  uint256 public maxMintPerBlock;
  /// @notice max redeemed USDe allowed per block
  uint256 public maxRedeemPerBlock;

  /* --------------- MODIFIERS --------------- */

  /// @notice ensure that the already minted USDe in the actual block plus the amount to be minted is below the maxMintPerBlock var
  /// @param mintAmount The USDe amount to be minted
  modifier belowMaxMintPerBlock(uint256 mintAmount) {
    if (mintedPerBlock[block.number] + mintAmount > maxMintPerBlock) revert MaxMintPerBlockExceeded();
    _;
  }

  /// @notice ensure that the already redeemed USDe in the actual block plus the amount to be redeemed is below the maxRedeemPerBlock var
  /// @param redeemAmount The USDe amount to be redeemed
  modifier belowMaxRedeemPerBlock(uint256 redeemAmount) {
    if (redeemedPerBlock[block.number] + redeemAmount > maxRedeemPerBlock) revert MaxRedeemPerBlockExceeded();
    _;
  }

  /* --------------- CONSTRUCTOR --------------- */

  constructor(
    IUSDe _usde,
    address[] memory _assets,
    address[] memory _custodians,
    address _owner,
    uint256 _maxMintPerBlock,
    uint256 _maxRedeemPerBlock
  ) {
    if (address(_usde) == address(0)) revert InvalidUSDeAddress();
    if (_assets.length == 0) revert NoAssetsProvided();
    if (_owner == address(0)) revert InvalidZeroAddress();
    usde = _usde;

    for (uint256 i = 0; i < _assets.length; i++) {
      addSupportedAsset(_assets[i]);
    }

    for (uint256 j = 0; j < _custodians.length; j++) {
      addCustodianAddress(_custodians[j]);
    }

    // Set the max mint/redeem limits per block
    _setMaxMintPerBlock(_maxMintPerBlock);
    _setMaxRedeemPerBlock(_maxRedeemPerBlock);

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _transferOwnership(_owner);

    _chainId = _getChainID();
    _domainSeparator = _computeDomainSeparator();

    emit USDeSet(address(_usde));
  }

  /* --------------- EXTERNAL --------------- */

  /**
   * @notice Mint stablecoins from assets
   * @param order struct containing order details and confirmation from server
   * @param signature signature of the taker
   */
  function mint(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
  ) public override nonReentrant onlyRole(MINTER_ROLE) belowMaxMintPerBlock(order.usde_amount) {
    verifyOrder(order, signature);
    if (!verifyRoute(route, order.order_type)) revert InvalidRoute();
    if (!_deduplicateOrder(order.benefactor, order.nonce)) revert Duplicate();
    // Add to the minted amount in this block
    mintedPerBlock[block.number] += order.usde_amount;
    _transferCollateral(order.collateral_amount, order.collateral_asset, order.benefactor, route.addresses, route.ratios);
    usde.mint(order.beneficiary, order.usde_amount);
    emit Mint(msg.sender, order.benefactor, order.beneficiary, order.collateral_asset, order.collateral_amount, order.usde_amount);
  }

  /**
   * @notice Redeem stablecoins for assets
   * @param order struct containing order details and confirmation from server
   * @param signature signature of the taker
   */
  function redeem(
    Order calldata order,
    Signature calldata signature
  ) public override nonReentrant onlyRole(REDEEMER_ROLE) belowMaxRedeemPerBlock(order.usde_amount) {
    require(order.order_type == OrderType.REDEEM);
    verifyOrder(order, signature);
    if (!_deduplicateOrder(order.benefactor, order.nonce)) revert Duplicate();
    // Add to the redeemed amount in this block
    redeemedPerBlock[block.number] += order.usde_amount;
    usde.burnFrom(order.benefactor, order.usde_amount);
    _transferToBeneficiary(order.beneficiary, order.collateral_asset, order.collateral_amount);
    emit Redeem(msg.sender, order.benefactor, order.beneficiary, order.collateral_asset, order.collateral_amount, order.usde_amount);
  }

  /// @notice Sets the usde contract address.
  function setUSDe(IUSDe _usde) external onlyOwner {
    if (address(_usde) == address(0)) revert InvalidAddress();
    address oldUSDe = address(usde);
    usde = _usde;
    emit USDeChanged(oldUSDe, address(usde));
  }

  /// @notice Sets the max mintPerBlock limit
  function setMaxMintPerBlock(uint256 _maxMintPerBlock) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setMaxMintPerBlock(_maxMintPerBlock);
  }

  /// @notice Sets the max redeemPerBlock limit
  function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setMaxRedeemPerBlock(_maxRedeemPerBlock);
  }

  /// @notice Disables the mint and redeem
  function disableMintRedeem() external onlyRole(GATEKEEPER_ROLE) {
    _setMaxMintPerBlock(0);
    _setMaxRedeemPerBlock(0);
  }

  /// @notice Enables smart contracts to delegate an address for signing
  function setDelegatedSigner(address _delegateTo) external {
    delegatedSigner[_delegateTo] = msg.sender;
  }

  /// @notice transfers an asset to a custody wallet
  function transferToCustody(
    address wallet,
    address asset,
    uint256 amount
  ) external nonReentrant onlyRole(MINTER_ROLE) {
    if (wallet == address(0) || !_custodianAddresses.contains(wallet)) revert InvalidAddress();
    if (asset == NATIVE_TOKEN) {
      (bool success, ) = wallet.call{value: amount}('');
      if (!success) revert TransferFailed();
    } else {
      IERC20(asset).safeTransfer(wallet, amount);
    }
    emit CustodyTransfer(wallet, asset, amount);
  }

  /// @notice Removes an asset from the supported assets list
  function removeSupportedAsset(address asset) external onlyOwner {
    if (!_supportedAssets.contains(asset)) revert InvalidAssetAddress();
    _supportedAssets.remove(asset);
    emit AssetRemoved(asset);
  }

  /// @notice Checks if an asset is supported.
  function isSupportedAsset(address asset) external view returns (bool) {
    return _supportedAssets.contains(asset);
  }

  /// @notice Removes an custodian from the custodian address list
  function removeCustodianAddress(address custodian) external onlyOwner {
    if (!_custodianAddresses.contains(custodian)) revert InvalidCustodianAddress();
    _custodianAddresses.remove(custodian);
    emit CustodianAddressRemoved(custodian);
  }

  /// @notice Removes the minter role from an account, this can ONLY be executed by the gatekeeper role
  /// @param minter The address to remove the minter role from
  function removeMinterRole(address minter) external onlyRole(GATEKEEPER_ROLE) {
    _revokeRole(MINTER_ROLE, minter);
  }

  /// @notice Removes the redeemer role from an account, this can ONLY be executed by the gatekeeper role
  /// @param redeemer The address to remove the redeemer role from
  function removeRedeemerRole(address redeemer) external onlyRole(GATEKEEPER_ROLE) {
    _revokeRole(REDEEMER_ROLE, redeemer);
  }

  /* --------------- PUBLIC --------------- */

  /// @notice Adds an asset to the supported assets list.
  function addSupportedAsset(address asset) public onlyOwner {
    if (asset == address(0) || asset == address(usde) || _supportedAssets.contains(asset)) revert InvalidAssetAddress();
    _supportedAssets.add(asset);
    emit AssetAdded(asset);
  }

  /// @notice Adds an custodian to the supported custodians list.
  function addCustodianAddress(address custodian) public onlyOwner {
    if (custodian == address(0) || custodian == address(usde) || _custodianAddresses.contains(custodian)) revert InvalidCustodianAddress();
    _custodianAddresses.add(custodian);
    emit CustodianAddressAdded(custodian);
  }

  /// @notice Get the domain separator for the token
  /// @dev Return cached value if chainId matches cache, otherwise recomputes separator, to prevent replay attack across forks
  /// @return The domain separator of the token at current chain
  function getDomainSeparator() public view returns (bytes32)   {
    if (_getChainID() == _chainId) {
      return _domainSeparator;
    }
    return _computeDomainSeparator();
  }

  /// @notice hash an Order struct
  function hashOrder(Order memory order) public view override returns (bytes32) {
    return keccak256(abi.encodePacked('\x19\x01', getDomainSeparator(), keccak256(encodeOrder(order))));
  }

  function encodeOrder(Order memory order) public pure returns (bytes memory) {
    return
      abi.encode(
        ORDER_TYPE,
        order.order_type,
        order.expiry,
        order.nonce,
        order.benefactor,
        order.beneficiary,
        order.collateral_asset,
        order.collateral_amount,
        order.usde_amount
      );
  }

  function encodeRoute(Route memory route) public pure returns (bytes memory) {
    return abi.encode(ROUTE_TYPE, route.addresses, route.ratios);
  }

  /// @notice assert validity of signed order
  function verifyOrder(
    Order calldata order,
    Signature calldata signature
  ) public view override returns (bool, bytes32) {
    bytes32 taker_order_hash = hashOrder(order);
    if (signature.signature_bytes.length != 65) revert InvalidSignatureLength();
    (bytes32 r, bytes32 s, uint8 v) = getRsv(signature.signature_bytes);
    address signer = ecrecover(taker_order_hash, v, r, s);
    if (!(signer == order.benefactor || delegatedSigner[signer] == order.benefactor)) revert InvalidSignature();
    if (order.beneficiary == address(0)) revert InvalidAmount();
    if (order.collateral_amount == 0) revert InvalidAmount();
    if (order.usde_amount == 0) revert InvalidAmount();
    if (block.timestamp > order.expiry) revert SignatureExpired();
    return (true, taker_order_hash);
  }

  /// @notice assert validity of route object per type
  function verifyRoute(Route calldata route, OrderType orderType) public view override returns (bool) {
    // routes only used to mint
    if (orderType == OrderType.REDEEM) {
      return true;
    }
    uint256 totalRatio = 0;
    if (route.addresses.length != route.ratios.length) {
      return false;
    }
    if (route.addresses.length == 0) {
      return false;
    }
    for (uint i = 0; i < route.addresses.length; ++i) {
      if (!_custodianAddresses.contains(route.addresses[i]) || route.addresses[i] == address(0) || route.ratios[i] == 0) {
        return false;
      }
      totalRatio += route.ratios[i];
    }
    if (totalRatio != 10_000) {
      return false;
    }
    return true;
  }

  /// @notice verify validity of nonce by checking its presence
  function verifyNonce(address sender, uint256 nonce) public view override returns (bool, uint256, uint256, uint256) {
    require(nonce > 0, 'Invalid nonce');
    uint256 invalidatorSlot = uint64(nonce) >> 8;
    uint256 invalidatorBit = 1 << uint8(nonce);
    mapping(uint256 => uint256) storage invalidatorStorage = _orderBitmaps[sender];
    uint256 invalidator = invalidatorStorage[invalidatorSlot];
    require(invalidator & invalidatorBit == 0, 'Invalid nonce');
    return (true, invalidatorSlot, invalidator, invalidatorBit);
  }

  /// @notice unpacks r, s, v from signature bytes
  function getRsv(bytes memory sig) public pure returns (bytes32, bytes32, uint8) {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := and(mload(add(sig, 65)), 255)
    }
    if (v < 27) v += 27;
    return (r, s, v);
  }

  /// @notice packs r, s, v into signature bytes
  function packRsv(bytes32 r, bytes32 s, uint8 v) public pure returns (bytes memory) {
    bytes memory sig = new bytes(65);
    assembly {
      mstore(add(sig, 32), r)
      mstore(add(sig, 64), s)
      mstore8(add(sig, 96), v)
    }
    return sig;
  }

  /* --------------- PRIVATE --------------- */

  /// @notice deduplication of taker order
  function _deduplicateOrder(address sender, uint256 nonce) private returns (bool) {
    (bool valid, uint256 invalidatorSlot, uint256 invalidator, uint256 invalidatorBit) = verifyNonce(sender, nonce);
    mapping(uint256 => uint256) storage invalidatorStorage = _orderBitmaps[sender];
    invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBit;
    return valid;
  }

  /* --------------- INTERNAL --------------- */

  /// @notice transfer supported asset to beneficiary address
  function _transferToBeneficiary(address beneficiary, address asset, uint256 amount) internal {
    if (asset == NATIVE_TOKEN) {
      if (address(this).balance < amount) revert InvalidAmount();
      (bool success, ) = (beneficiary).call{value: amount}('');
      if (!success) revert TransferFailed();
    } else {
      if (!_supportedAssets.contains(asset)) revert UnsupportedAsset();
      IERC20(asset).safeTransfer(beneficiary, amount);
    }
  }

  /// @notice transfer supported asset to array of custody addresses per defined ratio
  function _transferCollateral(
    uint256 amount,
    address asset,
    address benefactor,
    address[] calldata addresses,
    uint256[] calldata ratios
  ) internal {
    // cannot mint using unsupported asset or native ETH even if it is supported for redemptions
    if (!_supportedAssets.contains(asset) || asset == NATIVE_TOKEN) revert UnsupportedAsset();
    IERC20 token = IERC20(asset);
    uint256 totalTransferred = 0;
    for (uint i = 0; i < addresses.length; ++i) {
      uint256 amountToTransfer = (amount * ratios[i]) / 10_000;
      token.safeTransferFrom(benefactor, addresses[i], amountToTransfer);
      totalTransferred += amountToTransfer;
    }
    uint256 remainingBalance = amount - totalTransferred;
    if (remainingBalance > 0) {
      token.safeTransferFrom(benefactor, addresses[addresses.length - 1], remainingBalance);
    }
  }

  /// @notice Sets the max mintPerBlock limit
  function _setMaxMintPerBlock(uint256 _maxMintPerBlock) internal {
    uint256 oldMaxMintPerBlock = maxMintPerBlock;
    maxMintPerBlock = _maxMintPerBlock;
    emit MaxMintPerBlockChanged(oldMaxMintPerBlock, maxMintPerBlock);
  }

  /// @notice Sets the max redeemPerBlock limit
  function _setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) internal {
    uint256 oldMaxRedeemPerBlock = maxRedeemPerBlock;
    maxRedeemPerBlock = _maxRedeemPerBlock;
    emit MaxRedeemPerBlockChanged(oldMaxRedeemPerBlock, maxRedeemPerBlock);
  }

  function ecr(bytes32 message, uint8 v, bytes32 r, bytes32 s) public pure returns (address sender) {
    return ecrecover(message, v, r, s);
  }

  /// @notice Compute the current domain separator
  /// @return The domain separator for the token
  function _computeDomainSeparator() internal view returns (bytes32) {
    return keccak256(abi.encode(EIP712_DOMAIN, _getEIP712BaseId(), _EIP712_REVISION, _getChainID(), address(this)));
  }

  /// @notice returns the EIP712 base id
  function _getEIP712BaseId() internal pure returns (bytes32) {
    return keccak256('EthenaMinting');
  }

  /// @notice returns the chain id
  function _getChainID() internal view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}
