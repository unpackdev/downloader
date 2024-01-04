// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IPoolOnChainPriceFeed.sol";
import "./IPoolGeneral.sol";
import "./IPoolOnChainPriceFeedStorage.sol";
import "./FixedPoint.sol";
import "./IERC20.sol";
import "./IStandardERC20.sol";
import "./IDerivative.sol";
import "./IRole.sol";
import "./IFinder.sol";
import "./IPoolRegistry.sol";
import "./IPriceFeed.sol";
import "./Constants.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

/**
 * @notice Pool implementation is stored here to reduce deployment costs
 */

library SynthereumPoolOnChainPriceFeedLib {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolOnChainPriceFeedLib for ISynthereumPoolOnChainPriceFeedStorage.Storage;
  using SynthereumPoolOnChainPriceFeedLib for IDerivative;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  struct ExecuteMintParams {
    // Amount of synth tokens to mint
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) needed for mint
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral minted + fees
    FixedPoint.Unsigned totCollateralAmount;
  }

  struct ExecuteRedeemParams {
    //Amount of synth tokens needed for redeem
    FixedPoint.Unsigned numTokens;
    // Amount of collateral that user will receive
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redeemed + fees
    FixedPoint.Unsigned totCollateralAmount;
  }

  struct ExecuteExchangeParams {
    // Amount of tokens to send
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) equivalent to synthetic token (exluding fees) to send
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redemeed + fees
    FixedPoint.Unsigned totCollateralAmount;
    // Amount of synthetic token to receive
    FixedPoint.Unsigned destNumTokens;
  }

  //----------------------------------------
  // Events
  //----------------------------------------
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
  // We may omit the pool from event since we can recover it from the address of smart contract emitting event, but for query convenience we include it in the event
  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  // Check that derivative must be whitelisted in this pool
  modifier checkDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) {
    require(self.derivatives.contains(address(derivative)), 'Wrong derivative');
    _;
  }

  // Check that the sender must be an EOA if the flag isContractAllowed is false
  modifier checkIsSenderContract(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self
  ) {
    if (!self.isContractAllowed) {
      require(tx.origin == msg.sender, 'Account must be an EOA');
    }
    _;
  }

  //----------------------------------------
  // External function
  //----------------------------------------

  /**
   * @notice Initializes a fresh on chain pool
   * @notice The derivative's collateral currency must be a Collateral Token
   * @notice `_startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param self Data type the library is attached to
   * @param _version Synthereum version of the pool
   * @param _finder Synthereum finder
   * @param _derivative The perpetual derivative
   * @param _startingCollateralization Collateralization ratio to use before a global one is set
   * @param _isContractAllowed Enable or disable the option to accept meta-tx only by an EOA for security reason
   */
  function initialize(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    uint8 _version,
    ISynthereumFinder _finder,
    IDerivative _derivative,
    FixedPoint.Unsigned memory _startingCollateralization,
    bool _isContractAllowed
  ) external {
    self.version = _version;
    self.finder = _finder;
    self.startingCollateralization = _startingCollateralization;
    self.isContractAllowed = _isContractAllowed;
    self.collateralToken = getDerivativeCollateral(_derivative);
    self.syntheticToken = _derivative.tokenCurrency();
    self.priceIdentifier = _derivative.positionManagerData().priceIdentifier;
    self.derivatives.add(address(_derivative));
    emit AddDerivative(address(this), address(_derivative));
  }

  /**
   * @notice Add a derivate to be linked to this pool
   * @param self Data type the library is attached to
   * @param derivative A perpetual derivative
   */
  function addDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.collateralToken == getDerivativeCollateral(derivative),
      'Wrong collateral of the new derivative'
    );
    require(
      self.syntheticToken == derivative.tokenCurrency(),
      'Wrong synthetic token'
    );
    require(
      self.derivatives.add(address(derivative)),
      'Derivative has already been included'
    );
    emit AddDerivative(address(this), address(derivative));
  }

  /**
   * @notice Remove a derivate linked to this pool
   * @param self Data type the library is attached to
   * @param derivative A perpetual derivative
   */
  function removeDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.derivatives.remove(address(derivative)),
      'Derivative not included'
    );
    emit RemoveDerivative(address(this), address(derivative));
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param self Data type the library is attached to
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  )
    external
    checkIsSenderContract(self)
    returns (uint256 syntheticTokensMinted, uint256 feePaid)
  {
    FixedPoint.Unsigned memory totCollateralAmount =
      FixedPoint.Unsigned(mintParams.collateralAmount);
    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);
    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);
    FixedPoint.Unsigned memory numTokens =
      calculateNumberOfTokens(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        collateralAmount
      );
    require(
      numTokens.rawValue >= mintParams.minNumTokens,
      'Number of tokens less than minimum limit'
    );
    checkParams(
      self,
      mintParams.derivative,
      mintParams.feePercentage,
      mintParams.expiration
    );
    self.executeMint(
      mintParams.derivative,
      ExecuteMintParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount
      )
    );
    syntheticTokensMinted = numTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param self Data type the library is attached to
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams
  )
    external
    checkIsSenderContract(self)
    returns (uint256 collateralRedeemed, uint256 feePaid)
  {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(redeemParams.numTokens);
    FixedPoint.Unsigned memory totCollateralAmount =
      calculateCollateralAmount(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        numTokens
      );
    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);
    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);
    require(
      collateralAmount.rawValue >= redeemParams.minCollateral,
      'Collateral amount less than minimum limit'
    );
    checkParams(
      self,
      redeemParams.derivative,
      redeemParams.feePercentage,
      redeemParams.expiration
    );
    self.executeRedeem(
      redeemParams.derivative,
      ExecuteRedeemParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount
      )
    );
    feePaid = feeAmount.rawValue;
    collateralRedeemed = collateralAmount.rawValue;
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.ExchangeParams memory exchangeParams
  )
    external
    checkIsSenderContract(self)
    returns (uint256 destNumTokensMinted, uint256 feePaid)
  {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(exchangeParams.numTokens);

    FixedPoint.Unsigned memory totCollateralAmount =
      calculateCollateralAmount(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        numTokens
      );

    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);

    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);

    FixedPoint.Unsigned memory destNumTokens =
      calculateNumberOfTokens(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        exchangeParams.destPool.getPriceFeedIdentifier(),
        collateralAmount
      );

    require(
      destNumTokens.rawValue >= exchangeParams.minDestNumTokens,
      'Number of destination tokens less than minimum limit'
    );
    checkParams(
      self,
      exchangeParams.derivative,
      exchangeParams.feePercentage,
      exchangeParams.expiration
    );

    self.executeExchange(
      exchangeParams.derivative,
      exchangeParams.destPool,
      exchangeParams.destDerivative,
      ExecuteExchangeParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount,
        destNumTokens
      )
    );

    destNumTokensMinted = destNumTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the deployer
   * @param self Data type the library is attached to
   * @param srcDerivative Derivative used by the source pool
   * @param derivative Derivative that this pool will use
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative srcDerivative,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external {
    self.checkPool(ISynthereumPoolGeneral(msg.sender), srcDerivative);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    // Target the starting collateralization ratio if there is no global ratio
    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    // Check that LP collateral can support the tokens to be minted
    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    // Pull Collateral Tokens from calling Pool contract
    self.pullCollateral(msg.sender, collateralAmount);

    // Mint new tokens with the collateral
    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    // Transfer new tokens back to the calling Pool where they will be sent to the user
    self.transferSynTokens(msg.sender, numTokens);
  }

  /**
   * @notice Liquidity provider withdraw collateral from the pool
   * @param self Data type the library is attached to
   * @param collateralAmount The amount of collateral to withdraw
   */
  function withdrawFromPool(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) external {
    // Transfer the collateral from this pool to the LP sender
    self.collateralToken.safeTransfer(msg.sender, collateralAmount.rawValue);
  }

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param self Data type the library is attached to
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  /**
   * @notice Start a withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param self Data type the library is attached to
   * @param derivative Derivative from which request collateral withdrawal
   * @param collateralAmount The amount of short margin to withdraw
   */
  function slowWithdrawRequest(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    derivative.requestWithdrawal(collateralAmount);
  }

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param self Data type the library is attached to
   * @param derivative Derivative from which collateral withdrawal was requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdrawPassedRequest();
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param self Data type the library is attached to
   * @param derivative Derivative from which fast withdrawal was requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdraw(collateralAmount);
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  /**
   * @notice Actiavte emergency shutdown on a derivative in order to liquidate the token holders in case of emergency
   * @param self Data type the library is attached to
   * @param derivative Derivative on which emergency shutdown is called
   */
  function emergencyShutdown(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external checkDerivative(self, derivative) {
    derivative.emergencyShutdown();
  }

  /**
   * @notice Redeem tokens after derivative emergency shutdown
   * @param self Data type the library is attached to
   * @param derivative Derivative for which settlement is requested
   * @param liquidity_provider_role Lp role
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    bytes32 liquidity_provider_role
  ) external returns (uint256 amountSettled) {
    IERC20 tokenCurrency = self.syntheticToken;

    IERC20 collateralToken = self.collateralToken;

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    //Check if sender is a LP
    bool isLiquidityProvider =
      IRole(address(this)).hasRole(liquidity_provider_role, msg.sender);

    // Make sure there is something for the user to settle
    require(
      numTokens.isGreaterThan(0) || isLiquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      // Move synthetic tokens from the user to the pool
      // - This is because derivative expects the tokens to come from the sponsor address
      tokenCurrency.safeTransferFrom(
        msg.sender,
        address(this),
        numTokens.rawValue
      );

      // Allow the derivative to transfer tokens from the pool
      tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);
    }

    // Redeem the synthetic tokens for collateral
    derivative.settleEmergencyShutdown();

    // Amount of collateral that will be redeemed and sent to the user
    FixedPoint.Unsigned memory totalToRedeem;

    // If the user is the LP, send redeemed token collateral plus excess collateral
    if (isLiquidityProvider) {
      // Redeem LP collateral held in pool
      // Includes excess collateral withdrawn by a user previously calling `settleEmergencyShutdown`
      totalToRedeem = FixedPoint.Unsigned(
        collateralToken.balanceOf(address(this))
      );
    } else {
      // Otherwise, separate excess collateral from redeemed token value
      // Must be called after `emergencyShutdown` to make sure expiryPrice is set
      FixedPoint.Unsigned memory dueCollateral =
        numTokens.mul(derivative.emergencyShutdownPrice());

      totalToRedeem = FixedPoint.min(
        dueCollateral,
        FixedPoint.Unsigned(collateralToken.balanceOf(address(this)))
      );
    }
    amountSettled = totalToRedeem.rawValue;
    // Redeem the collateral for the underlying asset and transfer to the user
    collateralToken.safeTransfer(msg.sender, amountSettled);

    emit Settlement(
      msg.sender,
      address(this),
      numTokens.rawValue,
      amountSettled
    );
  }

  /**
   * @notice Update the fee percentage
   * @param self Data type the library is attached to
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) external {
    require(
      _feePercentage.rawValue < 10**(18),
      'Fee Percentage must be less than 100%'
    );
    self.fee.feePercentage = _feePercentage;
    emit SetFeePercentage(_feePercentage.rawValue);
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param self Data type the library is attached to
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );
    uint256 totalActualFeeProportions;
    // Store the sum of all proportions
    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }
    self.fee.feeRecipients = _feeRecipients;
    self.fee.feeProportions = _feeProportions;
    self.totalFeeProportions = totalActualFeeProportions;
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory startingCollateralRatio
  ) external {
    self.startingCollateralization = startingCollateralRatio;
  }

  /**
   * @notice Add a role into derivative to another contract
   * @param self Data type the library is attached to
   * @param derivative Derivative in which a role is being added
   * @param derivativeRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.DerivativeRoles derivativeRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (
      derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN
    ) {
      derivative.addAdmin(addressToAdd);
    } else {
      ISynthereumPoolGeneral pool = ISynthereumPoolGeneral(addressToAdd);
      IERC20 collateralToken = self.collateralToken;
      require(
        collateralToken == pool.collateralToken(),
        'Collateral tokens do not match'
      );
      require(
        self.syntheticToken == pool.syntheticToken(),
        'Synthetic tokens do not match'
      );
      ISynthereumFinder finder = self.finder;
      require(finder == pool.synthereumFinder(), 'Finders do not match');
      ISynthereumPoolRegistry poolRegister =
        ISynthereumPoolRegistry(
          finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
        );
      poolRegister.isPoolDeployed(
        pool.syntheticTokenSymbol(),
        collateralToken,
        pool.version(),
        address(pool)
      );
      if (
        derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.POOL
      ) {
        derivative.addPool(addressToAdd);
      } else if (
        derivativeRole ==
        ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN_AND_POOL
      ) {
        derivative.addAdminAndPool(addressToAdd);
      }
    }
  }

  /**
   * @notice Removing a role from a derivative contract
   * @param self Data type the library is attached to
   * @param derivative Derivative in which to remove a role
   * @param derivativeRole Role to remove
   */
  function renounceRoleInDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.DerivativeRoles derivativeRole
  ) external checkDerivative(self, derivative) {
    if (
      derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN
    ) {
      derivative.renounceAdmin();
    } else if (
      derivativeRole == ISynthereumPoolOnChainPriceFeed.DerivativeRoles.POOL
    ) {
      derivative.renouncePool();
    } else if (
      derivativeRole ==
      ISynthereumPoolOnChainPriceFeed.DerivativeRoles.ADMIN_AND_POOL
    ) {
      derivative.renounceAdminAndPool();
    }
  }

  /**
   * @notice Add a role into synthetic token to another contract
   * @param self Data type the library is attached to
   * @param derivative Derivative in which adding role
   * @param synthTokenRole Role to add
   * @param addressToAdd address of EOA or smart contract to add with a role in derivative
   */
  function addRoleInSynthToken(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolOnChainPriceFeed.SynthTokenRoles synthTokenRole,
    address addressToAdd
  ) external checkDerivative(self, derivative) {
    if (
      synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.ADMIN
    ) {
      derivative.addSyntheticTokenAdmin(addressToAdd);
    } else {
      require(
        self.syntheticToken == IDerivative(addressToAdd).tokenCurrency(),
        'Synthetic tokens do not match'
      );
      if (
        synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.MINTER
      ) {
        derivative.addSyntheticTokenMinter(addressToAdd);
      } else if (
        synthTokenRole == ISynthereumPoolOnChainPriceFeed.SynthTokenRoles.BURNER
      ) {
        derivative.addSyntheticTokenBurner(addressToAdd);
      } else if (
        synthTokenRole ==
        ISynthereumPoolOnChainPriceFeed
          .SynthTokenRoles
          .ADMIN_AND_MINTER_AND_BURNER
      ) {
        derivative.addSyntheticTokenAdminAndMinterAndBurner(addressToAdd);
      }
    }
  }

  /**
   * @notice Set the possibility to accept only EOA meta-tx
   * @param self Data type the library is attached to
   * @param isContractAllowed Flag that represent options to receive tx by a contract or only EOA
   */
  function setIsContractAllowed(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    bool isContractAllowed
  ) external {
    require(
      self.isContractAllowed != isContractAllowed,
      'Contract flag already set'
    );
    self.isContractAllowed = isContractAllowed;
  }

  //----------------------------------------
  //  Internal functions
  //----------------------------------------

  /**
   * @notice Execute mint of synthetic tokens
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param executeMintParams Params for execution of mint (see ExecuteMintParams struct)
   */
  function executeMint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ExecuteMintParams memory executeMintParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeMintParams.collateralAmount.isGreaterThan(0),
      'Sending amount is equal to 0'
    );

    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    // Target the starting collateralization ratio if there is no global ratio
    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    // Check that LP collateral can support the tokens to be minted
    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        executeMintParams.collateralAmount,
        executeMintParams.numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    // Pull user's collateral and mint fee into the pool
    self.pullCollateral(msg.sender, executeMintParams.totCollateralAmount);

    // Mint synthetic asset with collateral from user and liquidity provider
    self.mintSynTokens(
      derivative,
      executeMintParams.numTokens.mulCeil(targetCollateralization),
      executeMintParams.numTokens
    );

    // Transfer synthetic assets to the user
    self.transferSynTokens(msg.sender, executeMintParams.numTokens);

    // Send fees
    self.sendFee(executeMintParams.feeAmount);

    emit Mint(
      msg.sender,
      address(this),
      executeMintParams.totCollateralAmount.rawValue,
      executeMintParams.numTokens.rawValue,
      executeMintParams.feeAmount.rawValue
    );
  }

  /**
   * @notice Execute redeem of collateral
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param executeRedeemParams Params for execution of redeem (see ExecuteRedeemParams struct)
   */
  function executeRedeem(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ExecuteRedeemParams memory executeRedeemParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeRedeemParams.numTokens.isGreaterThan(0),
      'Sending amount is equal to 0'
    );
    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(
        msg.sender,
        derivative,
        executeRedeemParams.numTokens
      );
    require(
      amountWithdrawn.isGreaterThan(executeRedeemParams.totCollateralAmount),
      'Collateral from derivative less than collateral amount'
    );

    //Send net amount of collateral to the user that submited the redeem request
    self.collateralToken.safeTransfer(
      msg.sender,
      executeRedeemParams.collateralAmount.rawValue
    );
    // Send fees collected
    self.sendFee(executeRedeemParams.feeAmount);

    emit Redeem(
      msg.sender,
      address(this),
      executeRedeemParams.numTokens.rawValue,
      executeRedeemParams.collateralAmount.rawValue,
      executeRedeemParams.feeAmount.rawValue
    );
  }

  /**
   * @notice Execute exchange between synthetic tokens
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param destPool Pool of synthetic token to receive
   * @param destDerivative Derivative of the pool of synthetic token to receive
   * @param executeExchangeParams Params for execution of exchange (see ExecuteExchangeParams struct)
   */
  function executeExchange(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolGeneral destPool,
    IDerivative destDerivative,
    ExecuteExchangeParams memory executeExchangeParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeExchangeParams.numTokens.isGreaterThan(0),
      'Sending amount is equal to 0'
    );
    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(
        msg.sender,
        derivative,
        executeExchangeParams.numTokens
      );

    require(
      amountWithdrawn.isGreaterThan(executeExchangeParams.totCollateralAmount),
      'Collateral from derivative less than collateral amount'
    );
    self.checkPool(destPool, destDerivative);

    self.sendFee(executeExchangeParams.feeAmount);

    self.collateralToken.safeApprove(
      address(destPool),
      executeExchangeParams.collateralAmount.rawValue
    );
    // Mint the destination tokens with the withdrawn collateral
    destPool.exchangeMint(
      derivative,
      destDerivative,
      executeExchangeParams.collateralAmount.rawValue,
      executeExchangeParams.destNumTokens.rawValue
    );

    // Transfer the new tokens to the user
    destDerivative.tokenCurrency().safeTransfer(
      msg.sender,
      executeExchangeParams.destNumTokens.rawValue
    );

    emit Exchange(
      msg.sender,
      address(this),
      address(destPool),
      executeExchangeParams.numTokens.rawValue,
      executeExchangeParams.destNumTokens.rawValue,
      executeExchangeParams.feeAmount.rawValue
    );
  }

  /**
   * @notice Pulls collateral tokens from the sender to store in the Pool
   * @param self Data type the library is attached to
   * @param numTokens The number of tokens to pull
   */
  function pullCollateral(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeTransferFrom(
      from,
      address(this),
      numTokens.rawValue
    );
  }

  /**
   * @notice Mints synthetic tokens with the available collateral
   * @param self Data type the library is attached to
   * @param collateralAmount The amount of collateral to send
   * @param numTokens The number of tokens to mint
   */
  function mintSynTokens(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.create(collateralAmount, numTokens);
  }

  /**
   * @notice Transfer synthetic tokens from the derivative to an address
   * @dev Refactored from `mint` to guard against reentrancy
   * @param self Data type the library is attached to
   * @param recipient The address to send the tokens
   * @param numTokens The number of tokens to send
   */
  function transferSynTokens(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.syntheticToken.safeTransfer(recipient, numTokens.rawValue);
  }

  /**
   * @notice Redeem synthetic tokens for collateral from the derivative
   * @param tokenHolder Address of the user that redeems
   * @param derivative Derivative from which collateral is redeemed
   * @param numTokens The number of tokens to redeem
   * @return amountWithdrawn Collateral amount withdrawn by redeem execution
   */
  function redeemForCollateral(
    address tokenHolder,
    IDerivative derivative,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory amountWithdrawn) {
    IERC20 tokenCurrency = derivative.positionManagerData().tokenCurrency;
    require(
      tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue,
      'Token balance less than token to redeem'
    );

    // Move synthetic tokens from the user to the Pool
    // - This is because derivative expects the tokens to come from the sponsor address
    tokenCurrency.safeTransferFrom(
      tokenHolder,
      address(this),
      numTokens.rawValue
    );

    // Allow the derivative to transfer tokens from the Pool
    tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);

    // Redeem the synthetic tokens for Collateral tokens
    amountWithdrawn = derivative.redeem(numTokens);
  }

  /**
   * @notice Send collateral withdrawn by the derivative to the LP
   * @param self Data type the library is attached to
   * @param collateralAmount Amount of collateral to send to the LP
   * @param recipient Address of a LP
   * @return amountWithdrawn Collateral amount withdrawn
   */
  function liquidateWithdrawal(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    address recipient
  ) internal returns (uint256 amountWithdrawn) {
    amountWithdrawn = collateralAmount.rawValue;
    self.collateralToken.safeTransfer(recipient, amountWithdrawn);
  }

  /**
   * @notice Set the Pool fee structure parameters
   * @param self Data type the library is attached tfo
   * @param _feeAmount Amount of fee to send
   */
  function sendFee(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    // Distribute fees
    // TODO Consider using the withdrawal pattern for fees
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      self.collateralToken.safeTransfer(
        self.fee.feeRecipients[i],
        // This order is important because it mixes FixedPoint with unscaled uint
        _feeAmount
          .mul(self.fee.feeProportions[i])
          .div(self.totalFeeProportions)
          .rawValue
      );
    }
  }

  //----------------------------------------
  //  Internal views functions
  //----------------------------------------

  /**
   * @notice Check fee percentage and expiration of mint, redeem and exchange transaction
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param feePercentage Maximum percentage of fee that a user want to pay
   * @param expiration Expiration time of the transaction
   */
  function checkParams(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    uint256 feePercentage,
    uint256 expiration
  ) internal view checkDerivative(self, derivative) {
    require(now <= expiration, 'Transaction expired');
    require(
      self.fee.feePercentage.rawValue <= feePercentage,
      'User fee percentage less than actual one'
    );
  }

  /**
   * @notice Get the address of collateral of a perpetual derivative
   * @param derivative Address of the perpetual derivative
   * @return collateral Address of the collateral of perpetual derivative
   */
  function getDerivativeCollateral(IDerivative derivative)
    internal
    view
    returns (IERC20 collateral)
  {
    collateral = derivative.collateralCurrency();
  }

  /**
   * @notice Get the global collateralization ratio of the derivative
   * @param derivative Perpetual derivative contract
   * @return The global collateralization ratio
   */
  function getGlobalCollateralizationRatio(IDerivative derivative)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      derivative.globalPositionData().totalTokensOutstanding;
    if (totalTokensOutstanding.isGreaterThan(0)) {
      return derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  /**
   * @notice Check if a call to `mint` with the supplied parameters will succeed
   * @dev Compares the new collateral from `collateralAmount` combined with LP collateral
   *      against the collateralization ratio of the derivative.
   * @param self Data type the library is attached to
   * @param globalCollateralization The global collateralization ratio of the derivative
   * @param collateralAmount The amount of additional collateral supplied
   * @param numTokens The number of tokens to mint
   * @return `true` if there is sufficient collateral
   */
  function checkCollateralizationRatio(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory globalCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (bool) {
    // Collateral ratio possible for new tokens accounting for LP collateral
    FixedPoint.Unsigned memory newCollateralization =
      collateralAmount
        .add(FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this))))
        .div(numTokens);

    // Check that LP collateral can support the tokens to be minted
    return newCollateralization.isGreaterThanOrEqual(globalCollateralization);
  }

  /**
   * @notice Check if sender or receiver pool is a correct registered pool
   * @param self Data type the library is attached to
   * @param poolToCheck Pool that should be compared with this pool
   * @param derivativeToCheck Derivative of poolToCheck
   */
  function checkPool(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolGeneral poolToCheck,
    IDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(derivativeToCheck),
      'Wrong derivative'
    );
    IERC20 collateralToken = self.collateralToken;
    require(
      collateralToken == poolToCheck.collateralToken(),
      'Collateral tokens do not match'
    );
    ISynthereumFinder finder = self.finder;
    require(finder == poolToCheck.synthereumFinder(), 'Finders do not match');
    ISynthereumPoolRegistry poolRegister =
      ISynthereumPoolRegistry(
        finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );
    require(
      poolRegister.isPoolDeployed(
        poolToCheck.syntheticTokenSymbol(),
        collateralToken,
        poolToCheck.version(),
        address(poolToCheck)
      ),
      'Destination pool not registred'
    );
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token, using on-chain oracle
   * @param finder Synthereum finder
   * @param collateralToken Collateral token contract
   * @param priceIdentifier Identifier of price pair
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function calculateCollateralAmount(
    ISynthereumFinder finder,
    IStandardERC20 collateralToken,
    bytes32 priceIdentifier,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (FixedPoint.Unsigned memory collateralAmount) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(finder, priceIdentifier);
    uint256 decimalsOfCollateral = getCollateralDecimals(collateralToken);
    collateralAmount = numTokens.mul(priceRate).div(
      10**((uint256(18)).sub(decimalsOfCollateral))
    );
  }

  /**
   * @notice Calculate synthetic token amount starting from an amount of collateral, using on-chain oracle
   * @param finder Synthereum finder
   * @param collateralToken Collateral token contract
   * @param priceIdentifier Identifier of price pair
   * @param numTokens Amount of collateral from which you want to calculate synthetic token amount
   * @return numTokens Amount of tokens after on-chain oracle conversion
   */
  function calculateNumberOfTokens(
    ISynthereumFinder finder,
    IStandardERC20 collateralToken,
    bytes32 priceIdentifier,
    FixedPoint.Unsigned memory collateralAmount
  ) internal view returns (FixedPoint.Unsigned memory numTokens) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(finder, priceIdentifier);
    uint256 decimalsOfCollateral = getCollateralDecimals(collateralToken);
    numTokens = collateralAmount
      .mul(10**((uint256(18)).sub(decimalsOfCollateral)))
      .div(priceRate);
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @param finder Synthereum finder
   * @param priceIdentifier Identifier of price pair
   * @return priceRate Latest rate of the pair
   */
  function getPriceFeedRate(ISynthereumFinder finder, bytes32 priceIdentifier)
    internal
    view
    returns (FixedPoint.Unsigned memory priceRate)
  {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );
    priceRate = FixedPoint.Unsigned(priceFeed.getLatestPrice(priceIdentifier));
  }

  /**
   * @notice Retrun the number of decimals of collateral token
   * @param collateralToken Collateral token contract
   * @return decimals number of decimals
   */
  function getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint256 decimals)
  {
    decimals = collateralToken.decimals();
  }
}
