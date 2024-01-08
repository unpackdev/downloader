// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IAdapterRegistry.sol";
import "./CloneLibrary.sol";
import "./ArrayHelper.sol";


abstract contract AbstractProtocolAdapter {
  using ArrayHelper for address[];

/* ========== Events ========== */

  event MarketFrozen(address token);

  event MarketUnfrozen(address token);

  event AdapterFrozen(address adapter);

  event AdapterUnfrozen(address adapter);

/* ========== Constants ========== */

  /**
   * @dev WETH address used for deciding whether to deploy an ERC20 or Ether adapter.
   */
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Global registry of adapters.
   */
  IAdapterRegistry public immutable registry;

/* ========== Storage ========== */

  /**
   * @dev List of adapters which have been deployed and then frozen.
   */
  address[] public frozenAdapters;

  /**
   * @dev List of tokens which have been frozen and which do not have an adapter.
   */
  address[] public frozenTokens;

  /**
   * @dev Number of tokens which have been mapped by the adapter.
   */
  uint256 public totalMapped;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) {
    registry = _registry;
  }

/* ========== Public Actions ========== */

  /**
   * @dev Map up to `max` tokens, starting at `totalMapped`.
   */
  function map(uint256 max) external virtual {
    address[] memory tokens = getUnmappedUpTo(max);
    uint256 len = tokens.length;
    address[] memory adapters = new address[](len);
    uint256 skipped;
    for (uint256 i; i < len; i++) {
      address token = tokens[i];
      if (isTokenMarketFrozen(token)) {
        skipped++;
        frozenTokens.push(token);
        emit MarketFrozen(token);
        continue;
      }
      address adapter = deployAdapter(token);
      adapters[i - skipped] = adapter;
    }
    totalMapped += len;
    assembly { if gt(skipped, 0) { mstore(adapters, sub(len, skipped)) } }
    registry.addTokenAdapters(adapters);
  }

  /**
   * @dev Unfreeze adapter at `index` in `frozenAdapters`.
   * Market for the adapter must not be frozen by the protocol.
   */
  function unfreezeAdapter(uint256 index) external virtual {
    address adapter = frozenAdapters[index];
    require(!isAdapterMarketFrozen(adapter), "Market still frozen");
    frozenAdapters.remove(index);
    registry.addTokenAdapter(adapter);
    emit AdapterUnfrozen(adapter);
  }

  /**
   * @dev Unfreeze token at `index` in `frozenTokens` and create a new adapter for it.
   * Market for the token must not be frozen by the protocol.
   */
  function unfreezeToken(uint256 index) external virtual {
    address token = frozenTokens[index];
    require(!isTokenMarketFrozen(token), "Market still frozen");
    frozenTokens.remove(index);
    address adapter = deployAdapter(token);
    registry.addTokenAdapter(adapter);
    emit MarketUnfrozen(token);
  }

  /**
   * @dev Freeze `adapter` - add it to `frozenAdapters` and remove it from the registry.
   * Does not verify adapter exists or has been registered by this contract because the
   * registry handles that.
   */
  function freezeAdapter(address adapter) external virtual {
    require(isAdapterMarketFrozen(adapter), "Market not frozen");
    frozenAdapters.push(adapter);
    registry.removeTokenAdapter(adapter);
    emit AdapterFrozen(adapter);
  }

/* ========== Internal Actions ========== */

  /**
   * @dev Deploys an adapter for `token`, which will either be an underlying token
   * or a wrapper token, whichever is returned by `getUnmapped`.
   */
  function deployAdapter(address token) internal virtual returns (address);

/* ========== Public Queries ========== */

  /**
   * @dev Name of the protocol the adapter is for.
   */
  function protocol() external view virtual returns (string memory);

  /**
   * @dev Get the list of tokens which have not already been mapped by the adapter.
   * Tokens may be underlying tokens or wrapper tokens for a lending market.
   */
  function getUnmapped() public view virtual returns (address[] memory tokens);

  /**
   * @dev Get up to `max` tokens which have not already been mapped by the adapter.
   * Tokens may be underlying tokens or wrapper tokens for a lending market.
   */
  function getUnmappedUpTo(uint256 max) public view virtual returns (address[] memory tokens) {
    tokens = getUnmapped();
    if (tokens.length > max) {
      assembly { mstore(tokens, max) }
    }
  }

  function getFrozenAdapters() external view returns (address[] memory tokens) {
    tokens = frozenAdapters;
  }

  function getFrozenTokens() external view returns (address[] memory tokens) {
    tokens = frozenTokens;
  }

/* ========== Internal Queries ========== */

  /**
   * @dev Check whether the market for an adapter is frozen.
   */
  function isAdapterMarketFrozen(address adapter) internal view virtual returns (bool);

  /**
   * @dev Check whether the market for a token is frozen.
   */
  function isTokenMarketFrozen(address token) internal view virtual returns (bool);
}