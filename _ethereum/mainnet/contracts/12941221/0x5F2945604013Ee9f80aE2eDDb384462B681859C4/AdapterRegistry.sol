// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ITokenAdapter.sol";
import "./IProtocolAdapter.sol";
import "./IAdapterRegistry.sol";
import "./INirnVault.sol";
import "./ArrayHelper.sol";
import "./DynamicArrays.sol";


contract AdapterRegistry is Ownable(), IAdapterRegistry {
  using ArrayHelper for address[];
  using ArrayHelper for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.AddressSet;
  using DynamicArrays for address[];
  using DynamicArrays for uint256[];

/* ========== Storage ========== */

  /** @dev Mapping from underlying token to registered vault. */
  mapping(address => address) public override vaultsByUnderlying;

  /** @dev Accounts allowed to register vaults. */
  mapping(address => bool) public override approvedVaultFactories;

  /** @dev List of all registered vaults. */
  EnumerableSet.AddressSet internal vaults;

  /** @dev Number of protocol adapters registered. */
  uint256 public override protocolsCount;

  /** @dev Mapping from protocol IDs to adapter addresses. */
  mapping(uint256 => address) public override protocolAdapters;

  /** @dev Mapping from protocol adapter addresses to protocol IDs. */
  mapping(address => uint256) public override protocolAdapterIds;

  /** @dev Mapping from underlying tokens to lists of adapters. */
  mapping(address => address[]) internal tokenAdapters;

  /** @dev Mapping from wrapper tokens to adapters. */
  mapping(address => TokenAdapter) internal adaptersByWrapperToken;

  /** @dev List of all underlying tokens with registered adapters. */
  EnumerableSet.AddressSet internal supportedTokens;

/* ========== Modifiers ========== */

  modifier onlyProtocolOrOwner {
    require(protocolAdapterIds[msg.sender] > 0 || msg.sender == owner(), "!approved");
    _;
  }

  function getProtocolAdapterId(address protocolAdapter) internal view returns (uint256 id) {
    require((id = protocolAdapterIds[protocolAdapter]) > 0, "!exists");
  }

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external override onlyOwner {
    require(_factory != address(0), "null address");
    require(!approvedVaultFactories[_factory], "already approved");
    approvedVaultFactories[_factory] = true;
    emit VaultFactoryAdded(_factory);
  }

  function removeVaultFactory(address _factory) external override onlyOwner {
    require(approvedVaultFactories[_factory], "!approved");
    approvedVaultFactories[_factory] = false;
    emit VaultFactoryRemoved(_factory);
  }

/* ========== Vault Management ========== */

  function addVault(address vault) external override {
    require(approvedVaultFactories[msg.sender], "!approved");
    address underlying = INirnVault(vault).underlying();
    require(vaultsByUnderlying[underlying] == address(0), "exists");
    vaultsByUnderlying[underlying] = vault;
    vaults.add(vault);
    emit VaultAdded(underlying, vault);
  }

  function removeVault(address vault) external override onlyOwner {
    address underlying = INirnVault(vault).underlying();
    require(vaultsByUnderlying[underlying] != address(0), "!exists");
    vaultsByUnderlying[underlying] = address(0);
    vaults.remove(vault);
    emit VaultRemoved(underlying, vault);
  }

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external override onlyProtocolOrOwner returns (uint256 id) {
    require(protocolAdapter != address(0), "null");
    require(protocolAdapterIds[protocolAdapter] == 0, "exists");
    id = ++protocolsCount;
    protocolAdapterIds[protocolAdapter] = id;
    protocolAdapters[id] = protocolAdapter;
    emit ProtocolAdapterAdded(id, protocolAdapter);
  }

  function removeProtocolAdapter(address protocolAdapter) external override onlyOwner {
    uint256 id = getProtocolAdapterId(protocolAdapter);
    delete protocolAdapterIds[protocolAdapter];
    delete protocolAdapters[id];
    emit ProtocolAdapterRemoved(id);
  }

/* ========== Token Adapter Management ========== */

  function _addTokenAdapter(IErc20Adapter adapter, uint256 id) internal {
    address underlying = adapter.underlying();
    address wrapper = adapter.token();
    require(adaptersByWrapperToken[wrapper].protocolId == 0, "adapter exists");
    if (tokenAdapters[underlying].length == 0) {
      supportedTokens.add(underlying);
      emit TokenSupportAdded(underlying);
    }
    tokenAdapters[underlying].push(address(adapter));
    adaptersByWrapperToken[wrapper] = TokenAdapter(address(adapter), uint96(id));
    emit TokenAdapterAdded(address(adapter), id, underlying, wrapper);
  }

  function addTokenAdapter(address adapter) external override {
    uint256 id = getProtocolAdapterId(msg.sender);
    _addTokenAdapter(IErc20Adapter(adapter), id);
  }

  function addTokenAdapters(address[] calldata adapters) external override {
    uint256 id = getProtocolAdapterId(msg.sender);
    uint256 len = adapters.length;
    for (uint256 i = 0; i < len; i++) {
      IErc20Adapter adapter = IErc20Adapter(adapters[i]);
      _addTokenAdapter(adapter, id);
    }
  }

  function removeTokenAdapter(address adapter) external override {
    address wrapper = IErc20Adapter(adapter).token();
    TokenAdapter memory adapterRecord = adaptersByWrapperToken[wrapper];
    require(adapterRecord.adapter == address(adapter), "wrong adapter");
    uint256 protocolId = adapterRecord.protocolId;
    require(
      msg.sender == owner() ||
      msg.sender == protocolAdapters[protocolId],
      "!authorized"
    );
    delete adaptersByWrapperToken[wrapper];
    address underlying = IErc20Adapter(adapter).underlying();
    address[] storage adapters = tokenAdapters[underlying];
    uint256 index = adapters.indexOf(address(adapter));
    adapters.remove(index);
    if (adapters.length == 0) {
      supportedTokens.remove(underlying);
      emit TokenSupportRemoved(underlying);
    }
    emit TokenAdapterRemoved(address(adapter), protocolId, underlying, wrapper);
  }

/* ========== Vault Queries ========== */

  function getVaultsList() external view override returns (address[] memory) {
    return vaults.toArray();
  }

  function haveVaultFor(address underlying) external view override returns (bool) {
    return vaultsByUnderlying[underlying] != address(0);
  }

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view override returns (address[] memory adapters, uint256[] memory ids) {
    uint256 len = protocolsCount;
    adapters = DynamicArrays.dynamicAddressArray(len);
    ids = DynamicArrays.dynamicUint256Array(len);
    for (uint256 id = 1; id <= len; id++) {
      address adapter = protocolAdapters[id];
      if (adapter != address(0)) {
        adapters.dynamicPush(adapter);
        ids.dynamicPush(id);
      }
    }
  }

  function getProtocolMetadata(uint256 id) external view override returns (address protocolAdapter, string memory name) {
    protocolAdapter = protocolAdapters[id];
    require(protocolAdapter != address(0), "invalid id");
    name = IProtocolAdapter(protocolAdapter).protocol();
  }

  function getProtocolForTokenAdapter(address adapter) external view override returns (address protocolAdapter) {
    address wrapper = IErc20Adapter(adapter).token();
    TokenAdapter memory adapterRecord = adaptersByWrapperToken[wrapper];
    require(adapterRecord.adapter == adapter, "!approved");
    protocolAdapter = protocolAdapters[adapterRecord.protocolId];
  }

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view override returns (bool) {
    return tokenAdapters[underlying].length > 0;
  }

  function getSupportedTokens() external view override returns (address[] memory list) {
    list = supportedTokens.toArray();
  }

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view override returns (bool) {
    address wrapper = IErc20Adapter(adapter).token();
    TokenAdapter memory adapterRecord = adaptersByWrapperToken[wrapper];
    return adapterRecord.adapter == adapter;
  }

  function getAdaptersList(address underlying) public view override returns (address[] memory list) {
    list = tokenAdapters[underlying];
  }

  function getAdapterForWrapperToken(address wrapperToken) external view override returns (address) {
    return adaptersByWrapperToken[wrapperToken].adapter;
  }

  function getAdaptersCount(address underlying) external view override returns (uint256) {
    return tokenAdapters[underlying].length;
  }

  function getAdaptersSortedByAPR(address underlying)
    public
    view
    override
    returns (address[] memory adapters, uint256[] memory aprs)
  {
    adapters = getAdaptersList(underlying);
    uint256 len = adapters.length;
    aprs = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      try IErc20Adapter(adapters[i]).getAPR() returns (uint256 apr) {
        aprs[i] = apr;
      } catch {
        aprs[i] = 0;
      }
    }
    adapters.sortByDescendingScore(aprs);
  }

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    public
    view
    override
    returns (address[] memory adapters, uint256[] memory aprs)
  {
    adapters = getAdaptersList(underlying);
    uint256 len = adapters.length;
    aprs = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      address adapter = adapters[i];
      if (adapter == excludingAdapter) {
        try IErc20Adapter(adapter).getAPR() returns (uint256 apr) {
          aprs[i] = apr;
        } catch {
          aprs[i] = 0;
        }
      } else {
        try IErc20Adapter(adapter).getHypotheticalAPR(int256(deposit)) returns (uint256 apr) {
          aprs[i] = apr;
        } catch {
          aprs[i] = 0;
        }
      }
    }
    adapters.sortByDescendingScore(aprs);
  }

  function getAdapterWithHighestAPR(address underlying) external view override returns (address adapter, uint256 apr) {
    (address[] memory adapters, uint256[] memory aprs) = getAdaptersSortedByAPR(underlying);
    adapter = adapters[0];
    apr = aprs[0];
  }

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view override returns (address adapter, uint256 apr) {
    (address[] memory adapters, uint256[] memory aprs) = getAdaptersSortedByAPRWithDeposit(
      underlying,
      deposit,
      excludingAdapter
    );
    adapter = adapters[0];
    apr = aprs[0];
  }
}
