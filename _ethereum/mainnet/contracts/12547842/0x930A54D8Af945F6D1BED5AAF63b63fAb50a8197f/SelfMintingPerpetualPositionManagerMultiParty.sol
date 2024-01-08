// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IStandardERC20.sol";
import "./MintableBurnableIERC20.sol";
import "./IdentifierWhitelistInterface.sol";
import "./AddressWhitelist.sol";
import "./AdministrateeInterface.sol";
import "./IFinder.sol";
import "./ISelfMintingDerivativeDeployment.sol";
import "./OracleInterface.sol";
import "./Constants.sol";
import "./Constants.sol";
import "./FixedPoint.sol";
import "./SafeERC20.sol";
import "./SelfMintingPerpetualPositionManagerMultiPartyLib.sol";
import "./FeePayerParty.sol";

/**
 * @title Financial contract with priceless position management.
 * @notice Handles positions for multiple sponsors in an optimistic (i.e., priceless) way without relying
 * on a price feed. On construction, deploys a new ERC20, managed by this contract, that is the synthetic token.
 */
contract SelfMintingPerpetualPositionManagerMultiParty is
  ISelfMintingDerivativeDeployment,
  FeePayerParty
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for PositionData;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for PositionManagerData;

  /**
   * @notice Construct the PerpetualPositionManager.
   * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
   * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
   * can mint new tokens, which could be used to steal all of this contract's locked collateral.
   * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
   * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
   * total supply is 0 prior to construction of this contract.
   * @param withdrawalLiveness liveness delay, in seconds, for pending withdrawals.
   * @param collateralAddress ERC20 token used as collateral for all positions.
   * @param tokenAddress ERC20 token used as synthetic token.
   * @param finderAddress UMA protocol Finder used to discover other protocol contracts.
   * @param priceFeedIdentifier registered in the DVM for the synthetic.
   * @param minSponsorTokens minimum amount of collateral that must exist at any time in a position.
   * @param timerAddress Contract that stores the current time in a testing environment. Set to 0x0 for production.
   * @param excessTokenBeneficiary Beneficiary to send all excess token balances that accrue in the contract.
   * @param version Version of the self-minting derivative
   * @param synthereumFinder The SynthereumFinder contract
   */
  struct PositionManagerParams {
    uint256 withdrawalLiveness;
    address collateralAddress;
    address tokenAddress;
    address finderAddress;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address timerAddress;
    address excessTokenBeneficiary;
    uint8 version;
    ISynthereumFinder synthereumFinder;
  }

  // Represents a single sponsor's position. All collateral is held by this contract.
  // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
  struct PositionData {
    FixedPoint.Unsigned tokensOutstanding;
    // Tracks pending withdrawal requests. A withdrawal request is pending if `withdrawalRequestPassTimestamp != 0`.
    uint256 withdrawalRequestPassTimestamp;
    FixedPoint.Unsigned withdrawalRequestAmount;
    // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
    // To add or remove collateral, use _addCollateral() and _removeCollateral().
    FixedPoint.Unsigned rawCollateral;
  }

  struct GlobalPositionData {
    // Keep track of the total collateral and tokens across all positions to enable calculating the
    // global collateralization ratio without iterating over all positions.
    FixedPoint.Unsigned totalTokensOutstanding;
    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    //_getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  struct PositionManagerData {
    // SynthereumFinder contract
    ISynthereumFinder synthereumFinder;
    // Synthetic token created by this contract.
    MintableBurnableIERC20 tokenCurrency;
    // Unique identifier for DVM price feed ticker.
    bytes32 priceIdentifier;
    // Time that has to elapse for a withdrawal request to be considered passed, if no liquidations occur.
    // !!Note: The lower the withdrawal liveness value, the more risk incurred by the contract.
    // Extremely low liveness values increase the chance that opportunistic invalid withdrawal requests
    // expire without liquidation, thereby increasing the insolvency risk for the contract as a whole. An insolvent
    // contract is extremely risky for any sponsor or synthetic token holder for the contract.
    uint256 withdrawalLiveness;
    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned minSponsorTokens;
    // Expiry price pulled from the DVM in the case of an emergency shutdown.
    FixedPoint.Unsigned emergencyShutdownPrice;
    // Timestamp used in case of emergency shutdown.
    uint256 emergencyShutdownTimestamp;
    // The excessTokenBeneficiary of any excess tokens added to the contract.
    address excessTokenBeneficiary;
    // Version of the self-minting derivative
    uint8 version;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  // Maps sponsor addresses to their positions. Each sponsor can have only one position.
  mapping(address => PositionData) public positions;

  GlobalPositionData public globalPositionData;

  PositionManagerData public positionManagerData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event RequestWithdrawal(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalExecuted(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalCanceled(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount,
    uint256 feeAmount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyCollateralizedPosition(address sponsor) {
    _onlyCollateralizedPosition(sponsor);
    _;
  }

  modifier notEmergencyShutdown() {
    _notEmergencyShutdown();
    _;
  }

  modifier isEmergencyShutdown() {
    _isEmergencyShutdown();
    _;
  }

  modifier noPendingWithdrawal(address sponsor) {
    _positionHasNoPendingWithdrawal(sponsor);
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Construct the SelfMintingPerpetualPositionManagerMultiParty.
   * @param _positionManagerData Input parameters of PositionManager (see PositionManagerData struct)
   */
  constructor(PositionManagerParams memory _positionManagerData)
    public
    FeePayerParty(
      _positionManagerData.collateralAddress,
      _positionManagerData.finderAddress,
      _positionManagerData.timerAddress
    )
    nonReentrant()
  {
    require(
      _getIdentifierWhitelist().isIdentifierSupported(
        _positionManagerData.priceFeedIdentifier
      ),
      'Unsupported price identifier'
    );
    require(
      _getCollateralWhitelist().isOnWhitelist(
        _positionManagerData.collateralAddress
      ),
      'Collateral not whitelisted'
    );
    positionManagerData.synthereumFinder = _positionManagerData
      .synthereumFinder;
    positionManagerData.withdrawalLiveness = _positionManagerData
      .withdrawalLiveness;
    positionManagerData.tokenCurrency = MintableBurnableIERC20(
      _positionManagerData.tokenAddress
    );
    positionManagerData.minSponsorTokens = _positionManagerData
      .minSponsorTokens;
    positionManagerData.priceIdentifier = _positionManagerData
      .priceFeedIdentifier;
    positionManagerData.excessTokenBeneficiary = _positionManagerData
      .excessTokenBeneficiary;
    positionManagerData.version = _positionManagerData.version;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Transfers `collateralAmount` of `feePayerData.collateralCurrency` into the caller's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of `feePayerData.collateralCurrency`.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function deposit(uint256 collateralAmount) external {
    depositTo(msg.sender, collateralAmount);
  }

  /**
   * @notice Transfers `collateralAmount` of `feePayerData.collateralCurrency` from the sponsor's position to the sponsor.
   * @dev Reverts if the withdrawal puts this position's collateralization ratio below the global collateralization
   * ratio. In that case, use `requestWithdrawal`. Might not withdraw the full requested amount to account for precision loss.
   * @param collateralAmount is the amount of collateral to withdraw.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdraw(uint256 collateralAmount)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData
      .withdraw(
      globalPositionData,
      FixedPoint.Unsigned(collateralAmount),
      feePayerData
    )
      .rawValue;
  }

  /**
   * @notice Starts a withdrawal request that, if passed, allows the sponsor to withdraw` from their position.
   * @dev The request will be pending for `withdrawalLiveness`, during which the position can be liquidated.
   * @param collateralAmount the amount of collateral requested to withdraw
   */
  function requestWithdrawal(uint256 collateralAmount)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    nonReentrant()
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.requestWithdrawal(
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      actualTime,
      feePayerData
    );
  }

  /**
   * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and waiting
   * `withdrawalLiveness`), withdraws `positionData.withdrawalRequestAmount` of collateral currency.
   * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
   * amount exceeds the collateral in the position (due to paying fees).
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdrawPassedRequest()
    external
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn)
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    amountWithdrawn = positionData
      .withdrawPassedRequest(globalPositionData, actualTime, feePayerData)
      .rawValue;
  }

  /**
   * @notice Cancels a pending withdrawal request.
   */
  function cancelWithdrawal() external notEmergencyShutdown() nonReentrant() {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.cancelWithdrawal();
  }

  /**
   * @notice Creates tokens by creating a new position or by augmenting an existing position. Pulls `collateralAmount
   * ` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
   * @dev Can only be called by a token sponsor. Might not mint the full proportional amount of collateral
   * in order to account for precision loss. This contract must be approved to spend at least `collateralAmount` of
   * `collateralCurrency`.
   * @param collateralAmount is the number of collateral tokens to collateralize the position with
   * @param numTokens is the number of tokens to mint from the position.
   * @param feePercentage The percentage of fee that is paid in collateralCurrency
   */
  function create(
    uint256 collateralAmount,
    uint256 numTokens,
    uint256 feePercentage
  )
    external
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (uint256 daoFeeAmount)
  {
    PositionData storage positionData = positions[msg.sender];
    daoFeeAmount = positionData
      .create(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens),
      FixedPoint.Unsigned(feePercentage),
      feePayerData
    )
      .rawValue;
  }

  /**
   * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of `feePayerData.collateralCurrency`.
   * @dev Can only be called by a token sponsor. Might not redeem the full proportional amount of collateral
   * in order to account for precision loss. This contract must be approved to spend at least `numTokens` of
   * `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function redeem(uint256 numTokens, uint256 feePercentage)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn, uint256 daoFeeAmount)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    (
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory feeAmount
    ) =
      positionData.redeeem(
        globalPositionData,
        positionManagerData,
        FixedPoint.Unsigned(numTokens),
        FixedPoint.Unsigned(feePercentage),
        feePayerData,
        msg.sender
      );

    amountWithdrawn = collateralAmount.rawValue;
    daoFeeAmount = feeAmount.rawValue;
  }

  /**
   * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back `feePayerData.collateralCurrency`.
   * This is done by a sponsor to increase position CR.
   * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
   * @param feePercentage the fee percentage paid by the token sponsor in collateralCurrency
   */
  function repay(uint256 numTokens, uint256 feePercentage)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (uint256 daoFeeAmount)
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    daoFeeAmount = (
      positionData.repay(
        globalPositionData,
        positionManagerData,
        FixedPoint.Unsigned(numTokens),
        FixedPoint.Unsigned(feePercentage),
        feePayerData
      )
    )
      .rawValue;
  }

  /**
   * @notice If the contract is emergency shutdown then all token holders and sponsor can redeem their tokens or
   * remaining collateral for underlying at the prevailing price defined by a DVM vote.
   * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
   * `feePayerData.collateralCurrency`. Might not redeem the full proportional amount of collateral in order to account for
   * precision loss. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
   * @dev This contract must have the Burner role for the `tokenCurrency`.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function settleEmergencyShutdown()
    external
    isEmergencyShutdown()
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = positions[msg.sender];
    amountWithdrawn = positionData
      .settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      feePayerData
    )
      .rawValue;
  }

  /**
   * @notice Premature contract settlement under emergency circumstances.
   * @dev Only the governor can call this function as they are permissioned within the `FinancialContractAdmin`.
   * Upon emergency shutdown, the contract settlement time is set to the shutdown time. This enables withdrawal
   * to occur via the `settleEmergencyShutdown` function.
   */
  function emergencyShutdown()
    external
    override
    notEmergencyShutdown()
    nonReentrant()
  {
    require(
      msg.sender ==
        positionManagerData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Manager
        ) ||
        msg.sender == _getFinancialContractsAdminAddress(),
      'Caller must be a Synthereum manager or the UMA governor'
    );
    positionManagerData.emergencyShutdownTimestamp = getCurrentTime();
    positionManagerData.requestOraclePrice(
      positionManagerData.emergencyShutdownTimestamp,
      feePayerData
    );
    emit EmergencyShutdown(
      msg.sender,
      positionManagerData.emergencyShutdownTimestamp
    );
  }

  /** @notice Remargin function
   */
  function remargin() external override {
    return;
  }

  /**
   * @notice Drains any excess balance of the provided ERC20 token to a pre-selected beneficiary.
   * @dev This will drain down to the amount of tracked collateral and drain the full balance of any other token.
   * @param token address of the ERC20 token whose excess balance should be drained.
   */
  function trimExcess(IERC20 token)
    external
    nonReentrant()
    returns (uint256 amount)
  {
    FixedPoint.Unsigned memory pfcAmount = _pfc();
    amount = positionManagerData
      .trimExcess(token, pfcAmount, feePayerData)
      .rawValue;
  }

  /**
   * @notice Delete a TokenSponsor position (This function can only be called by the contract itself)
   * @param sponsor address of the TokenSponsor.
   */
  function deleteSponsorPosition(address sponsor) external onlyThisContract {
    delete positions[sponsor];
  }

  /**
   * @notice Accessor method for a sponsor's collateral.
   * @dev This is necessary because the struct returned by the positions() method shows
   * rawCollateral, which isn't a user-readable value.
   * @param sponsor address whose collateral amount is retrieved.
   * @return collateralAmount amount of collateral within a sponsors position.
   */
  function getCollateral(address sponsor)
    external
    view
    nonReentrantView()
    returns (FixedPoint.Unsigned memory collateralAmount)
  {
    return
      positions[sponsor].rawCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  /**
   * @notice Get SynthereumFinder contract address
   * @return finder SynthereumFinder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = positionManagerData.synthereumFinder;
  }

  /**
   * @notice Get synthetic token currency
   * @return synthToken Synthetic token
   */
  function tokenCurrency() external view override returns (IERC20 synthToken) {
    synthToken = positionManagerData.tokenCurrency;
  }

  /**
   * @notice Get synthetic token symbol
   * @return symbol Synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(positionManagerData.tokenCurrency))
      .symbol();
  }

  /** @notice Get the version of a self minting derivative
   * @return contractVersion Contract version
   */
  function version() external view override returns (uint8 contractVersion) {
    contractVersion = positionManagerData.version;
  }

  /**
   * @notice Get synthetic token price identifier registered with UMA DVM
   * @return identifier Synthetic token price identifier
   */
  function priceIdentifier() external view returns (bytes32 identifier) {
    identifier = positionManagerData.priceIdentifier;
  }

  /**
   * @notice Accessor method for the total collateral stored within the SelfMintingPerpetualPositionManagerMultiParty.
   * @return totalCollateral amount of all collateral within the position manager.
   */
  function totalPositionCollateral()
    external
    view
    nonReentrantView()
    returns (uint256)
  {
    return
      globalPositionData
        .rawTotalPositionCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .rawValue;
  }

  /**
   * @notice Get the currently minted synthetic tokens from all self-minting derivatives
   * @return totalTokens Total amount of synthetic tokens minted
   */
  function totalTokensOutstanding() external view returns (uint256) {
    return globalPositionData.totalTokensOutstanding.rawValue;
  }

  /**
   * @notice Get the price of synthetic token set by DVM after emergencyShutdown call
   * @return Price of synthetic token
   */
  function emergencyShutdownPrice()
    external
    view
    isEmergencyShutdown()
    returns (uint256)
  {
    return positionManagerData.emergencyShutdownPrice.rawValue;
  }

  /** @notice Calculates the DAO fee based on the numTokens parameter
   * @param numTokens Number of synthetic tokens used in the transaction
   * @return rawValue The DAO fee to be paid in collateralCurrency
   */
  function calculateDaoFee(uint256 numTokens) external view returns (uint256) {
    return
      positionManagerData
        .calculateDaoFee(
        globalPositionData,
        FixedPoint.Unsigned(numTokens),
        feePayerData
      )
        .rawValue;
  }

  /** @notice Checks the currently set fee recipient and fee percentage for the DAO fee
   * @return feePercentage The percentage set by the DAO to be taken as a fee on each transaction
   * @return feeRecipient The DAO address that receives the fee
   */
  function daoFee()
    external
    view
    returns (uint256 feePercentage, address feeRecipient)
  {
    (FixedPoint.Unsigned memory percentage, address recipient) =
      positionManagerData.daoFee();
    feePercentage = percentage.rawValue;
    feeRecipient = recipient;
  }

  /** @notice Check the current cap on self-minting synthetic tokens.
   * A cap mint amount is set in order to avoid depletion of liquidity pools,
   * by self-minting synthetic assets and redeeming collateral from the pools.
   * The cap mint amount is updateable and is based on a percentage of the currently
   * minted synthetic assets from the liquidity pools.
   * @return capMint The currently set cap amount for self-minting a synthetic token
   */
  function capMintAmount() external view returns (uint256 capMint) {
    capMint = positionManagerData.capMintAmount().rawValue;
  }

  /** @notice Check the current cap on deposit of collateral into a self-minting derivative.
   * A cap deposit ratio is set in order to avoid a troll attack in which an attacker
   * can increase infinitely the GCR thus making it extremelly expensive or impossible
   * for other users to self-mint synthetic assets with a given collateral.
   * @return capDeposit The current cap deposit ratio
   */
  function capDepositRatio() external view returns (uint256 capDeposit) {
    capDeposit = positionManagerData.capDepositRatio().rawValue;
  }

  /**
   * @notice Transfers `collateralAmount` of `feePayerData.collateralCurrency` into the specified sponsor's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of `feePayerData.collateralCurrency`.
   * @param sponsor the sponsor to credit the deposit to.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function depositTo(address sponsor, uint256 collateralAmount)
    public
    notEmergencyShutdown()
    noPendingWithdrawal(sponsor)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      feePayerData,
      sponsor
    );
  }

  /** @notice Check the collateralCurrency in which fees are paid for a given self-minting derivative
   * @return collateral The collateral currency
   */
  function collateralCurrency()
    public
    view
    override(ISelfMintingDerivativeDeployment, FeePayerParty)
    returns (IERC20 collateral)
  {
    collateral = FeePayerParty.collateralCurrency();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  /** @notice Gets the adjusted collateral after substracting fee
   * @return adjusted net collateral
   */
  function _pfc()
    internal
    view
    virtual
    override
    returns (FixedPoint.Unsigned memory)
  {
    return
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  /** @notice Gets all data on a given sponsors position for a self-minting derivative
   * @param sponsor Address of the sponsor to check
   * @return A struct of information on a tokens sponsor position
   */
  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralizedPosition(sponsor)
    returns (PositionData storage)
  {
    return positions[sponsor];
  }

  /** @notice Get a whitelisted price feed implementation from the Finder contract for a self-minting derivative
   * @return IdentifierWhitelistInterface Address of the whitelisted identifier
   */
  function _getIdentifierWhitelist()
    internal
    view
    returns (IdentifierWhitelistInterface)
  {
    return
      IdentifierWhitelistInterface(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.IdentifierWhitelist
        )
      );
  }

  /** @notice Get a whitelisted collateralCurrency address from the Finder contract for a self-minting derivative
   * @return AddressWhitelist Address of the whitelisted collateralCurrency
   */
  function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
    return
      AddressWhitelist(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.CollateralWhitelist
        )
      );
  }

  /** @notice Get the collateral for a position of a token sponsor on a self-minting derivative if any
   * or return that this token sponsor does not have such a position
   * @param sponsor Address of the token sponsor to check
   */
  function _onlyCollateralizedPosition(address sponsor) internal view {
    require(
      positions[sponsor]
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isGreaterThan(0),
      'Position has no collateral'
    );
  }

  /** @notice Make sure an emergency shutdown is not called on a self-minting derivative
   */
  function _notEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
  }

  /** @notice Make sure an emergency shutdown is called on a self-minting derivative
   */
  function _isEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
  }

  /** @notice Make sure that there are no pending withdraws on a position of a token sponsor
   * @param sponsor Token sponsor address for which to check
   */
  function _positionHasNoPendingWithdrawal(address sponsor) internal view {
    require(
      _getPositionData(sponsor).withdrawalRequestPassTimestamp == 0,
      'Pending withdrawal'
    );
  }

  /** @notice Gets the financial contract admin address
   */
  function _getFinancialContractsAdminAddress()
    internal
    view
    returns (address)
  {
    return
      feePayerData.finder.getImplementationAddress(
        OracleInterfaces.FinancialContractsAdmin
      );
  }
}
