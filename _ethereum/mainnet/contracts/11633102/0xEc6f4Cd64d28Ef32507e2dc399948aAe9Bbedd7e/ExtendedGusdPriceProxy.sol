// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

interface IExtendedAggregator {
  /**
   * @notice Return the address of the token of which this proxy provides the price of
   * @return address token
   */
  function getToken() external view returns (address);

  /**
   * @notice Return the numeric type of this proxy
   * @return uint256 type
   */
  function getTokenType() external view returns (uint256);

  /**
   * @notice Return the list of dependencies from where to check events on price updates
   * @return address[] addresses
   */
  function getSubTokens() external view returns (address[] memory);

  /**
   * @notice Returns the price
   * @return int256 price
   */
  function latestAnswer() external view returns (int256);

  /**
   * - 0: Invalid
   * - 1: Simple token
   * - 2: Complex token, with its price depending from other sources, for offchain tracking purposes
   */
  enum ProxyType {Invalid, Simple, Complex}
}

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}

contract ExtendedGusdPriceProxy is IExtendedAggregator {
  IChainlinkAggregator public constant ETH_USD_CHAINLINK_PROXY = IChainlinkAggregator(
    0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
  );
  int256 public constant NORMALIZATION = 1e8 * 1 ether; // 8 decimals to normalized the format on the ETH/USD pair and multiplying by 1 ether to get the price in wei
  address public constant ETH_USD_MOCK_ADDRESS = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;

  address internal constant GUSD = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
  ProxyType internal constant TYPE = ProxyType.Complex; // 2 = "Complex token", with its price depending from other sources, for offchain tracking purposes
  address[] internal _subTokens;

  event Setup(address indexed token, ProxyType proxyType, address[] subTokens);

  constructor() {
    _subTokens.push(ETH_USD_MOCK_ADDRESS);

    emit Setup(GUSD, TYPE, _subTokens);
  }

  function latestAnswer() external override view returns (int256) {
    int256 priceFromChainlink = ETH_USD_CHAINLINK_PROXY.latestAnswer();

    return (priceFromChainlink <= 0) ? 0 : NORMALIZATION / priceFromChainlink;
  }

  function getToken() external override pure returns (address) {
    return GUSD;
  }

  function getTokenType() external override pure returns (uint256) {
    return uint256(TYPE);
  }

  function getSubTokens() external override view returns (address[] memory) {
    return _subTokens;
  }
}