// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// OpenZeppelin
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
// Chainlink
import "./FeedRegistryInterface.sol";
import "./Denominations.sol";

contract DustSweeper is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 private takerDiscountPercent;
  uint256 private protocolFeePercent;
  address private protocolWallet;

  struct TokenData {
    address tokenAddress;
    uint256 tokenPrice;
  }
  mapping(address => uint8) private tokenDecimals;

  // ChainLink
  address private chainLinkRegistry;
  address private quoteETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(
    address _chainLinkRegistry,
    address _protocolWallet,
    uint256 _takerDiscountPercent,
    uint256 _protocolFeePercent
  ) {
    chainLinkRegistry = _chainLinkRegistry;
    protocolWallet = _protocolWallet;
    takerDiscountPercent = _takerDiscountPercent;
    protocolFeePercent = _protocolFeePercent;
  }

  function sweepDust(
    address[] calldata makers,
    address[] calldata tokenAddresses
  ) external payable nonReentrant {
    // Make sure order data is valid
    require(makers.length > 0 && makers.length == tokenAddresses.length, "Passed order data in invalid format");
    // Track how much ETH was sent so we can return any overage
    uint256 ethSent = msg.value;
    uint256 totalNativeAmount = 0;
    TokenData memory lastToken;
    for (uint256 i = 0; i < makers.length; i++) {
      // Fetch/cache tokenDecimals
      if (tokenDecimals[tokenAddresses[i]] == 0) {
        bytes memory decData = Address.functionStaticCall(tokenAddresses[i], abi.encodeWithSignature("decimals()"));
        tokenDecimals[tokenAddresses[i]] = abi.decode(decData, (uint8));
      }
      require(tokenDecimals[tokenAddresses[i]] > 0, "Failed to fetch token decimals");

      // Fetch/cache tokenPrice
      if (i == 0 || lastToken.tokenPrice == 0 || lastToken.tokenAddress != tokenAddresses[i]) {
        // Need to fetch tokenPrice
        lastToken = TokenData(tokenAddresses[i], uint256(getPrice(tokenAddresses[i], quoteETH)));
      }
      require(lastToken.tokenPrice > 0, "Failed to fetch token price!");

      // Amount of Tokens to transfer
      uint256 allowance = IERC20(tokenAddresses[i]).allowance(makers[i], address(this));
      require(allowance > 0, "Allowance for specified token is 0");

      // Equivalent amount of Native Tokens
      uint256 nativeAmt = allowance * lastToken.tokenPrice / 10**tokenDecimals[tokenAddresses[i]];
      totalNativeAmount += nativeAmt;

      // Amount of Native Tokens to transfer
      uint256 distribution = nativeAmt * (10**4 - takerDiscountPercent) / 10**4;
      // Subtract distribution amount from ethSent amount
      ethSent -= distribution;

      // Taker sends Native Token to Maker
      Address.sendValue(payable(makers[i]), distribution);

      // DustSweeper sends Maker's tokens to Taker
      IERC20(tokenAddresses[i]).safeTransferFrom(makers[i], msg.sender, allowance);
    }

    // Taker pays protocolFee % for the total amount to avoid multiple transfers
    uint256 protocolNative = totalNativeAmount * protocolFeePercent / 10**4;
    // Subtract protocolFee from ethSent
    ethSent -= protocolNative;
    // Send to protocol wallet
    Address.sendValue(payable(protocolWallet), protocolNative);

    // Pay any overage back to msg.sender as long as overage > gas cost
    if (ethSent > 10000) {
      Address.sendValue(payable(msg.sender), ethSent);
    }
  }

  /**
 * Returns the latest price from Chainlink
 */
  function getPrice(address base, address quote) public view returns(int256) {
    (,int256 price,,,) = FeedRegistryInterface(chainLinkRegistry).latestRoundData(base, quote);
    return price;
  }

  // onlyOwner protected Setters/Getters
  function getTakerDiscountPercent() view external returns(uint256) {
    return takerDiscountPercent;
  }

  function setTakerDiscountPercent(uint256 _takerDiscountPercent) external onlyOwner {
    if (_takerDiscountPercent <= 5000) { // 50%
      takerDiscountPercent = _takerDiscountPercent;
    }
  }

  function getProtocolFeePercent() view external returns(uint256) {
    return protocolFeePercent;
  }

  function setProtocolFeePercent(uint256 _protocolFeePercent) external onlyOwner {
    if (_protocolFeePercent <= 1000) { // 10%
      protocolFeePercent = _protocolFeePercent;
    }
  }

  function getChainLinkRegistry() view external returns(address) {
    return chainLinkRegistry;
  }

  function setChainLinkRegistry(address _chainLinkRegistry) external onlyOwner {
    chainLinkRegistry = _chainLinkRegistry;
  }

  function getProtocolWallet() view external returns(address) {
    return protocolWallet;
  }

  function setProtocolWallet(address _protocolWallet) external onlyOwner {
    protocolWallet = _protocolWallet;
  }

  // Payment methods
  receive() external payable {}
  fallback() external payable {}

  function removeBalance(address tokenAddress) external onlyOwner {
    if (tokenAddress == address(0)) {
      Address.sendValue(payable(msg.sender), address(this).balance);
    } else {
      uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
      if (tokenBalance > 0) {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenBalance);
      }
    }
  }

}
