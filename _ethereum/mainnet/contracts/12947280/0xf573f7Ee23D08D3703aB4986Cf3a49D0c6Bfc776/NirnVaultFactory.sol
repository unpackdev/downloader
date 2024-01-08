// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IProxyManager.sol";
import "./IAdapterRegistry.sol";
import "./INirnVault.sol";
import "./ArrayHelper.sol";


contract NirnVaultFactory is Ownable() {
  using EnumerableSet for EnumerableSet.AddressSet;
  using ArrayHelper for EnumerableSet.AddressSet;

/* ========== Events ========== */

  event TokenApproved(address token);

  event SetDefaultRewardsSeller(address defaultRewardsSeller);

  event SetDefaultFeeRecipient(address defaultFeeRecipient);

/* ========== Constants ========== */

  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint256 public constant minimumAdapters = 2;
  bytes32 public constant erc20VaultImplementationId = keccak256("NirnVaultV1");
  bytes32 public constant ethVaultImplementationId = keccak256("EthNirnVaultV1");
  IProxyManager public immutable proxyManager;
  IAdapterRegistry public immutable registry;

/* ========== Storage ========== */

  EnumerableSet.AddressSet internal _approvedTokens;
  address public defaultFeeRecipient;
  address public defaultRewardsSeller;

/* ========== Constructor ========== */

  constructor(address _proxyManager, address _registry) {
    proxyManager = IProxyManager(_proxyManager);
    registry = IAdapterRegistry(_registry);
  }

/* ========== Configuration ========== */

  function approveToken(address token) external onlyOwner {
    require(!_approvedTokens.contains(token), "already approved");
    require(token != address(0), "null address");
    _approvedTokens.add(token);
    emit TokenApproved(token);
  }

  function setDefaultRewardsSeller(address _defaultRewardsSeller) external onlyOwner {
    require(_defaultRewardsSeller != address(0), "null address");
    defaultRewardsSeller = _defaultRewardsSeller;
    emit SetDefaultRewardsSeller(_defaultRewardsSeller);
  }

  function setDefaultFeeRecipient(address _defaultFeeRecipient) external onlyOwner {
    require(_defaultFeeRecipient != address(0), "null address");
    defaultFeeRecipient = _defaultFeeRecipient;
    emit SetDefaultFeeRecipient(_defaultFeeRecipient);
  }

/* ========== Queries ========== */

  function isTokenApproved(address token) external view returns (bool) {
    return _approvedTokens.contains(token);
  }

  function getApprovedTokens() external view returns (address[] memory approvedTokens) {
    approvedTokens = _approvedTokens.toArray();
  }

  function computeVaultAddress(address underlying) external view returns (address vault) {
    bytes32 implementationId = getImplementationId(underlying);
    bytes32 salt = keccak256(abi.encode(underlying));
    vault = proxyManager.computeProxyAddressManyToOne(address(this), implementationId, salt);
  }

  function getImplementationId(address underlying) internal pure returns (bytes32 implementationId) {
    return underlying == weth
      ? ethVaultImplementationId
      : erc20VaultImplementationId;
  }

/* ========== Actions ========== */

  function deployVault(address underlying) external {
    require(_approvedTokens.contains(underlying), "!approved");
    require(registry.getAdaptersCount(underlying) >= minimumAdapters, "insufficient adapters");
    address _defaultFeeRecipient = defaultFeeRecipient;
    require(_defaultFeeRecipient != address(0), "null default");
    bytes32 implementationId = getImplementationId(underlying);
    bytes32 salt = keccak256(abi.encode(underlying));
    address vault = proxyManager.deployProxyManyToOne(implementationId, salt);
    INirnVault(vault).initialize(underlying, defaultRewardsSeller, _defaultFeeRecipient, owner());
    registry.addVault(vault);
  }
}