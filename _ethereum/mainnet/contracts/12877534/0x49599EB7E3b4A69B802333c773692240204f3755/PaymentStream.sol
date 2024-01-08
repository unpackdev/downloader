//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./IPaymentStream.sol";
import "./ISwapManager.sol";

contract PaymentStream is Ownable, AccessControl, IPaymentStream {
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;

  uint256 private constant TWAP_PERIOD = 1 hours;

  uint8 private constant MAX_PATH = 5;

  struct TokenSupport {
    address[] path;
    uint256 dex;
  }

  Counters.Counter private totalStreams;
  ISwapManager private swapManager;

  modifier onlyPayer(uint256 streamId) {
    require(_msgSender() == streams[streamId].payer, "Not stream owner");
    _;
  }

  modifier onlyPayerOrDelegated(uint256 streamId) {
    require(
      _msgSender() == streams[streamId].payer ||
        hasRole(keccak256(abi.encodePacked(streamId)), _msgSender()),
      "Not stream owner/delegated"
    );
    _;
  }

  modifier onlyPayee(uint256 streamId) {
    require(_msgSender() == streams[streamId].payee, "Not payee");
    _;
  }

  mapping(uint256 => Stream) public streams;
  mapping(address => TokenSupport) public supportedTokens; // token address => TokenSupport
  mapping(address => address) public fundingOwnership; // fundingAddress => payer

  constructor(address _swapManager) {
    // Start the counts at 1
    // the 0th stream is available to all
    totalStreams.increment();

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
   * @return newly created streamId
   */

  function createStream(
    address _payee,
    uint256 _usdAmount,
    address _token,
    address _fundingAddress,
    uint256 _endTime
  ) external override returns (uint256) {
    require(_endTime > block.timestamp, "End time is in the past");
    require(_payee != _fundingAddress, "payee == fundingAddress");
    require(
      _payee != address(0) && _fundingAddress != address(0),
      "invalid payee or fundingAddress"
    );

    // _fundingAddress shouldn't be in use by any other Payer
    // or Payer has to be the owner already
    if (fundingOwnership[_fundingAddress] == address(0))
      fundingOwnership[_fundingAddress] = _msgSender();

    require(
      fundingOwnership[_fundingAddress] == _msgSender(),
      "Not funding owner"
    );

    require(_usdAmount > 0, "usdAmount == 0");
    require(supportedTokens[_token].path.length > 1, "Token not supported");

    Stream memory _stream;

    _stream.payee = _payee;
    _stream.usdAmount = _usdAmount;
    _stream.token = _token;
    _stream.fundingAddress = _fundingAddress;
    _stream.payer = _msgSender();
    _stream.paused = false;
    _stream.startTime = block.timestamp;
    _stream.secs = _endTime - block.timestamp;
    _stream.usdPerSec = _usdAmount / _stream.secs;
    _stream.claimed = 0;

    uint256 _streamId = totalStreams.current();

    streams[_streamId] = _stream;

    bytes32 _adminRole = keccak256(abi.encodePacked("admin", _streamId));
    bytes32 _pausableRole = keccak256(abi.encodePacked(_streamId));

    _setupRole(_adminRole, _msgSender());
    _setRoleAdmin(_pausableRole, _adminRole);

    totalStreams.increment();

    emit StreamCreated(_streamId, _msgSender(), _payee, _usdAmount);

    return _streamId;
  }

  /**
   * @notice Delegates pausable capability to new delegate
   * @dev Only RoleAdmin (Payer) can delegate this capability, tx will revert otherwise
   * @param _streamId id of a stream that Payer owns
   * @param _delegate address that receives the "pausableRole"
   */
  function delegatePausable(uint256 _streamId, address _delegate)
    external
    override
  {
    require(_delegate != address(0), "Invalid delegate");

    grantRole(keccak256(abi.encodePacked(_streamId)), _delegate);
  }

  /**
   * @notice Revokes pausable capability of a delegate
   * @dev Only RoleAdmin (Payer) can revoke this capability, tx will revert otherwise
   * @param _streamId id of a stream that Payer owns
   * @param _delegate address that has its "pausableRole" revoked
   */
  function revokePausable(uint256 _streamId, address _delegate)
    external
    override
  {
    revokeRole(keccak256(abi.encodePacked(_streamId)), _delegate);
  }

  /**
   * @notice Pauses a stream if caller is either the payer or a delegate of pausableRole
   * @param _streamId id of a stream
   */
  function pauseStream(uint256 _streamId)
    external
    override
    onlyPayerOrDelegated(_streamId)
  {
    streams[_streamId].paused = true;
    emit StreamPaused(_streamId);
  }

  /**
   * @notice Unpauses a stream if caller is either the payer or a delegate of pausableRole
   * @param _streamId id of a stream
   */
  function unpauseStream(uint256 _streamId)
    external
    override
    onlyPayerOrDelegated(_streamId)
  {
    streams[_streamId].paused = false;
    emit StreamUnpaused(_streamId);
  }

  /**
   * @notice If caller is the payer of the stream it sets a new address as receiver of the stream
   * @param _streamId id of a stream
   * @param _newPayee address of new payee
   */
  function updatePayee(uint256 _streamId, address _newPayee)
    external
    override
    onlyPayer(_streamId)
  {
    require(_newPayee != address(0), "newPayee invalid");
    streams[_streamId].payee = _newPayee;
    emit PayeeUpdated(_streamId, _newPayee);
  }

  /**
   * @notice If caller is the payer of the stream it sets a new address used to withdraw the drip
   * @param _streamId id of a stream
   * @param _newFundingAddress new address used to withdraw the drip
   */
  function updateFundingAddress(uint256 _streamId, address _newFundingAddress)
    external
    override
    onlyPayer(_streamId)
  {
    require(_newFundingAddress != address(0), "newFundingAddress invalid");

    // _newFundingAddress shouldn't be in use by any other Payer
    // or Payer has to be the owner already
    if (fundingOwnership[_newFundingAddress] == address(0))
      fundingOwnership[_newFundingAddress] = _msgSender();

    require(
      fundingOwnership[_newFundingAddress] == _msgSender(),
      "Not funding owner"
    );
    emit FundingAddressUpdated(
      _streamId,
      streams[_streamId].fundingAddress,
      _newFundingAddress
    );
    streams[_streamId].fundingAddress = _newFundingAddress;
  }

  /**
   * @notice If caller is the payer it increases or decreases a stream funding rate
   * @dev Any unclaimed drip amount remaining will be claimed on behalf of payee
   * @param _streamId id of a stream
   * @param _usdAmount uint256 total amount in USD (scaled to 18 decimals) to be distributed until endTime
   * @param _endTime timestamp that sets drip distribution end
   */
  function updateFundingRate(
    uint256 _streamId,
    uint256 _usdAmount,
    uint256 _endTime
  ) external override onlyPayer(_streamId) {
    Stream memory _stream = streams[_streamId];

    require(_endTime > block.timestamp, "End time is in the past");

    uint256 _accumulated = _claimable(_streamId);
    uint256 _amount = _usdToTokenAmount(_stream.token, _accumulated);

    // if we get _amount = 0 it means Payer called this function
    // before the oracles had time to update for the first time
    require(_amount > 0, "Oracle update error");

    _stream.usdAmount = _usdAmount;
    _stream.startTime = block.timestamp;
    _stream.secs = _endTime - block.timestamp;
    _stream.usdPerSec = _usdAmount / _stream.secs;
    _stream.claimed = 0;

    streams[_streamId] = _stream;

    IERC20(_stream.token).safeTransferFrom(
      _stream.fundingAddress,
      _stream.payee,
      _amount
    );

    emit Claimed(_streamId, _accumulated, _amount);
    emit StreamUpdated(_streamId, _usdAmount, _endTime);
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

    require(_len > 1, "Path too short");
    require(_len <= MAX_PATH, "Path too long");

    _len--;

    for (uint8 i = 0; i < _len; i++) {
      swapManager.createOrUpdateOracle(
        _path[i],
        _path[i + 1],
        TWAP_PERIOD,
        _dex
      );
    }

    _tokenSupport.path = _path;

    supportedTokens[_tokenAddress] = _tokenSupport;

    emit TokenAdded(_tokenAddress);
  }

  /**
   * @notice If caller is the payee of streamId it receives the accrued drip amount
   * @param _streamId id of a stream
   */
  function claim(uint256 _streamId) external override onlyPayee(_streamId) {
    Stream memory _stream = streams[_streamId];

    require(!_stream.paused, "Stream is paused");

    _updateOracles(_stream.token);

    uint256 _accumulated = _claimable(_streamId);

    if (_accumulated == 0) return;

    uint256 _amount = _usdToTokenAmount(_stream.token, _accumulated);

    // if we get _amount = 0 it means payee called this function
    // before the oracles had time to update for the first time
    require(_amount > 0, "Oracle update error");

    _stream.claimed += _accumulated;

    streams[_streamId] = _stream;

    IERC20(_stream.token).safeTransferFrom(
      _stream.fundingAddress,
      _stream.payee,
      _amount
    );

    emit Claimed(_streamId, _accumulated, _amount);
  }

  /**
   * @notice Updates Swap Manager contract address
   * @dev Only contract owner can change swapManager
   * @param _newAddress address of new Swap Manager instance
   */
  function updateSwapManager(address _newAddress) external override onlyOwner {
    require(_newAddress != address(0), "Invalid SwapManager address");

    emit SwapManagerUpdated(address(swapManager), _newAddress);
    swapManager = ISwapManager(_newAddress);
  }

  /**
   * @notice Helper function, gets stream information
   * @param _streamId id of a stream
   * @return Stream struct
   */
  function getStream(uint256 _streamId) external view returns (Stream memory) {
    return streams[_streamId];
  }

  /**
   * @notice Helper function, gets no. of total streams, useful for looping through streams using getStream
   * @return uint256
   */
  function getStreamsCount() external view override returns (uint256) {
    return totalStreams.current();
  }

  function claimable(uint256 _streamId)
    external
    view
    override
    returns (uint256)
  {
    return _claimable(_streamId);
  }

  /**
   * @notice Helper function, gets the accrued drip of given stream converted into target token amount
   * @param _streamId id of a stream
   * @return uint256 amount in target token
   */
  function claimableToken(uint256 _streamId)
    external
    view
    override
    returns (uint256)
  {
    return _usdToTokenAmount(streams[_streamId].token, _claimable(_streamId));
  }

  /**
   * @notice gets the accrued drip of given stream in USD
   * @param _streamId id of a stream
   * @return uint256 USD amount (scaled to 18 decimals)
   */
  function _claimable(uint256 _streamId) internal view returns (uint256) {
    Stream memory _stream = streams[_streamId];

    uint256 _elapsed = block.timestamp - _stream.startTime;

    if (_elapsed > _stream.secs) {
      return _stream.usdAmount - _stream.claimed; // no more drips to avoid floating point dust
    }

    return (_stream.usdPerSec * _elapsed) - _stream.claimed;
  }

  /**
   * @notice Converts given amount in usd to target token amount using oracle
   * @param _token address of target token
   * @param _amount amount in USD (scaled to 18 decimals)
   * @return uint256 target token amount
   */
  function _usdToTokenAmount(address _token, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    TokenSupport memory _tokenSupport = supportedTokens[_token];

    // _amount is 18 decimals
    // some stablecoins like USDC has 6 decimals, so we scale the amount accordingly

    _amount = _amount / 10**(18 - ERC20(_tokenSupport.path[0]).decimals());

    uint256 lastPrice;

    uint256 _len = _tokenSupport.path.length - 1;

    for (uint8 i = 0; i < _len; i++) {
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

    return lastPrice;
  }

  /**
   * @notice Updates price oracles for a given token
   * @param _token address of target token
   */
  function _updateOracles(address _token) internal {
    TokenSupport memory _tokenSupport = supportedTokens[_token];

    uint256 _len = _tokenSupport.path.length - 1;

    address[] memory _oracles = new address[](_len);

    for (uint8 i = 0; i < _len; i++) {
      _oracles[i] = swapManager.getOracle(
        _tokenSupport.path[i],
        _tokenSupport.path[i + 1],
        TWAP_PERIOD,
        _tokenSupport.dex
      );
    }

    swapManager.updateOracles(_oracles);
  }
}
