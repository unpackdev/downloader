//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./FeedRegistryInterface.sol";
import "./Denominations.sol";
import "./IPaymentStreamFactory.sol";
import "./PaymentStream.sol";

contract PaymentStreamFactory is IPaymentStreamFactory, Ownable {
  string public constant VERSION = "1.0.2";
  string public constant NAME = "PaymentStreamFactory";

  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address[] private allStreams;
  mapping(address => bool) private isOurs;

  // Chainlink Feed Registry: https://docs.chain.link/docs/feed-registry/
  // Aggregates all supported price feeds in one handy factory contract
  // Automatically supported TOKEN/USD and TOKEN/ETH pairs: https://docs.chain.link/docs/ethereum-addresses/
  FeedRegistryInterface public feedRegistry;

  // Some tokens like ETH or BTC have special addresses in the feed registry
  // token address => token denomination in Feed Registry
  mapping(address => address) public customFeedMapping;

  constructor(address _feedRegistry) {
    feedRegistry = FeedRegistryInterface(_feedRegistry);

    customFeedMapping[WETH] = Denominations.ETH;
  }

  /**
   * @notice Creates a new payment stream
   * @dev Payer (_msgSender()) is set as admin of "pausableRole", so he can grant and revoke the "pausable" role later on
   * @param _payee address that receives the payment stream
   * @param _usdAmount uint256 total amount in USD (scaled to 18 decimals) to be distributed until endTime
   * @param _token address of the ERC20 token that payee receives as payment
   * @param _fundingAddress address used to withdraw the drip
   * @param _endTime timestamp that sets drip distribution end
   */
  function createStream(
    address _payee,
    uint256 _usdAmount,
    address _token,
    address _fundingAddress,
    uint256 _endTime
  ) external returns (address streamAddress) {
    // Prevents the caller to create a Stream with an unsupported token
    // In case a USD/TOKEN or ETH/TOKEN Pair doesn't exist
    // This will revert with "Feed not found"
    usdToTokenAmount(_token, _usdAmount);

    streamAddress = address(
      new PaymentStream(
        _msgSender(),
        _payee,
        _usdAmount,
        _token,
        _fundingAddress,
        _endTime
      )
    );

    allStreams.push(streamAddress);
    isOurs[streamAddress] = true;

    emit StreamCreated(
      allStreams.length - 1,
      streamAddress,
      _msgSender(),
      _payee,
      _usdAmount
    );
  }

  /**
   * @notice Updates Chainlink FeedRegistry contract address
   * @dev Only contract owner can change feedRegistry
   * @param _newAddress address of new Chainlink FeedRegistry instance
   */
  function updateFeedRegistry(address _newAddress) external override onlyOwner {
    require(_newAddress != address(0), "invalid-feed-registry-address");
    require(_newAddress != address(feedRegistry), "same-feed-registry-address");

    emit FeedRegistryUpdated(address(feedRegistry), _newAddress);
    feedRegistry = FeedRegistryInterface(_newAddress);
  }

  /**
   * @notice Defines a custom mapping for token denominations in the Feed Registry
   * @param _token address of the ERC20 token
   * @param _denomination the denomination address that the feed registry uses for _token
   */
  function updateCustomFeedMapping(address _token, address _denomination)
    external
    onlyOwner
  {
    require(_denomination != address(0), "invalid-custom-feed-map");
    require(_denomination != customFeedMapping[_token], "same-custom-feed-map");

    customFeedMapping[_token] = _denomination;
    emit CustomFeedMappingUpdated(_token, _denomination);
  }

  /**
   * @notice Converts given amount in usd to target token amount using oracle
   * @param _token address of target token
   * @param _amount amount in USD (scaled to 18 decimals)
   * @return lastPrice target token amount
   */
  function usdToTokenAmount(address _token, uint256 _amount)
    public
    view
    override
    returns (uint256 lastPrice)
  {
    // tries a direct _token -> USD pair first
    try
      feedRegistry.getFeed(_tokenDenomination(_token), Denominations.USD)
    returns (AggregatorV2V3Interface) {
      uint256 _quote = _getQuote(_token, Denominations.USD);
      lastPrice =
        ((_amount * 1e18) / _quote) /
        10**(18 - IERC20Metadata(_token).decimals());
    } catch {
      // If getFeed reverts, uses token/ETH/usd route
      // If a feed doesn't exist for _token/ETH, it will revert with "Feed not found"
      uint256 _ethQuote = _getQuote(_token, Denominations.ETH);
      uint256 _ethUsdQuote = _getQuote(Denominations.ETH, Denominations.USD);
      uint256 _amountInETH = (_amount * 1e18) / _ethUsdQuote;
      lastPrice =
        ((_amountInETH * 1e18) / _ethQuote) /
        10**(18 - IERC20Metadata(_token).decimals());
    }
  }

  /**
   * @notice Checks if a address belongs to this contract' streams
   */
  function ours(address _a) external view override returns (bool) {
    return isOurs[_a];
  }

  /**
   * @notice Returns no. of streams stored in contract
   */
  function getStreamsCount() external view override returns (uint256) {
    return allStreams.length;
  }

  /**
   * @notice Returns address of the stream located at given id
   */
  function getStream(uint256 _idx) external view override returns (address) {
    return allStreams[_idx];
  }

  function _getQuote(address _base, address _quote)
    internal
    view
    returns (uint256)
  {
    (, int256 _price, , , ) =
      feedRegistry.latestRoundData(_tokenDenomination(_base), _quote);

    // USD decimals is 8 in ChainLink, scales it up to 18 decimals
    _price = (_quote == Denominations.USD) ? _price * 1e10 : _price;
    return uint256(_price);
  }

  function _tokenDenomination(address _token) internal view returns (address) {
    return
      (customFeedMapping[_token] == address(0))
        ? _token
        : customFeedMapping[_token];
  }
}
