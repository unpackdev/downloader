// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IStandardERC20.sol";
import "./IDerivative.sol";
import "./IPool.sol";
import "./IPoolStorage.sol";
import "./IFinder.sol";
import "./IDeployer.sol";
import "./Constants.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";
import "./FixedPoint.sol";
import "./PoolLib.sol";
import "./Lockable.sol";
import "./AccessControl.sol";

contract SynthereumPool is
  AccessControl,
  ISynthereumPoolStorage,
  ISynthereumPool,
  Lockable
{
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolLib for Storage;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  bytes32 public constant VALIDATOR_ROLE = keccak256('Validator');

  bytes32 public immutable MINT_TYPEHASH;

  bytes32 public immutable REDEEM_TYPEHASH;

  bytes32 public immutable EXCHANGE_TYPEHASH;

  bytes32 public DOMAIN_SEPARATOR;

  Storage private poolStorage;

  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

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

  constructor(
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    Roles memory _roles,
    bool _isContractAllowed,
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
    poolStorage.initialize(
      _version,
      _finder,
      _derivative,
      FixedPoint.Unsigned(_startingCollateralization),
      _isContractAllowed
    );
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        ),
        keccak256(bytes('Synthereum Pool')),
        keccak256(bytes(Strings.toString(_version))),
        getChainID(),
        address(this)
      )
    );
    MINT_TYPEHASH = keccak256(
      'MintParameters(address sender,address derivativeAddr,uint256 collateralAmount,uint256 numTokens,uint256 feePercentage,uint256 nonce,uint256 expiration)'
    );
    REDEEM_TYPEHASH = keccak256(
      'RedeemParameters(address sender,address derivativeAddr,uint256 collateralAmount,uint256 numTokens,uint256 feePercentage,uint256 nonce,uint256 expiration)'
    );
    EXCHANGE_TYPEHASH = keccak256(
      'ExchangeParameters(address sender,address derivativeAddr,address destPoolAddr,address destDerivativeAddr,uint256 numTokens,uint256 collateralAmount,uint256 destNumTokens,uint256 feePercentage,uint256 nonce,uint256 expiration)'
    );
  }

  function addDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.addDerivative(derivative);
  }

  function removeDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.removeDerivative(derivative);
  }

  function mint(MintParameters memory mintMetaTx, Signature memory signature)
    external
    override
    nonReentrant
    returns (uint256 feePaid)
  {
    feePaid = poolStorage.mint(
      mintMetaTx,
      SignatureVerificationParams(
        DOMAIN_SEPARATOR,
        MINT_TYPEHASH,
        signature,
        VALIDATOR_ROLE
      )
    );
  }

  function redeem(
    RedeemParameters memory redeemMetaTx,
    Signature memory signature
  ) external override nonReentrant returns (uint256 feePaid) {
    feePaid = poolStorage.redeem(
      redeemMetaTx,
      SignatureVerificationParams(
        DOMAIN_SEPARATOR,
        REDEEM_TYPEHASH,
        signature,
        VALIDATOR_ROLE
      )
    );
  }

  function exchange(
    ExchangeParameters memory exchangeMetaTx,
    Signature memory signature
  ) external override nonReentrant returns (uint256 feePaid) {
    feePaid = poolStorage.exchange(
      exchangeMetaTx,
      SignatureVerificationParams(
        DOMAIN_SEPARATOR,
        EXCHANGE_TYPEHASH,
        signature,
        VALIDATOR_ROLE
      )
    );
  }

  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external override nonReentrant {
    poolStorage.exchangeMint(
      srcDerivative,
      derivative,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens)
    );
  }

  function withdrawFromPool(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.withdrawFromPool(FixedPoint.Unsigned(collateralAmount));
  }

  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
    poolStorage.depositIntoDerivative(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.slowWithdrawRequest(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.slowWithdrawPassedRequest(derivative);
  }

  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.fastWithdraw(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  function emergencyShutdown(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.emergencyShutdown(derivative);
  }

  function settleEmergencyShutdown(IDerivative derivative)
    external
    override
    nonReentrant
    returns (uint256 amountSettled)
  {
    amountSettled = poolStorage.settleEmergencyShutdown(
      derivative,
      LIQUIDITY_PROVIDER_ROLE
    );
  }

  function setFeePercentage(uint256 _feePercentage)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
  }

  function setFeeRecipients(
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external override onlyMaintainer nonReentrant {
    poolStorage.setFeeRecipients(_feeRecipients, _feeProportions);
  }

  function setStartingCollateralization(uint256 startingCollateralRatio)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setStartingCollateralization(
      FixedPoint.Unsigned(startingCollateralRatio)
    );
  }

  function addRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInDerivative(derivative, derivativeRole, addressToAdd);
  }

  function renounceRoleInDerivative(
    IDerivative derivative,
    DerivativeRoles derivativeRole
  ) external override onlyMaintainer nonReentrant {
    poolStorage.renounceRoleInDerivative(derivative, derivativeRole);
  }

  function addRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external override onlyMaintainer nonReentrant {
    poolStorage.addRoleInSynthToken(derivative, synthTokenRole, addressToAdd);
  }

  function renounceRoleInSynthToken(
    IDerivative derivative,
    SynthTokenRoles synthTokenRole
  ) external override onlyMaintainer nonReentrant {
    poolStorage.renounceRoleInSynthToken(derivative, synthTokenRole);
  }

  function setIsContractAllowed(bool isContractAllowed)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setIsContractAllowed(isContractAllowed);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = poolStorage.finder;
  }

  function version() external view override returns (uint8 poolVersion) {
    poolVersion = poolStorage.version;
  }

  function collateralToken()
    external
    view
    override
    returns (IERC20 collateralCurrency)
  {
    collateralCurrency = poolStorage.collateralToken;
  }

  function syntheticToken()
    external
    view
    override
    returns (IERC20 syntheticCurrency)
  {
    syntheticCurrency = poolStorage.syntheticToken;
  }

  function getAllDerivatives()
    external
    view
    override
    returns (IDerivative[] memory)
  {
    EnumerableSet.AddressSet storage derivativesSet = poolStorage.derivatives;
    uint256 numberOfDerivatives = derivativesSet.length();
    IDerivative[] memory derivatives = new IDerivative[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      derivatives[j] = (IDerivative(derivativesSet.at(j)));
    }
    return derivatives;
  }

  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    override
    returns (bool isAdmitted)
  {
    isAdmitted = poolStorage.derivatives.contains(address(derivative));
  }

  function getStartingCollateralization()
    external
    view
    override
    returns (uint256 startingCollateralRatio)
  {
    startingCollateralRatio = poolStorage.startingCollateralization.rawValue;
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(poolStorage.syntheticToken)).symbol();
  }

  function isContractAllowed() external view override returns (bool isAllowed) {
    isAllowed = poolStorage.isContractAllowed;
  }

  function getFeeInfo() external view override returns (Fee memory fee) {
    fee = poolStorage.fee;
  }

  function getUserNonce(address user)
    external
    view
    override
    returns (uint256 nonce)
  {
    nonce = poolStorage.nonces[user];
  }

  function calculateFee(uint256 collateralAmount)
    external
    view
    override
    returns (uint256 fee)
  {
    fee = FixedPoint
      .Unsigned(collateralAmount)
      .mul(poolStorage.fee.feePercentage)
      .rawValue;
  }

  function setFee(Fee memory _fee) public override onlyMaintainer nonReentrant {
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  function getChainID() private pure returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}
