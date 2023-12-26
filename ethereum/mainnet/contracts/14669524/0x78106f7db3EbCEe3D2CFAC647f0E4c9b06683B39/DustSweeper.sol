// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SafeTransferLib.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Trustus.sol";

/// @title DustSweeper
/// @notice Allows users to swap small balance tokens for ETH without expensive gas transactions
contract DustSweeper is Ownable, ReentrancyGuard, Trustus {
  using SafeTransferLib for ERC20;

  /// @notice Events
  event Sweep(address indexed makerAddress, address indexed tokenAddress, uint256 tokenAmount, uint256 ethAmount);
  event ProtocolPayout(uint256 protocolSplit, uint256 governorSplit);
  /// @notice Errors
  error ZeroAddress();
  error NoBalance();
  error NotContract();
  error NoTokenPrice(address tokenAddress);
  error NoSweepableOrders();
  error InsufficientNative(uint256 sendAmount, uint256 remainingBalance);
  error OutOfRange(uint256 param);

  struct Token {
    bool tokenSetup;
    uint8 decimals;
    uint8 takerDiscountTier;
  }

  struct CurrentToken {
    address tokenAddress;
    uint8 decimals;
    uint256 price;
  }

  struct TokenPrice {
    address addr;
    uint256 price;
  }

  struct Native {
    uint256 balance;
    uint256 total;
    uint256 protocol;
  }

  struct Order {
    uint256 nativeAmount;
    uint256 tokenAmount;
    uint256 distributionAmount;
    address payable destinationAddress;
  }

  address payable public protocolWallet;
  address payable public governorWallet;
  uint256 public protocolFee;
  uint256 public protocolPayoutSplit;

  mapping(address => Token) private tokens;
  mapping(uint8 => uint256) public takerDiscountTiers;
  mapping(address => address payable) public destinations;

  /// @notice Trustus Packet Request
  bytes32 public constant TRUSTUS_REQUEST_VALUE = 0xfc7ecbf4f091085173dad8d1d3c2dfd218c018596a572201cd849763d1114e7a;

  /// @notice Whitelist
  bool public sweepWhitelistOn;
  mapping(address => bool) public sweepWhitelist;

  /// @notice Limits
  uint256 public constant MAX_TAKER_DISCOUNT_PCT = 10000;
  uint256 public constant MAX_PROTOCOL_FEE_PCT = 5000;
  uint256 public constant MAX_PROTOCOL_PAYOUT_SPLIT_PCT = 10000;
  uint256 public constant MIN_OVERAGE_RETURN_WEI = 7000;
  uint256 public constant MAX_SWEEP_ORDER_SIZE = 200;

  constructor(
    address payable _protocolWallet,
    address payable _governorWallet,
    uint256[] memory _takerDiscountTiers,
    uint256 _protocolFeePercent,
    uint256 _protocolPayoutSplitPercent
  ) {
    // Check Input
    if (_protocolWallet == address(0))
      revert ZeroAddress();
    if (_governorWallet == address(0))
      revert ZeroAddress();
    if (_protocolFeePercent > MAX_PROTOCOL_FEE_PCT)
      revert OutOfRange(_protocolFeePercent);
    if (_protocolPayoutSplitPercent > MAX_PROTOCOL_PAYOUT_SPLIT_PCT)
      revert OutOfRange(_protocolPayoutSplitPercent);
    // Taker Discount Tiers
    uint256 _takerDiscountTierslength = _takerDiscountTiers.length;
    for (uint8 t = 0;t < _takerDiscountTierslength;++t) {
      if (_takerDiscountTiers[t] > MAX_TAKER_DISCOUNT_PCT)
        revert OutOfRange(_takerDiscountTiers[t]);
      takerDiscountTiers[t] = _takerDiscountTiers[t];
    }
    // Wallets
    protocolWallet = _protocolWallet;
    governorWallet = _governorWallet;
    // Protocol Fee %
    protocolFee = _protocolFeePercent;
    // Protocol Payout Split Percent
    protocolPayoutSplit = _protocolPayoutSplitPercent;
  }

  /// @notice Method that is called by taker bots to exchange ETH for a list of ERC20 tokens at a discount
  /// @dev Taker bot needs to call offchain API to get packet with current price data for tokens they intend to sweep
  /// @dev makers & tokenAddresses are mapped and need to be the same size
  /// @dev tokenAddresses[0] is the ERC20 token address that will be swept from makers[0], tokenAddresses[1] corresponds with makers[1]...
  /// @param makers List of maker addresses that have approved an ERC20 token and taker bot intends to sweep
  /// @param tokenAddresses List of ERC20 tokenAddresses that correspond with makers list to be swept
  /// @param packet The packet that contains current prices for tokens the taker bot intends to sweep, is generated and signed offchain using API
  function sweepDust(
    address[] calldata makers,
    address[] calldata tokenAddresses,
    TrustusPacket calldata packet
  ) external payable nonReentrant verifyPacket(TRUSTUS_REQUEST_VALUE, packet) {
    // Check whitelist
    if (sweepWhitelistOn && !sweepWhitelist[msg.sender])
      revert NoSweepableOrders();
    TokenPrice[] memory tokenPrices = abi.decode(packet.payload, (TokenPrice[]));
    Native memory native = Native(msg.value, 0, 0);
    // Order is valid length
    uint256 makerLength = makers.length;
    if (makerLength == 0 || makerLength > MAX_SWEEP_ORDER_SIZE || makerLength != tokenAddresses.length)
      revert NoSweepableOrders();
    CurrentToken memory currentToken = CurrentToken(address(0), 0, 0);
    for (uint256 i = 0; i < makerLength; ++i) {
      Order memory order = Order(0, 0, 0, payable(address(0)));
      // Get tokenAmount to be swept
      order.tokenAmount = getTokenAmount(tokenAddresses[i], makers[i]);
      if (order.tokenAmount <= 0)
        continue;

      if (currentToken.tokenAddress != tokenAddresses[i]) {
        currentToken.tokenAddress = tokenAddresses[i];
        // Setup Token if needed
        if (!tokens[tokenAddresses[i]].tokenSetup)
          setupToken(tokenAddresses[i]);
        // Get tokenDecimals
        currentToken.decimals = getTokenDecimals(tokenAddresses[i]);
        // Get tokenPrice
        currentToken.price = getPrice(tokenAddresses[i], tokenPrices);
        if (currentToken.price == 0)
          revert NoTokenPrice(tokenAddresses[i]);
      }

      // DustSweeper sends Maker's tokens to Taker
      ERC20(tokenAddresses[i]).safeTransferFrom(makers[i], msg.sender, order.tokenAmount);

      // Equivalent amount of Native Tokens
      order.nativeAmount = ((order.tokenAmount * currentToken.price) / (10**currentToken.decimals));
      native.total += order.nativeAmount;

      // Amount of Native Tokens to transfer
      order.distributionAmount = (order.nativeAmount * (1e4 - takerDiscountTiers[getTokenTakerDiscountTier(tokenAddresses[i])])) / 1e4;
      if (order.distributionAmount > native.balance)
        revert InsufficientNative(order.distributionAmount, native.balance);
      // Subtract order.distributionAmount from native.balance amount
      native.balance -= order.distributionAmount;

      // If maker has specified a destinationAddress send ETH there otherwise send to maker address
      order.destinationAddress = destinations[makers[i]] == address(0) ? payable(makers[i]) : destinations[makers[i]];
      // Taker sends Native Token to Maker
      SafeTransferLib.safeTransferETH(order.destinationAddress, order.distributionAmount);
      // Log Event
      emit Sweep(makers[i], tokenAddresses[i], order.tokenAmount, order.distributionAmount);
    }
    // Taker pays protocolFee % for the total amount to avoid multiple transfers
    native.protocol = (native.total * protocolFee) / 1e4;
    if (native.protocol > native.balance)
      revert InsufficientNative(native.protocol, native.balance);
    // Subtract protocolFee from native.balance and leave in contract
    native.balance -= native.protocol;

    // Pay any overage back to msg.sender as long as overage > MIN_OVERAGE_RETURN_WEI
    if (native.balance > MIN_OVERAGE_RETURN_WEI) {
      SafeTransferLib.safeTransferETH(payable(msg.sender), native.balance);
    }
  }

  /// @notice Calculates the amount of ERC20 token to be swept
  /// @dev If balance is lower than allowance will return balance, otherwise entire allowance is returned
  /// @param _tokenAddress Address of the ERC20 token
  /// @param _makerAddress Address of the maker to fetch allowance/balance for specified ERC20 token
  /// @return The amount of the specified ERC20 token that can be swept
  function getTokenAmount(address _tokenAddress, address _makerAddress) private view returns(uint256) {
    // Check Allowance
    uint256 allowance = ERC20(_tokenAddress).allowance(_makerAddress, address(this));
    if (allowance == 0)
      return 0;
    uint256 balance = ERC20(_tokenAddress).balanceOf(_makerAddress);
    return balance < allowance ? balance : allowance;
  }

  /// @notice Fetches price for specified ERC20 token using the signed price packets
  /// @dev Iterates through the tokens/prices in the attached Trustus price packet, returns 0 if not found
  /// @param _tokenAddress Address of the ERC20 token
  /// @param _tokenPrices Array of TokenPrice structs generated and signed offchain
  /// @return Price in ETH of the specified ERC20 token
  function getPrice(address _tokenAddress, TokenPrice[] memory _tokenPrices) private pure returns(uint256) {
    uint256 tokenPricesLength = _tokenPrices.length;
    for (uint256 i = 0;i < tokenPricesLength;++i) {
      if (_tokenAddress == _tokenPrices[i].addr) {
        return _tokenPrices[i].price;
      }
    }
    return 0;
  }

  /// @notice Does first time setup of specified ERC20 token including caching decimals value from token contract
  /// @dev Attempts to fetch and cache the decimals value using the decimals() method on token contract, defaults to 18
  /// @param _tokenAddress Address of the ERC20 token to set up
  function setupToken(address _tokenAddress) public {
    (bool success, bytes memory result) = _tokenAddress.staticcall(abi.encodeWithSignature("decimals()"));
    uint8 decimals = 18;
    if (success)
      decimals = abi.decode(result, (uint8));
    tokens[_tokenAddress].tokenSetup = true;
    tokens[_tokenAddress].decimals = decimals;
  }

  /// @notice Returns the cached decimals value for the specified ERC20 token
  /// @dev This value is cached by calling decimals() method on ERC20 token contract during setupToken()
  /// @param _tokenAddress Address of the ERC20 token
  /// @return Decimals value for the specified ERC20 token
  function getTokenDecimals(address _tokenAddress) public view returns(uint8) {
    return tokens[_tokenAddress].decimals;
  }

  /// @notice Returns the takerDiscountTier for the specified ERC20 token
  /// @dev Use this method in conjunction with takerDiscountTiers(tier) to get the takerDiscount percent
  /// @param _tokenAddress Address of the ERC20 token
  /// @return takerDiscountTier that the specified ERC20 belongs to
  function getTokenTakerDiscountTier(address _tokenAddress) public view returns(uint8) {
    return tokens[_tokenAddress].takerDiscountTier;
  }

  /// @notice Allows makers to specify a different address for takers to send ETH to in exchange for ERC20 tokens
  /// @dev This needs to be called by the maker before the sweepDust of approved tokens takes place
  /// @param _destinationAddress The target address to receive distribution amount from taker, if not set will send to maker address
  function setDestinationAddress(address _destinationAddress) external {
    if (_destinationAddress == address(0))
      revert ZeroAddress();
    destinations[msg.sender] = payable(_destinationAddress);
  }

  /// @notice Set the token decimal field for the specified ERC20 token
  /// @dev The decimals field should be filled via the token contract decimals() method on token setup
  /// @dev If the decimals field is incorrect or not filled properly this method can be used to set it
  /// @param _tokenAddress Address of ERC20 token to update decimals field for
  /// @param _decimals The decimal value for the specified ERC20 token (valid range: 0-18)
  function setTokenDecimals(address _tokenAddress, uint8 _decimals) external onlyOwner {
    if (_tokenAddress == address(0))
      revert ZeroAddress();
    tokens[_tokenAddress].decimals = _decimals;
  }

  /// @notice Change the taker fee tier for the specified ERC20 token
  /// @dev Tokens start in the default taker fee tier (0) but tokens can be switched to low (1) or high (2) fee tiers
  /// @param _tokenAddress Address of the ERC20 token
  /// @param _tier Tier to assign to specified ERC20 token, must be a valid tier (non zero taker fee value in takerDiscountTiers)
  function setTokenTakerDiscountTier(address _tokenAddress, uint8 _tier) external onlyOwner {
    if (_tokenAddress == address(0))
      revert ZeroAddress();
    if (takerDiscountTiers[_tier] == 0)
      revert OutOfRange(_tier);
    tokens[_tokenAddress].takerDiscountTier = _tier;
  }

  /// @notice Used to calculate the discount percent given to the taker bot for sweeping tokens
  /// @dev This method can be used to add a new taker fee tier or adjust existing tier value
  /// @param _takerDiscountPercent Percent * 100, 100% == 10000, 50% == 5000 (valid range: 1-10000)
  /// @param _tier Tier to update
  function setTakerDiscountPercent(uint256 _takerDiscountPercent, uint8 _tier) external onlyOwner {
    if (_takerDiscountPercent == 0 || _takerDiscountPercent > MAX_TAKER_DISCOUNT_PCT)
      revert OutOfRange(_takerDiscountPercent);
    takerDiscountTiers[_tier] = _takerDiscountPercent;
  }

  /// @notice Set the percent that the taker bot pays out to the protocol in ETH
  /// @dev Protocol fee is calculated by taking the total ETH value of tokens multiplied by protocolFee
  /// @param _protocolFeePercent Percent * 100, 100% == 10000, 50% == 5000 (valid range: 0-5000)
  function setProtocolFeePercent(uint256 _protocolFeePercent) external onlyOwner {
    if (_protocolFeePercent > MAX_PROTOCOL_FEE_PCT)
      revert OutOfRange(_protocolFeePercent);
    protocolFee = _protocolFeePercent;
  }

  /// @notice Change the address of the protocol wallet
  /// @dev Split for payout of protocolWallet is determined by protocolPayoutSplit value
  /// @param _protocolWallet Address where the contract will send protocol split of collected fees to
  function setProtocolWallet(address payable _protocolWallet) external onlyOwner {
    if (_protocolWallet == address(0))
      revert ZeroAddress();
    protocolWallet = _protocolWallet;
  }

  /// @notice Change the address of the governor wallet
  /// @dev Split for payout of governorWallet is determined by sending balance left after protocolWallet is paid
  /// @param _governorWallet Address where the contract will send governor split of collected fees to
  function setGovernorWallet(address payable _governorWallet) external onlyOwner {
    if (_governorWallet == address(0))
      revert ZeroAddress();
    governorWallet = _governorWallet;
  }

  /// @notice Sets the percentage of protocol fees that are sent to protocol wallet
  /// @dev Protocol fees are split between protocolWallet & governorWallet
  /// @dev Setting this to 10000 (100%) sends all fees to protocolWallet
  /// @dev Setting this to 0 (0%) sends all fees to governorWallet
  /// @param _protocolPayoutSplitPercent Percent * 100, 100% == 10000, 50% == 5000 (valid range: 0-10000)
  function setProtocolPayoutSplit(uint256 _protocolPayoutSplitPercent) external onlyOwner {
    if (_protocolPayoutSplitPercent > MAX_PROTOCOL_PAYOUT_SPLIT_PCT)
      revert OutOfRange(_protocolPayoutSplitPercent);
    protocolPayoutSplit = _protocolPayoutSplitPercent;
  }

  /// @notice Adds or removes addresses from the trusted signer list
  /// @dev Addresses that are set to true in Trustus.isTrusted mapping are allowed to sign offchain price packets
  /// @param _trustedProviderAddress Address to add/remove from the isTrusted list used for offchain signing
  function toggleIsTrusted(address _trustedProviderAddress) external onlyOwner {
    if (_trustedProviderAddress == address(0))
      revert ZeroAddress();
    bool _isTrusted = isTrusted[_trustedProviderAddress] ? false : true;
    _setIsTrusted(_trustedProviderAddress, _isTrusted);
  }

  /// @notice Checks if specified address is a trusted signer
  /// @dev A getter function which can be used to see if address is in the internal isTrusted mapping
  /// @param _trustedProviderAddress Address to check against isTrusted mapping
  /// @return True if address is in isTrusted mapping, false otherwise
  function getIsTrusted(address _trustedProviderAddress) external view returns(bool) {
    return isTrusted[_trustedProviderAddress];
  }

  /// @notice Turns on/off the taker bot whitelist
  /// @dev If this is turned on only whitelisted addresses will be able to run the sweepDust method
  function toggleSweepWhitelist() external onlyOwner {
    sweepWhitelistOn = sweepWhitelistOn ? false : true;
  }

  /// @notice Adds or removes addresses from taker bot whitelist
  /// @dev Get the status of whitelisted addresses using sweepWhitelist(address)
  /// @param _whitelistAddress Address of taker bot to whitelist
  function toggleSweepWhitelistAddress(address _whitelistAddress) external onlyOwner {
    if (_whitelistAddress == address(0))
      revert ZeroAddress();
    sweepWhitelist[_whitelistAddress] = sweepWhitelist[_whitelistAddress] ? false : true;
  }

  /// @notice Use this method to pay out accumulated protocol fees
  /// @dev ETH protocol fees stored in contract are split between protocolWallet & governorWallet based on protocolPayoutSplit
  function payoutProtocolFees() external nonReentrant {
    uint256 balance = address(this).balance;
    if (balance <= 0)
      revert NoBalance();
    // Protocol Split
    uint256 protocolSplit = (balance * protocolPayoutSplit) / 1e4;
    if (protocolSplit > 0)
      SafeTransferLib.safeTransferETH(protocolWallet, protocolSplit);
    // Governor Split
    uint256 governorSplit = address(this).balance;
    if (governorSplit > 0)
      SafeTransferLib.safeTransferETH(governorWallet, governorSplit);
    emit ProtocolPayout(protocolSplit, governorSplit);
  }

  /// @notice Used to withdraw any ERC20 tokens that have been sent to contract
  /// @dev No ERC20 tokens should be sent but this method prevents tokens being locked in contract
  /// @param _tokenAddress Address of token to be withdrawn from contract
  function withdrawToken(address _tokenAddress) external onlyOwner {
    uint256 tokenBalance = ERC20(_tokenAddress).balanceOf(address(this));
    if (tokenBalance <= 0)
      revert NoBalance();
    ERC20(_tokenAddress).safeTransfer(msg.sender, tokenBalance);
  }

  receive() external payable {}
  fallback() external payable {}
}
