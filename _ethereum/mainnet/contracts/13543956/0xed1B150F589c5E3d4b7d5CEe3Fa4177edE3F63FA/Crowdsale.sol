// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./Structs.sol";

contract Crowdsale is Ownable, Pausable {
  using SafeERC20 for IERC20;

  // ========================================
  // State variables
  // ========================================

  uint8 internal constant ETH_DECIMALS = 18;
  uint256 internal constant USD_PRICE = 100000000;

  // Constant contract configuration
  CrowdsaleBaseConfig internal config;

  // Amount of tokens sold during SALE phase
  // and not yet claimed
  uint256 public locked;

  // Amounts of tokens each address bought
  // and that are not yet claimed
  mapping(address => uint256) public balance;

  // Amounts of tokens each address bought
  mapping(address => uint256) public maxBalance;

  // Events
  event Buy(address indexed from, uint256 indexed value);
  event Claim(address indexed from, uint256 indexed value);

  // ========================================
  // Constructor
  // ========================================

  constructor(CrowdsaleBaseConfig memory _config) {
    // Copy config from memory to storage
    _initializeConfig(_config);
  }

  // ========================================
  // Main functions
  // ========================================

  // Transfer ETH and receive tokens in exchange
  receive() external payable {
    _buy(msg.value, false);
  }

  // Transfer Stablecoin and receive tokens in exchange
  function buyForUSD(uint256 value) external {
    _buy(value, true);
  }

  // Main function for buying tokens for both ETH and stable coins
  function _buy(uint256 value, bool stable) internal onlySalePhase whenNotPaused {
    require(value != 0, 'CS: transaction value is zero');

    // match payment decimals
    uint8 decimals = stable ? config.USDDecimals : ETH_DECIMALS;

    // Fetch current price for ETH or use 1 for stablecoins
    uint256 price = stable ? USD_PRICE : _currentEthPrice();

    // // Make sure tx value does not exceed max value in USD
    // require(
    //   _toUsd(value, price, decimals) <= config.maxUsdValue,
    //   'CS: transaction value exceeds maximal value in usd'
    // );

    // Calculate how many tokens to send in exchange
    uint256 tokens = _calculateTokenAmount(
      value,
      price,
      config.rate,
      config.tokenDecimals,
      decimals
    );

    // Stop if there is nothing to send
    require(tokens > 0, 'CS: token amount is zero');

    // Make sure there is enough tokens on contract address
    // and that is does not use tokens owned by previous buyers
    uint256 availableTokens = _tokenBalance() - locked;
    require(availableTokens >= tokens, 'CS: not enough tokens on sale');

    // If stablecoin is used, transfer coins from buyer to crowdsale
    if (stable) {
      config.USD.safeTransferFrom(msg.sender, address(this), value);
    }

    // Update balances
    balance[msg.sender] += tokens;
    maxBalance[msg.sender] += tokens;
    locked += tokens;

    emit Buy(msg.sender, tokens);
  }

  // Claim tokens in vesting stages
  function claim(uint256 value) external onlyVestingPhase whenNotPaused {
    require(balance[msg.sender] != 0, 'CS: sender has 0 tokens');
    require(balance[msg.sender] >= value, 'CS: not enough tokens');

    // Disallow to claim more tokens than current unlocked percentage
    // Ex Allow to claim 50% of tokens after 3 months
    require(value <= _maxTokensToUnlock(msg.sender), 'CS: value exceeds unlocked percentage');

    // Transfer tokens to user
    config.token.safeTransfer(msg.sender, value);

    // Update balances
    balance[msg.sender] -= value;
    locked -= value;

    emit Claim(msg.sender, value);
  }

  // ========================================
  // Public views
  // ========================================

  // Fetch configuration object
  function configuration() external view returns (CrowdsaleBaseConfig memory) {
    return _configuration();
  }

  // Fetch current price from price feed
  function currentEthPrice() external view returns (uint256) {
    return _currentEthPrice();
  }

  function tokenBalance() external view returns (uint256) {
    return _tokenBalance();
  }

  // Amount of unlocked tokens on contract
  function freeBalance() external view returns (uint256) {
    return _freeBalance();
  }

  // What percent of tokens can be claim at current time
  function unlockedPercentage() external view returns (uint256) {
    return _calculateUnlockedPercentage(config.stages, block.timestamp);
  }

  // How many tokens can be bought for selected ETH value
  function calculateTokenAmountForETH(uint256 value) external view returns (uint256) {
    return
      _calculateTokenAmount(
        value,
        _currentEthPrice(),
        config.rate,
        config.tokenDecimals,
        ETH_DECIMALS
      );
  }

    // How many tokens can be bought for selected ETH value
  function calculateTokenAmountForUSD(uint256 value) external view returns (uint256) {
    return
      _calculateTokenAmount(
        value,
        USD_PRICE,
        config.rate,
        config.tokenDecimals,
        config.USDDecimals
      );
  }

  // What tx value of ETH is needed to buy selected amount of tokens
  function calculatePaymentForETH(uint256 tokens) external view returns (uint256) {
    return
      _calculatePayment(
        tokens,
        _currentEthPrice(),
        config.rate,
        config.tokenDecimals,
        ETH_DECIMALS
      );
  }

    // What value of USD is needed to buy selected amount of tokens
  function calculatePaymentForUSD(uint256 tokens) external view returns (uint256) {
    return
      _calculatePayment(
        tokens,
        USD_PRICE,
        config.rate,
        config.tokenDecimals,
        config.USDDecimals
      );
  }

  // Maximal amount of tokens user can claim at current time
  function maxTokensToUnlock(address sender) external view returns (uint256) {
    return _maxTokensToUnlock(sender);
  }

  // ========================================
  // Owner utilities
  // ========================================

  // Used to send ETH to contract from owner
  function fund() external payable onlyOwner {}

  // Use to withdraw eth
  function transferEth(address payable to, uint256 value) external onlyOwner {
    to.transfer(value);
  }

  // Owner function used to withdraw tokens
  // Disallows to claim tokens belonging to other addresses
  function transferToken(address to, uint256 value) external onlyOwner {
    uint256 free = _tokenBalance() - locked;

    require(value <= free, 'CS: value exceeds locked value');

    config.token.safeTransfer(to, value);
  }

  // OWner utility function
  // Use in case other token is send to contract address
  function transferOtherToken(
    IERC20 otherToken,
    address to,
    uint256 value
  ) external onlyOwner {
    require(config.token != otherToken, 'CS: invalid token address');

    otherToken.safeTransfer(to, value);
  }

  // OWner utility function
  function pause() external onlyOwner {
    _pause();
  }

  // OWner utility function
  function unpause() external onlyOwner {
    _unpause();
  }

  // ========================================
  // Internals
  // ========================================

  function _tokenBalance() internal view returns (uint256) {
    return config.token.balanceOf(address(this));
  }

  function _freeBalance() internal view returns (uint256) {
    return _tokenBalance() - locked;
  }

  function _currentEthPrice() internal view returns (uint256) {
    (, int256 answer, , , ) = config.priceFeed.latestRoundData();
    return uint256(answer);
  }

  function _maxTokensToUnlock(address sender) internal view returns (uint256) {
    uint256 percentage = _calculateUnlockedPercentage(config.stages, block.timestamp);
    uint256 unlocked = _calculateMaxTokensToUnlock(balance[sender], maxBalance[sender], percentage);

    return unlocked;
  }

  function _calculateTokenAmount(
    uint256 value,
    uint256 price,
    uint256 rate,
    uint8 tokenDecimals,
    uint8 paymentDecimals
  ) internal pure returns (uint256) {
    return (price * value * uint256(10)**tokenDecimals) / rate / uint256(10)**paymentDecimals;
  }

  function _calculatePayment(
    uint256 tokens,
    uint256 price,
    uint256 rate,
    uint8 tokenDecimals,
    uint8 paymentDecimals
  ) internal pure returns (uint256) {
    return (tokens * rate * uint256(10)**paymentDecimals) / uint256(10)**tokenDecimals / price;
  }

  function _toUsd(
    uint256 value,
    uint256 price,
    uint8 paymentDecimals
  ) internal pure returns (uint256) {
    return (price * value) / uint256(10)**paymentDecimals;
  }

  function _calculateMaxTokensToUnlock(
    uint256 _balance,
    uint256 _maxBalance,
    uint256 _percentage
  ) internal pure returns (uint256) {
    if (_percentage == 0) return 0;
    if (_percentage >= 100) return _balance;

    uint256 maxTotal = (_maxBalance * _percentage) / 100;
    return maxTotal - (_maxBalance - _balance);
  }

  function _calculateUnlockedPercentage(Stage[] memory stages, uint256 currentTimestamp)
    internal
    pure
    returns (uint256)
  {
    // Allow to claim all if there are no stages
    if (stages.length == 0) return 100;

    uint256 unlocked = 0;

    for (uint256 i = 0; i < stages.length; i++) {
      if (currentTimestamp >= stages[i].timestamp) {
        unlocked = stages[i].percent;
      } else {
        break;
      }
    }

    return unlocked;
  }

  // Copy array of structs from storage to memory
  function _configuration() internal view returns (CrowdsaleBaseConfig memory) {
    CrowdsaleBaseConfig memory _config = config;
    Stage[] memory _stages = new Stage[](config.stages.length);

    for (uint8 i = 0; i < config.stages.length; i++) {
      _stages[i] = config.stages[i];
    }

    _config.stages = _stages;
    return _config;
  }

  // Copy array of structs from memory to storage
  function _initializeConfig(CrowdsaleBaseConfig memory _config) internal {
    config.token = _config.token;
    config.tokenDecimals = _config.tokenDecimals;
    config.USD = _config.USD;
    config.USDDecimals = _config.USDDecimals;
    config.rate = _config.rate;
    config.phaseSwitchTimestamp = _config.phaseSwitchTimestamp;
    config.priceFeed = _config.priceFeed;
    config.priceRestrictions = _config.priceRestrictions;
    config.maxUsdValue = _config.maxUsdValue;

    for (uint256 i = 0; i < _config.stages.length; i++) {
      config.stages.push(_config.stages[i]);
    }
  }

  // ========================================
  // Modifiers
  // ========================================

  // Phase guard
  modifier onlySalePhase() {
    require(block.timestamp < config.phaseSwitchTimestamp, 'CS: invalid phase, expected sale');
    _;
  }

  // Phase guard
  modifier onlyVestingPhase() {
    require(block.timestamp >= config.phaseSwitchTimestamp, 'CS: invalid phase, expected vesting');
    _;
  }
}
