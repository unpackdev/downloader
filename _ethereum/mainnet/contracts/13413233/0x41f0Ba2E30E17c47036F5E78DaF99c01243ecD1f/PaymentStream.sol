//SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./IPaymentStream.sol";
import "./IPaymentStreamFactory.sol";

contract PaymentStream is AccessControl, IPaymentStream {
  using SafeERC20 for IERC20;

  address public payer;
  address public payee;
  address public token;
  address public fundingAddress;

  uint256 public usdAmount;
  uint256 public startTime;
  uint256 public secs;
  uint256 public usdPerSec;
  uint256 public claimed;

  bool public paused;

  IPaymentStreamFactory public immutable factory;

  bytes32 private constant ADMIN_ROLE = keccak256(abi.encodePacked("admin"));
  bytes32 private constant PAUSABLE_ROLE =
    keccak256(abi.encodePacked("pausable"));

  modifier onlyPayer() {
    require(_msgSender() == payer, "not-stream-owner");
    _;
  }

  modifier onlyPayerOrDelegated() {
    require(
      _msgSender() == payer || hasRole(PAUSABLE_ROLE, _msgSender()),
      "not-stream-owner-or-delegated"
    );
    _;
  }

  modifier onlyPayee() {
    require(_msgSender() == payee, "not-payee");
    _;
  }

  /**
   * @notice Creates a new payment stream
   * @dev Payer is set as admin of "PAUSABLE_ROLE", so he can grant and revoke the "pausable" role later on
   * @param _payer Owner of the stream
   * @param _payee address that receives the payment stream
   * @param _usdAmount uint256 total amount in USD (scaled to 18 decimals) to be distributed until endTime
   * @param _token address of the ERC20 token that payee receives as payment
   * @param _fundingAddress address used to withdraw the drip
   * @param _endTime timestamp that sets drip distribution end
   */
  constructor(
    address _payer,
    address _payee,
    uint256 _usdAmount,
    address _token,
    address _fundingAddress,
    uint256 _endTime
  ) {
    factory = IPaymentStreamFactory(_msgSender());

    require(_endTime > block.timestamp, "invalid-end-time");
    require(_payee != _fundingAddress, "payee-is-funding-address");
    require(
      _payee != address(0) && _fundingAddress != address(0),
      "payee-or-funding-address-is-0"
    );

    require(_usdAmount > 0, "usd-amount-is-0");

    payee = _payee;
    usdAmount = _usdAmount;
    token = _token;
    fundingAddress = _fundingAddress;
    payer = _payer;
    startTime = block.timestamp;
    secs = _endTime - block.timestamp;
    usdPerSec = _usdAmount / secs;

    _setupRole(ADMIN_ROLE, _payer);
    _setRoleAdmin(PAUSABLE_ROLE, ADMIN_ROLE);
  }

  /**
   * @notice Delegates pausable capability to new delegate
   * @dev Only RoleAdmin (Payer) can delegate this capability, tx will revert otherwise
   * @param _delegate address that receives the "PAUSABLE_ROLE"
   */
  function delegatePausable(address _delegate) external override {
    require(_delegate != address(0), "invalid-delegate");

    grantRole(PAUSABLE_ROLE, _delegate);
  }

  /**
   * @notice Revokes pausable capability of a delegate
   * @dev Only RoleAdmin (Payer) can revoke this capability, tx will revert otherwise
   * @param _delegate address that has its "PAUSABLE_ROLE" revoked
   */
  function revokePausable(address _delegate) external override {
    revokeRole(PAUSABLE_ROLE, _delegate);
  }

  /**
   * @notice Pauses a stream if caller is either the payer or a delegate of PAUSABLE_ROLE
   */
  function pauseStream() external override onlyPayerOrDelegated {
    paused = true;
    emit StreamPaused();
  }

  /**
   * @notice Unpauses a stream if caller is either the payer or a delegate of PAUSABLE_ROLE
   */
  function unpauseStream() external override onlyPayerOrDelegated {
    paused = false;
    emit StreamUnpaused();
  }

  /**
   * @notice If caller is the payer of the stream it sets a new address as receiver of the stream
   * @param _newPayee address of new payee
   */
  function updatePayee(address _newPayee) external override onlyPayer {
    require(_newPayee != address(0), "invalid-new-payee");
    require(_newPayee != payee, "same-new-payee");

    _claim();

    emit PayeeUpdated(payee, _newPayee);
    payee = _newPayee;
  }

  /**
   * @notice If caller is the payer of the stream it sets a new address used to withdraw the drip
   * @param _newFundingAddress new address used to withdraw the drip
   */
  function updateFundingAddress(address _newFundingAddress)
    external
    override
    onlyPayer
  {
    require(_newFundingAddress != address(0), "invalid-new-funding-address");
    require(_newFundingAddress != fundingAddress, "same-new-funding-address");

    emit FundingAddressUpdated(fundingAddress, _newFundingAddress);

    fundingAddress = _newFundingAddress;
  }

  /**
   * @notice If caller is the payer it increases or decreases a stream funding rate
   * @dev Any unclaimed drip amount remaining will be claimed on behalf of payee
   * @param _usdAmount uint256 total amount in USD (scaled to 18 decimals) to be distributed until endTime
   * @param _endTime timestamp that sets drip distribution end
   */
  function updateFundingRate(uint256 _usdAmount, uint256 _endTime)
    external
    override
    onlyPayer
  {
    require(_endTime > block.timestamp, "invalid-end-time");

    _claim();

    usdAmount = _usdAmount;
    startTime = block.timestamp;
    secs = _endTime - block.timestamp;
    usdPerSec = _usdAmount / secs;
    claimed = 0;

    emit StreamUpdated(_usdAmount, _endTime);
  }

  /**
   * @notice If caller is the payee of the stream it receives the accrued drip amount
   */
  function claim() external override onlyPayee {
    require(!paused, "stream-is-paused");
    _claim();
  }

  function claimable() external view override returns (uint256) {
    return _claimable();
  }

  /**
   * @notice Helper function, gets the accrued drip of given stream converted into target token amount
   * @return uint256 amount in target token
   */
  function claimableToken() external view override returns (uint256) {
    return factory.usdToTokenAmount(token, _claimable());
  }

  function _claim() internal {
    factory.updateOracles(token);

    uint256 _accumulated = _claimable();

    if (_accumulated == 0) return;

    uint256 _amount = factory.usdToTokenAmount(token, _accumulated);

    // if we get _amount = 0 it means payee called this function
    // before the oracles had time to update for the first time
    require(_amount > 0, "oracle-update-error");

    claimed += _accumulated;

    IERC20(token).safeTransferFrom(fundingAddress, payee, _amount);

    emit Claimed(_accumulated, _amount);
  }

  /**
   * @notice gets the accrued drip of given stream in USD
   * @return uint256 USD amount (scaled to 18 decimals)
   */
  function _claimable() internal view returns (uint256) {
    uint256 _elapsed = block.timestamp - startTime;

    if (_elapsed > secs) {
      return usdAmount - claimed; // no more drips to avoid floating point dust
    }

    return (usdPerSec * _elapsed) - claimed;
  }
}
