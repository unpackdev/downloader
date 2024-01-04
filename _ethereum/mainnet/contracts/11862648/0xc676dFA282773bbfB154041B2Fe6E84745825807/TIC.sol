// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./ITIC.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./FixedPoint.sol";
import "./HitchensUnorderedKeySet.sol";
import "./TICHelper.sol";
import "./IERC20.sol";
import "./IStandardERC20.sol";

import "./IFinder.sol";
import "./IDerivative.sol";

contract SynthereumTIC is
  AccessControl,
  SynthereumTICInterface,
  ReentrancyGuard
{
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  bytes32 public constant VALIDATOR_ROLE = keccak256('Validator');

  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  using SynthereumTICHelper for Storage;

  struct Storage {
    ISynthereumFinder finder;
    uint8 version;
    IDerivative derivative;
    FixedPoint.Unsigned startingCollateralization;
    address liquidityProvider;
    address validator;
    IERC20 collateralToken;
    Fee fee;
    uint256 totalFeeProportions;
    mapping(bytes32 => MintRequest) mintRequests;
    HitchensUnorderedKeySetLib.Set mintRequestSet;
    mapping(bytes32 => ExchangeRequest) exchangeRequests;
    HitchensUnorderedKeySetLib.Set exchangeRequestSet;
    mapping(bytes32 => RedeemRequest) redeemRequests;
    HitchensUnorderedKeySetLib.Set redeemRequestSet;
  }

  event MintRequested(
    bytes32 mintID,
    uint256 timestamp,
    address indexed sender,
    uint256 collateralAmount,
    uint256 numTokens
  );
  event MintApproved(bytes32 mintID, address indexed sender);
  event MintRejected(bytes32 mintID, address indexed sender);

  event ExchangeRequested(
    bytes32 exchangeID,
    uint256 timestamp,
    address indexed sender,
    address destTIC,
    uint256 numTokens,
    uint256 destNumTokens
  );
  event ExchangeApproved(bytes32 exchangeID, address indexed sender);
  event ExchangeRejected(bytes32 exchangeID, address indexed sender);

  event RedeemRequested(
    bytes32 redeemID,
    uint256 timestamp,
    address indexed sender,
    uint256 collateralAmount,
    uint256 numTokens
  );
  event RedeemApproved(bytes32 redeemID, address indexed sender);
  event RedeemRejected(bytes32 redeemID, address indexed sender);
  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  Storage private ticStorage;

  constructor(
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    Roles memory _roles,
    uint256 _startingCollateralization,
    Fee memory _fee
  ) public nonReentrant {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, _roles.liquidityProvider);
    _setupRole(VALIDATOR_ROLE, _roles.validator);
    ticStorage.initialize(
      _derivative,
      _finder,
      _version,
      _roles.liquidityProvider,
      _roles.validator,
      FixedPoint.Unsigned(_startingCollateralization)
    );
    _setFeePercentage(_fee.feePercentage.rawValue);
    _setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender),
      'Sender must be the liquidity provider'
    );
    _;
  }

  modifier onlyValidator() {
    require(
      hasRole(VALIDATOR_ROLE, msg.sender),
      'Sender must be the validator'
    );
    _;
  }

  function mintRequest(uint256 collateralAmount, uint256 numTokens)
    external
    override
    nonReentrant
  {
    bytes32 mintID =
      ticStorage.mintRequest(
        FixedPoint.Unsigned(collateralAmount),
        FixedPoint.Unsigned(numTokens)
      );

    emit MintRequested(mintID, now, msg.sender, collateralAmount, numTokens);
  }

  function approveMint(bytes32 mintID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.mintRequests[mintID].sender;

    ticStorage.approveMint(mintID);

    emit MintApproved(mintID, sender);
  }

  function rejectMint(bytes32 mintID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.mintRequests[mintID].sender;

    ticStorage.rejectMint(mintID);

    emit MintRejected(mintID, sender);
  }

  function deposit(uint256 collateralAmount)
    external
    override
    nonReentrant
    onlyLiquidityProvider
  {
    ticStorage.deposit(FixedPoint.Unsigned(collateralAmount));
  }

  function withdraw(uint256 collateralAmount)
    external
    override
    nonReentrant
    onlyLiquidityProvider
  {
    ticStorage.withdraw(FixedPoint.Unsigned(collateralAmount));
  }

  function exchangeMint(uint256 collateralAmount, uint256 numTokens)
    external
    override
    nonReentrant
  {
    ticStorage.exchangeMint(
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens)
    );
  }

  function depositIntoDerivative(uint256 collateralAmount)
    external
    override
    nonReentrant
    onlyLiquidityProvider
  {
    ticStorage.depositIntoDerivative(FixedPoint.Unsigned(collateralAmount));
  }

  function withdrawRequest(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    ticStorage.withdrawRequest(FixedPoint.Unsigned(collateralAmount));
  }

  function withdrawPassedRequest()
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    ticStorage.withdrawPassedRequest();
  }

  function redeemRequest(uint256 collateralAmount, uint256 numTokens)
    external
    override
    nonReentrant
  {
    bytes32 redeemID =
      ticStorage.redeemRequest(
        FixedPoint.Unsigned(collateralAmount),
        FixedPoint.Unsigned(numTokens)
      );

    emit RedeemRequested(
      redeemID,
      now,
      msg.sender,
      collateralAmount,
      numTokens
    );
  }

  function approveRedeem(bytes32 redeemID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.redeemRequests[redeemID].sender;

    ticStorage.approveRedeem(redeemID);

    emit RedeemApproved(redeemID, sender);
  }

  function rejectRedeem(bytes32 redeemID)
    external
    override
    nonReentrant
    onlyValidator
  {
    address sender = ticStorage.redeemRequests[redeemID].sender;

    ticStorage.rejectRedeem(redeemID);

    emit RedeemRejected(redeemID, sender);
  }

  function emergencyShutdown() external override onlyMaintainer nonReentrant {
    ticStorage.emergencyShutdown();
  }

  function settleEmergencyShutdown() external override nonReentrant {
    ticStorage.settleEmergencyShutdown();
  }

  function exchangeRequest(
    SynthereumTICInterface destTIC,
    uint256 numTokens,
    uint256 collateralAmount,
    uint256 destNumTokens
  ) external override nonReentrant {
    bytes32 exchangeID =
      ticStorage.exchangeRequest(
        destTIC,
        FixedPoint.Unsigned(numTokens),
        FixedPoint.Unsigned(collateralAmount),
        FixedPoint.Unsigned(destNumTokens)
      );

    emit ExchangeRequested(
      exchangeID,
      now,
      msg.sender,
      address(destTIC),
      numTokens,
      destNumTokens
    );
  }

  function approveExchange(bytes32 exchangeID)
    external
    override
    onlyValidator
    nonReentrant
  {
    address sender = ticStorage.exchangeRequests[exchangeID].sender;

    ticStorage.approveExchange(exchangeID);

    emit ExchangeApproved(exchangeID, sender);
  }

  function rejectExchange(bytes32 exchangeID)
    external
    override
    onlyValidator
    nonReentrant
  {
    address sender = ticStorage.exchangeRequests[exchangeID].sender;

    ticStorage.rejectExchange(exchangeID);

    emit ExchangeRejected(exchangeID, sender);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = ticStorage.finder;
  }

  function version() external view override returns (uint8 poolVersion) {
    poolVersion = ticStorage.version;
  }

  function derivative() external view override returns (IDerivative) {
    return ticStorage.derivative;
  }

  function collateralToken() external view override returns (IERC20) {
    return ticStorage.collateralToken;
  }

  function syntheticToken() external view override returns (IERC20) {
    return ticStorage.derivative.tokenCurrency();
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(ticStorage.derivative.tokenCurrency()))
      .symbol();
  }

  function calculateFee(uint256 collateralAmount)
    external
    view
    override
    returns (uint256)
  {
    return
      FixedPoint
        .Unsigned(collateralAmount)
        .mul(ticStorage.fee.feePercentage)
        .rawValue;
  }

  function getMintRequests()
    external
    view
    override
    returns (MintRequest[] memory)
  {
    return ticStorage.getMintRequests();
  }

  function getRedeemRequests()
    external
    view
    override
    returns (RedeemRequest[] memory)
  {
    return ticStorage.getRedeemRequests();
  }

  function getExchangeRequests()
    external
    view
    override
    returns (ExchangeRequest[] memory)
  {
    return ticStorage.getExchangeRequests();
  }

  function setFee(Fee memory _fee)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    _setFeePercentage(_fee.feePercentage.rawValue);
    _setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  function setFeePercentage(uint256 _feePercentage)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    _setFeePercentage(_feePercentage);
  }

  function setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) external override nonReentrant onlyMaintainer {
    _setFeeRecipients(_feeRecipients, _feeProportions);
  }

  function _setFeePercentage(uint256 _feePercentage) private {
    ticStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
    emit SetFeePercentage(_feePercentage);
  }

  function _setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) private {
    ticStorage.setFeeRecipients(_feeRecipients, _feeProportions);
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }
}
