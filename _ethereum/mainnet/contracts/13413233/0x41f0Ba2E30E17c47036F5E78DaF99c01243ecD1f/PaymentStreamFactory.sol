//SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./IPaymentStreamFactory.sol";
import "./ISwapManager.sol";
import "./PaymentStream.sol";

contract PaymentStreamFactory is IPaymentStreamFactory, Ownable {
  address[] private allStreams;
  mapping(address => bool) private isOurs;

  uint256 private constant TWAP_PERIOD = 1 hours;

  uint8 private constant MAX_PATH = 5;

  ISwapManager public swapManager;

  mapping(address => TokenSupport) public supportedTokens; // token address => TokenSupport

  constructor(address _swapManager) {
    swapManager = ISwapManager(_swapManager);
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
    require(supportedTokens[_token].path.length > 1, "token-not-supported");

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
   * @notice Updates Swap Manager contract address
   * @dev Only contract owner can change swapManager
   * @param _newAddress address of new Swap Manager instance
   */
  function updateSwapManager(address _newAddress) external override onlyOwner {
    require(_newAddress != address(0), "invalid-swap-manager-address");
    require(_newAddress != address(swapManager), "same-swap-manager-address");

    emit SwapManagerUpdated(address(swapManager), _newAddress);
    swapManager = ISwapManager(_newAddress);
  }

  /**
   * @notice If caller is contract owner it adds (or updates) Oracle price feed for given token
   * @param _tokenAddress address of the ERC20 token to add support to
   * @param _dex ID for choosing the DEX where prices will be retrieved (0 = Uniswap v2, 1 = Sushiswap)
   * @param _path path of tokens to reach a _tokenAddress from a USD stablecoin (e.g: [ USDC, WETH, VSP ])
   */
  function addToken(
    address _tokenAddress,
    uint8 _dex,
    address[] memory _path
  ) external override onlyOwner {
    TokenSupport memory _tokenSupport;

    uint256 _len = _path.length;

    require(_len > 1 && _len <= MAX_PATH, "invalid-path-length");

    _len--;

    for (uint256 i = 0; i < _len; i++) {
      swapManager.createOrUpdateOracle(
        _path[i],
        _path[i + 1],
        TWAP_PERIOD,
        _dex
      );
    }

    _tokenSupport.path = _path;
    _tokenSupport.dex = _dex;

    supportedTokens[_tokenAddress] = _tokenSupport;

    emit TokenAdded(_tokenAddress);
  }

  /**
   * @notice Converts given amount in usd to target token amount using oracle
   * @param _token address of target token
   * @param _amount amount in USD (scaled to 18 decimals)
   * @return lastPrice target token amount
   */
  function usdToTokenAmount(address _token, uint256 _amount)
    external
    view
    override
    returns (uint256 lastPrice)
  {
    TokenSupport memory _tokenSupport = supportedTokens[_token];

    // _amount is 18 decimals
    // some stablecoins like USDC has 6 decimals, so we scale the amount accordingly

    _amount =
      _amount /
      10**(18 - IERC20Metadata(_tokenSupport.path[0]).decimals());
    uint256 _len = _tokenSupport.path.length - 1;

    for (uint256 i = 0; i < _len; i++) {
      (uint256 amountOut, ) =
        swapManager.consultForFree(
          _tokenSupport.path[i],
          _tokenSupport.path[i + 1],
          (i == 0) ? _amount : lastPrice,
          TWAP_PERIOD,
          _tokenSupport.dex
        );
      lastPrice = amountOut;
    }
  }

  /**
   * @notice Updates price oracles for a given token
   * @param _token address of target token
   */
  function updateOracles(address _token) external override {
    TokenSupport memory _tokenSupport = supportedTokens[_token];

    uint256 _len = _tokenSupport.path.length - 1;

    address[] memory _oracles = new address[](_len);

    for (uint256 i = 0; i < _len; i++) {
      _oracles[i] = swapManager.getOracle(
        _tokenSupport.path[i],
        _tokenSupport.path[i + 1],
        TWAP_PERIOD,
        _tokenSupport.dex
      );
    }

    swapManager.updateOracles(_oracles);
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
    require(_idx < allStreams.length, "index-exceeds-list-length");
    return allStreams[_idx];
  }
}
