// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;
import "./ERC20.sol";
import "./IERC20ByMetadrop.sol";
import "./IERC20DRIPoolByMetadrop.sol";
import "./IUniswapV2Router02.sol";
import "./Revert.sol";
import "./SafeERC20.sol";
import "./SignatureChecker.sol";

/**
 * @dev Metadrop ERC-20 Decentralised Rationalised Incentive Pool (DRIP)
 *
 * @dev Implementation of the {IERC20DRIPoolByMetadrop} interface.
 */

contract ERC20DRIPoolByMetadrop is ERC20, IERC20DRIPoolByMetadrop, Revert {
  using SafeERC20 for IERC20ByMetadrop;
  using SafeERC20 for IERC20;

  // Multiplier constant: you receive 1,000,000 DRIP for every ETH contributed:
  uint256 private constant ETH_TO_DRIP_MULTIPLIER = 1000000;

  // DRIP are burned to the 0x...dEaD address (not address(0)) in order to maintain a constant total
  // supply value during claims and refunds:
  address private constant DEAD_ADDRESS =
    0x000000000000000000000000000000000000dEaD;

  // Proportions are held in basis points, this is the basis point denominator:
  uint256 internal constant CONST_BP_DENOM = 10000;

  // The oracle signed message validity period:
  uint256 internal constant MSG_VALIDITY_SECONDS = 30 minutes;

  // The DP we use to truncate the fee amount. We truncate this many positions of WEI
  // from the fee. For example, is this is 10 ** 12 we are truncating to 6 DP of ETH, i.e.
  // we are setting the final 12 figures of the fee to zeros (ETH having 18 decimal places).
  uint256 internal constant FEE_DP_OF_ETH_FACTOR = 10 ** 12;

  // Address of the uniswap router on this chain:
  IUniswapV2Router02 public immutable uniswapRouter;

  // Metadrop Oracle Address:
  address public immutable metadropOracleAddress;

  // Slot 1: accessed when contributing to the pool
  //     96
  //     80
  //     64
  //     16
  // ------
  //    256
  // ------
  // What is the max pooled ETH? Contributions that would exceed this amount will not
  // be accepted: If this is ZERO there is no no limits, won't give up the fight.
  uint96 public poolMaxETH;

  // What is the max contribution per address? If this is ZERO there is no no limits,
  // we'll reach for the sky
  uint80 public poolPerAddressMaxETH;

  // What is the minimum contribution per transaction?:
  uint64 public poolPerTransactionMinETH;

  // Contribution fee in basis points - how much is automatically deducted from contribution. Note
  // that this is applied irrespective of whether EXCESS ETH is refunded at a point in the future
  // (for example if the pool is oversubscribed and only a portion of the contributed ETH is
  // converted to token ownership).
  // However - if the pool falls below the minimum contributions are refunded 100% i.e. no fee.
  uint16 public poolContributionFeeBasisPoints;

  // Slot 2: accessed when contributing to the pool:
  //     32
  //     32
  //     96
  //     96
  // ------
  //    256
  // ------
  // When does the pool phase start? Contributions to the DRIP will not be accepted
  // before this date:
  uint32 public poolStartDate;

  // When does the pool phase end? Contributions to the DRIP will not be accepted
  // after this date:
  uint32 public poolEndDate;

  // How many fees have accumulated:
  uint96 public accumulatedFees;

  // Store of the amount of ETH funded into LP / token buy:
  uint96 public totalETHFundedToLPAndTokenBuy;

  // Slot 3: accessed when claiming from the pool:
  //      8
  //     16
  //     16
  //    120
  //     96
  // ------
  //    256
  // ------
  // Pool type:
  DRIPoolType private _driPoolType;

  // If there is a vesting period for token claims this var will be that period in DAYS:
  uint32 public poolVestingInSeconds;

  // The supply of the pooled token in this pool (this is the token that pool participants
  // will claim, not the DRIP token):
  uint120 public supplyInThePool;

  // An accumulator for the total excess ETH refunded:
  uint96 public totalExcessETHRefunded;

  // Slot 4: accessed when claiming from the pool
  //    160
  //     96
  // ------
  //    256
  // ------
  // This is the contract address of the metadrop ERC20 that is being placed in this
  // pool:
  IERC20ByMetadrop public createdERC20;

  // Minimum amount for the pool to proceed:
  uint96 public poolMinETH;

  // Slot 5: accessed as part of claims / refunds
  //    160
  //     96
  // ------
  //    256
  // ------
  // The address that seeded the project ETH:
  address public projectSeedContributionAddress;

  // The amount of ETH seeded:
  uint96 public projectSeedContributionETH;

  // Slot 6: accessed as part of the supply funding / intitial buy process
  //    160
  //     96
  // ------
  //    256
  // ------
  // Recipient of accumulated fees
  address public poolFeeRecipient;

  // Max initial buy size. ETH above this will be refunded on a pro-rata basis
  uint96 public maxInitialBuy;

  // Slot 7: accessed as part of the supply funding / intitial buy process (if this is
  // an intial funding type pool)
  //     96
  //      8
  // ------
  //    104
  // ------
  // Max initial liquidity size. ETH above this will be refunded on a pro-rata basis
  uint96 public maxInitialLiquidity;

  // Bool that controls initialisation and only allows it to occur ONCE. This is
  // needed as this contract is clonable, threfore the constructor is not called
  // on cloned instances. We setup state of this contract through the initialise
  // function.
  bool public initialised;

  // Slot 8 to n:
  // ------
  //    256
  // ------
  // The name of this DRIP token:
  string private _dripName;

  // The symbol of this DRIP token:
  string private _dripSymbol;

  // Store the details of every participant, being the ETH they have contributed
  // (less the fee, if any), and any refund they have already received.
  mapping(address => Participant) public participant;

  /**
   * @dev {constructor}
   *
   * The constructor is not called when the contract is cloned.
   *
   * In this we just set the router address and the template contract
   * itself to initialised.
   *
   * @param router_ The address of the uniswap router on this chain.
   */
  constructor(
    address router_,
    address oracle_
  ) ERC20("Metadrop DRI Pool Token", "DRIP") {
    initialised = true;
    if (router_ == address(0)) {
      _revert(RouterCannotBeZeroAddress.selector);
    }
    if (oracle_ == address(0)) {
      _revert(MetadropOracleCannotBeAddressZero.selector);
    }
    uniswapRouter = IUniswapV2Router02(router_);
    metadropOracleAddress = oracle_;
  }

  /**
   * @dev {onlyDuringPoolPhase}
   *
   * Throws if NOT during the pool phase
   */
  modifier onlyDuringPoolPhase() {
    if (_poolPhaseStatus() != PhaseStatus.open) {
      _revert(PoolPhaseIsNotOpen.selector);
    }
    _;
  }

  /**
   * @dev {onlyAfterSuccessfulPoolPhase}
   *
   * Throws if NOT after the pool phase AND the phase succeeded
   */
  modifier onlyAfterSuccessfulPoolPhase() {
    if (_poolPhaseStatus() != PhaseStatus.succeeded) {
      _revert(PoolPhaseIsNotSucceeded.selector);
    }
    _;
  }

  /**
   * @dev {onlyAfterFailedPoolPhase}
   *
   * Throws if NOT after the pool phase AND the phase failed
   */
  modifier onlyAfterFailedPoolPhase() {
    if (_poolPhaseStatus() != PhaseStatus.failed) {
      _revert(PoolPhaseIsNotFailed.selector);
    }
    _;
  }

  /**
   * @dev {onlyWhenTokensVested}
   *
   * Throws if NOT after the token vesting date
   */
  modifier onlyWhenTokensVested() {
    if (block.timestamp < vestingEndDate()) {
      _revert(PoolVestingNotYetComplete.selector);
    }
    _;
  }

  /**
   * @dev {onlyFeeRecipient}
   *
   * Throws if NOT called by the fee recipient
   */
  modifier onlyFeeRecipient() {
    _checkFeeRecipient();
    _;
  }

  /**
   * @dev Throws if the sender is not the manager.
   */
  function _checkFeeRecipient() internal view virtual {
    if (poolFeeRecipient != _msgSender()) {
      _revert(CallerIsNotTheFeeRecipient.selector);
    }
  }

  /**
   * @dev {name}
   *
   * Returns the name of the token.
   */
  function name() public view override returns (string memory) {
    return _dripName;
  }

  /**
   * @dev {symbol}
   *
   * Returns the symbol of the token, usually a shorter version of the name.
   */
  function symbol() public view override returns (string memory) {
    return _dripSymbol;
  }

  /**
   * @dev {driType}
   *
   * Returns the type of this DRI pool
   */
  function driType() external view returns (DRIPoolType) {
    return _driPoolType;
  }

  /**
   * @dev {initialiseDRIP}
   *
   * Initalise configuration on a new minimal proxy clone
   *
   * @param poolParams_ bytes parameter object that will be decoded into configuration items.
   * @param name_ the name of the associated ERC20 token
   * @param symbol_ the symbol of the associated ERC20 token
   */
  function initialiseDRIP(
    bytes calldata poolParams_,
    string calldata name_,
    string calldata symbol_
  ) external {
    _initialisationControl();

    _setNameAndSymbol(name_, symbol_);

    _processPoolParams(poolParams_);

    emit DRIPoolCreatedAndInitialised();
  }

  /**
   * @dev {_initialisationControl}
   *
   * Check and set the initialistion boolean
   */
  function _initialisationControl() internal {
    if (initialised) {
      _revert(AlreadyInitialised.selector);
    }
    initialised = true;
  }

  /**
   * @dev {_setNameAndSymbol}
   *
   * Set the name and the symbol
   *
   * @param name_ The name of token
   * @param symbol_ The symbol token
   */
  function _setNameAndSymbol(
    string calldata name_,
    string calldata symbol_
  ) internal {
    _dripName = string.concat(name_, " - Metadrop Launch Pool Token");
    _dripSymbol = _getDripSymbol(symbol_);
  }

  /**
   * @dev Get the drip symbol, being the first six chars of the token symbol + '-DRIP'
   * We get just the first six chars as metamask has a default limit of 11 chars per token
   * symbol. You can get around this by manually editing the symbol when adding the token,
   * but it seems prudent to avoid the user having to do this.
   *
   * @param erc20Symbol_ The symbol of the ERC20
   * @return dripSymbol_ the symbol of our DRIP token
   */
  function _getDripSymbol(
    string memory erc20Symbol_
  ) internal pure returns (string memory dripSymbol_) {
    bytes memory erc20SymbolBytes = bytes(erc20Symbol_);

    if (erc20SymbolBytes.length < 6) {
      return string(abi.encodePacked(erc20SymbolBytes, "-DRIP"));
    } else {
      bytes memory result = new bytes(6);
      for (uint i = 0; i < 6; i++) {
        result[i] = erc20SymbolBytes[i];
      }
      return string(abi.encodePacked(result, "-DRIP"));
    }
  }

  /**
   * @dev {_processPoolParams}
   *
   * Validate and set pool parameters
   *
   * @param poolParams_ bytes parameter object that will be decoded into configuration items.
   */
  function _processPoolParams(bytes calldata poolParams_) internal {
    ERC20PoolParameters memory poolParams = _validatePoolParams(poolParams_);

    _setPoolParams(poolParams);
  }

  /**
   * @dev Decode and validate pool parameters
   *
   * @param poolParams_ Bytes parameters
   * @return poolParamsDecoded_ the decoded pool params
   */
  function _validatePoolParams(
    bytes calldata poolParams_
  ) internal pure returns (ERC20PoolParameters memory poolParamsDecoded_) {
    poolParamsDecoded_ = abi.decode(poolParams_, (ERC20PoolParameters));

    if (poolParamsDecoded_.poolPerAddressMaxETH > type(uint80).max) {
      _revert(ParamTooLargePerAddressMax.selector);
    }
    if (poolParamsDecoded_.poolMaxETH > type(uint96).max) {
      _revert(ParamTooLargePoolMaxETH.selector);
    }
    if (poolParamsDecoded_.poolPerTransactionMinETH > type(uint64).max) {
      _revert(ParamTooLargePoolPerTxnMinETH.selector);
    }
    if (poolParamsDecoded_.poolStartDate > type(uint32).max) {
      _revert(ParamTooLargeStartDate.selector);
    }
    if (poolParamsDecoded_.poolEndDate > type(uint32).max) {
      _revert(ParamTooLargeEndDate.selector);
    }
    if (poolParamsDecoded_.poolType > 1) {
      _revert(UnrecognisedType.selector);
    }
    if (poolParamsDecoded_.poolContributionFeeBasisPoints > type(uint16).max) {
      _revert(ParamTooLargeContributionFee.selector);
    }
    if (poolParamsDecoded_.poolVestingInSeconds > type(uint32).max) {
      _revert(ParamTooLargeVestingDays.selector);
    }
    if (poolParamsDecoded_.poolSupply > type(uint120).max) {
      _revert(ParamTooLargePoolSupply.selector);
    }
    if (poolParamsDecoded_.poolMinETH > type(uint96).max) {
      _revert(ParamTooLargeMinETH.selector);
    }
    if (poolParamsDecoded_.poolMaxInitialBuy > type(uint96).max) {
      _revert(ParamTooLargeMaxInitialBuy.selector);
    }
    if (poolParamsDecoded_.poolMaxInitialLiquidity > type(uint96).max) {
      _revert(ParamTooLargeMaxInitialLiquidity.selector);
    }
    if (
      poolParamsDecoded_.poolMaxInitialBuy != 0 &&
      poolParamsDecoded_.poolMinETH > poolParamsDecoded_.poolMaxInitialBuy
    ) {
      _revert(MinETHCannotExceedMaxBuy.selector);
    }
    if (
      poolParamsDecoded_.poolMaxInitialLiquidity != 0 &&
      poolParamsDecoded_.poolMinETH > poolParamsDecoded_.poolMaxInitialLiquidity
    ) {
      _revert(MinETHCannotExceedMaxLiquidity.selector);
    }
    return (poolParamsDecoded_);
  }

  /**
   * @dev {_setPoolParams}
   *
   * Load the pool params to storage
   *
   * @param poolParamsDecoded_ the decoded pool params
   */
  function _setPoolParams(
    ERC20PoolParameters memory poolParamsDecoded_
  ) internal {
    _driPoolType = DRIPoolType(poolParamsDecoded_.poolType);
    poolStartDate = uint32(poolParamsDecoded_.poolStartDate);
    poolEndDate = uint32(poolParamsDecoded_.poolEndDate);
    poolMaxETH = uint96(poolParamsDecoded_.poolMaxETH);
    poolMinETH = uint96(poolParamsDecoded_.poolMinETH);
    poolPerAddressMaxETH = uint80(poolParamsDecoded_.poolPerAddressMaxETH);
    poolVestingInSeconds = uint32(poolParamsDecoded_.poolVestingInSeconds);
    supplyInThePool = uint120(
      poolParamsDecoded_.poolSupply * (10 ** decimals())
    );
    poolPerTransactionMinETH = uint64(
      poolParamsDecoded_.poolPerTransactionMinETH
    );
    poolContributionFeeBasisPoints = uint16(
      poolParamsDecoded_.poolContributionFeeBasisPoints
    );
    maxInitialBuy = uint96(poolParamsDecoded_.poolMaxInitialBuy);
    maxInitialLiquidity = uint96(poolParamsDecoded_.poolMaxInitialLiquidity);
    poolContributionFeeBasisPoints = uint16(
      poolParamsDecoded_.poolContributionFeeBasisPoints
    );
    poolFeeRecipient = poolParamsDecoded_.poolFeeRecipient;
  }

  /**
   * @dev {supplyForLP}
   *
   * Convenience function to return the LP supply from the ERC-20 token contract.
   *
   * @return supplyForLP_ The total supply for LP creation.
   */
  function supplyForLP() public view returns (uint256 supplyForLP_) {
    return (createdERC20.balanceOf(address(createdERC20)));
  }

  /**
   * @dev {poolPhaseStatus}
   *
   * Convenience function to return the pool status in string format.
   *
   * @return poolPhaseStatus_ The pool phase status as a string
   */
  function poolPhaseStatus()
    external
    view
    returns (string memory poolPhaseStatus_)
  {
    // BEFORE the pool phase has started:
    if (_poolPhaseStatus() == PhaseStatus.before) {
      return ("before");
    }

    // AFTER the pool phase has ended successfully:
    if (_poolPhaseStatus() == PhaseStatus.succeeded) {
      return ("succeeded");
    }

    // AFTER the pool phase has ended but failed:
    if (_poolPhaseStatus() == PhaseStatus.failed) {
      return ("failed");
    }

    // DURING the pool phase:
    return ("open");
  }

  /**
   * @dev {_poolPhaseStatus}
   *
   * Internal function to return the pool phase status as an enum
   *
   * @return poolPhaseStatus_ The pool phase status as an enum
   */
  function _poolPhaseStatus()
    internal
    view
    returns (PhaseStatus poolPhaseStatus_)
  {
    // BEFORE the pool phase has started:
    if (block.timestamp < poolStartDate) {
      return (PhaseStatus.before);
    }

    // AFTER the pool phase has ended:
    if (block.timestamp >= poolEndDate) {
      if (poolIsAboveMinimum()) {
        // Successful:
        return (PhaseStatus.succeeded);
      } else {
        // Failed:
        return (PhaseStatus.failed);
      }
    }

    // DURING the pool phase:
    return (PhaseStatus.open);
  }

  /**
   * @dev {vestingEndDate}
   *
   * The vesting end date, being the end of the pool phase plus number of days vesting, if any.
   *
   * @return vestingEndDate_ The vesting end date as a timestamp
   */
  function vestingEndDate() public view returns (uint256 vestingEndDate_) {
    return poolEndDate + poolVestingInSeconds;
  }

  /**
   * @dev Return if the pool total has exceeded the minimum:
   *
   * @return poolIsAboveMinimum_ If the pool is above the minimum (or not)
   */
  function poolIsAboveMinimum() public view returns (bool poolIsAboveMinimum_) {
    return totalETHContributed() >= poolMinETH;
  }

  /**
   * @dev Return if the pool is at the maximum.
   *
   * @return poolIsAtMaximum_ If the pool is at the maximum ETH.
   */
  function poolIsAtMaximum() public view returns (bool poolIsAtMaximum_) {
    // A maximum of 0 signifies unlimited, therefore this can never be at the maximum:
    if (poolMaxETH == 0) {
      return false;
    }
    return totalETHContributed() == poolMaxETH;
  }

  /**
   * @dev Return the total ETH pooled (whether in the balance of this contract
   * or supplied as LP / token buy already).
   *
   * Note that this INCLUDES any seed ETH from the project on create.
   *
   * @return totalETHPooled_ the total ETH pooled in this contract
   */
  function totalETHPooled() public view returns (uint256 totalETHPooled_) {
    // This metric has an interesting characteristic where there can be negative ETH contributed:
    //  * The pool has failed
    //  * Fees have accumulated (but won't be paid)
    //  * All refunds have been made (or, at least, the vast majority have been made)
    //
    // We have a negative contributed amount because we deduct the fees still (we have to, in order
    // to see that the pool has failed). This then leaved the pooled amount lower than the deductions.
    //
    // We therefore have the concept that totalETHPooled must always be 0 or higher.
    uint256 positiveItems = address(this).balance +
      totalETHFundedToLPAndTokenBuy +
      totalExcessETHRefunded;

    if (positiveItems > accumulatedFees) {
      return positiveItems - accumulatedFees;
    } else {
      return (0);
    }
  }

  /**
   * @dev Return the total ETH contributed (whether in the balance of this contract
   * or supplied as LP already).
   *
   * Note that this EXCLUDES any seed ETH from the project on create.
   *
   * @return totalETHContributed_ the total ETH pooled in this contract
   */
  function totalETHContributed()
    public
    view
    returns (uint256 totalETHContributed_)
  {
    // This metric has an interesting characteristic where there can be negative ETH contributed:
    //  * The pool has failed
    //  * There is seed ETH provided
    //  * Fees have accumulated (but won't be paid)
    //  * All normal refunds have been made (or, at least, the vast majority have been made)
    //    leaving just the seed ETH (and maybe a small balance of normal refunds)
    //
    // We have a negative contributed amount because the deduct the fees still (we have to, in order
    // to see that the pool has failed). This then leaved the contribution amount lower than the seed
    // ETH amount.
    //
    // We therefore have the concept that totalETHContributed must always be 0 or higher.
    //
    if (projectSeedContributionETH < totalETHPooled()) {
      return totalETHPooled() - projectSeedContributionETH;
    } else {
      return (0);
    }
  }

  /**
   * @dev Return the total ETH pooled that is in excess of requirements
   *
   * @return totalExcessETHPooled_ the total ETH pooled in this contract
   * that is not needed for the initial lp / buy
   */
  function totalExcessETHPooled()
    public
    view
    returns (uint256 totalExcessETHPooled_)
  {
    if (_driPoolType == DRIPoolType.fundingLP) {
      if (maxInitialLiquidityExceeded()) {
        totalExcessETHPooled_ = totalETHContributed() - maxInitialLiquidity;
      } else {
        totalExcessETHPooled_ = 0;
      }
    } else {
      if (maxInitialBuyExceeded()) {
        totalExcessETHPooled_ = totalETHContributed() - maxInitialBuy;
      } else {
        totalExcessETHPooled_ = 0;
      }
    }

    return totalExcessETHPooled_;
  }

  /**
   * @dev Return the ETH pooled for this recipient
   *
   * @return participantETHPooled_ the total ETH pooled for this address
   */
  function participantETHPooled(
    address participant_
  ) public view returns (uint256 participantETHPooled_) {
    return participant[participant_].contribution;
  }

  /**
   * @dev Return the excess ETH already refunded for this recipient
   *
   * @return participantExcessETHRefunded_ the total excess ETH refunded for this participant
   */
  function participantExcessETHRefunded(
    address participant_
  ) public view returns (uint256 participantExcessETHRefunded_) {
    return participant[participant_].excessRefunded;
  }

  /**
   * @dev Return the excess refund currently owing for the query address
   *
   * Note that this EXCLUDES any seed ETH from the project on create.
   *
   * @return participantExcessRefund_ the total ETH pooled in this contract
   */
  function participantExcessRefundAvailable(
    address participant_
  ) public view returns (uint256 participantExcessRefund_) {
    if (totalETHContributed() == 0) {
      return 0;
    }
    return
      ((totalExcessETHPooled() * participant[participant_].contribution) /
        totalETHContributed()) - participant[participant_].excessRefunded;
  }

  /**
   * @dev Return if the max initial buy has been exceeded
   *
   * @return maxInitialBuyExceeded_
   */
  function maxInitialBuyExceeded()
    public
    view
    returns (bool maxInitialBuyExceeded_)
  {
    return maxInitialBuy != 0 && maxInitialBuy < totalETHContributed();
  }

  /**
   * @dev Return if the max initial lp funding has been exceeded
   *
   * @return maxInitialLiquidityExceeded_
   */
  function maxInitialLiquidityExceeded()
    public
    view
    returns (bool maxInitialLiquidityExceeded_)
  {
    return
      maxInitialLiquidity != 0 && maxInitialLiquidity < totalETHContributed();
  }

  /**
   * @dev {loadERC20AddressAndSeedETH}
   *
   * Load the target ERC-20 address. This is called by the factory in the same transaction as the clone
   * is instantiated
   *
   * @param createdERC20_ The ERC-20 address
   * @param poolCreator_ The creator of this pool
   */
  function loadERC20AddressAndSeedETH(
    address createdERC20_,
    address poolCreator_
  ) external payable {
    if (address(createdERC20) != address(0)) {
      _revert(AddressAlreadySet.selector);
    }

    // If there is ETH on this call then it is the ETH amount that the project team
    // is seeding into the pool. This seed amount does NOT mint DRIP token to the team,
    // as will be the case with any contributions to an open pool.
    //
    // IN A FUNDING LP POOL:
    //
    // It will be included in the ETH paired with the token when the pool closes,
    // if it closes above the minimum contribution threshold.
    //
    // In the event that the pool closes below the minimum contribution threshold the project
    // team will be able to claim a refund of the seeded amount, in just the same way
    // that contributors can get a refund of ETH when the pool closes below the minimum.
    //
    // IN AN INITIAL BUY POOL:
    //
    // When the pool closes this contract will fund the liquidity using the ETH that the team
    // has provided for liquicity and them IMMEDIATELY make the intitial purchase
    //
    // Tokens for users to claim are then held on this contract in the same way as for a liquidity pool

    // If this is an initial buy pool then we must have some seed ETH from the project as this is what
    // we will use to load liquidity. The ETH contributed to this contract is used as an initial buy.
    if (_driPoolType == DRIPoolType.initialBuy && msg.value == 0) {
      _revert(PoolMustBeSeededWithETHForInitialLiquidity.selector);
    }

    if (msg.value > 0) {
      if (msg.value > type(uint96).max) {
        _revert(ValueExceedsMaximum.selector);
      }
      projectSeedContributionETH = uint96(msg.value);
      projectSeedContributionAddress = poolCreator_;
    }
    createdERC20 = IERC20ByMetadrop(createdERC20_);
  }

  /**
   * @dev {addToPool}
   *
   * A user calls this to contribute to the pool
   *
   * Note that we could have used the receive method for this, and processed any ETH send to the
   * contract as a contribution to the pool. We've opted for the clarity of a specific method,
   * with the recieve method reverting an unidentified ETH.
   *
   * @param signedMessage_ The signed message object
   */
  function addToPool(
    SignedDropMessageDetails calldata signedMessage_
  ) external payable onlyDuringPoolPhase {
    _verifyMessage(signedMessage_);

    uint256 poolFee;

    // Deduct the pool fee if the fee is set:
    if (poolContributionFeeBasisPoints != 0) {
      // Fee is truncated to a given dp of ETH:
      poolFee =
        (((msg.value * poolContributionFeeBasisPoints) / CONST_BP_DENOM) /
          FEE_DP_OF_ETH_FACTOR) *
        FEE_DP_OF_ETH_FACTOR;
      accumulatedFees += uint96(poolFee);
    }

    _checkLimits(msg.value);

    // Mint DRIP to the participant:
    _mint(_msgSender(), msg.value * ETH_TO_DRIP_MULTIPLIER);

    // Record their ETH contribution:
    participant[_msgSender()].contribution += uint128(msg.value - poolFee);

    if (poolIsAtMaximum()) {
      poolEndDate = uint32(block.timestamp);
    }

    // Emit the event:
    emit AddToPool(_msgSender(), msg.value, poolFee);
  }

  /**
   * @dev function {_verifyMessage}
   *
   * Check the signature and expiry of the passed message
   *
   * @param signedMessage_ The signed message object
   */
  function _verifyMessage(
    SignedDropMessageDetails calldata signedMessage_
  ) internal view {
    // Check that this signature is from the oracle signer:
    if (
      !_validSignature(
        signedMessage_.messageHash,
        signedMessage_.messageSignature
      )
    ) {
      _revert(InvalidOracleSignature.selector);
    }

    // Check that the signature has not expired:
    unchecked {
      if (
        (signedMessage_.messageTimeStamp + MSG_VALIDITY_SECONDS) <
        block.timestamp
      ) {
        _revert(OracleSignatureHasExpired.selector);
      }
    }

    // Check that the message is from this sender and for this amount:
    if (
      createMessageHash(_msgSender(), msg.value) != signedMessage_.messageHash
    ) {
      _revert(PassedConfigDoesNotMatchApproved.selector);
    }
  }

  /**
   * @dev function {_validSignature}
   *
   * Checks the the signature on the signed message is from the metadrop oracle
   *
   * @param messageHash_ The message hash signed by the trusted oracle signer. This will be the
   * keccack256 hash of received data about this token.
   * @param messageSignature_ The signed message from the backend oracle signer for validation.
   * @return messageIsValid_ If the message is valid (or not)
   */
  function _validSignature(
    bytes32 messageHash_,
    bytes memory messageSignature_
  ) internal view returns (bool messageIsValid_) {
    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash_)
    );

    // Check the signature is valid:
    return (
      SignatureChecker.isValidSignatureNow(
        metadropOracleAddress,
        ethSignedMessageHash,
        messageSignature_
      )
    );
  }

  /**
   * @dev function {createMessageHash}
   *
   * Create the message hash
   *
   * @param sender_ The sender of the transcation
   * @param value_ The value of the transaction
   * @return messageHash_ The hash for the signed message
   */
  function createMessageHash(
    address sender_,
    uint256 value_
  ) public pure returns (bytes32 messageHash_) {
    return (keccak256(abi.encodePacked(sender_, value_)));
  }

  /**
   * @dev {_checkLimits}
   *
   * Check limits that apply to additions to the pool.
   *
   * @param ethValue_ The value of the ETH being contributed.
   */
  function _checkLimits(uint256 ethValue_) internal view {
    // Check the overall pool limit:
    if (poolMaxETH > 0 && (totalETHContributed() > poolMaxETH)) {
      _revert(AdditionToPoolWouldExceedPoolCap.selector);
    }

    // Check the per address limit:
    if (
      poolPerAddressMaxETH > 0 &&
      (balanceOf(_msgSender()) + (ethValue_ * ETH_TO_DRIP_MULTIPLIER) >
        (poolPerAddressMaxETH * ETH_TO_DRIP_MULTIPLIER))
    ) {
      _revert(AdditionToPoolWouldExceedPerAddressCap.selector);
    }

    // Check the contribution meets the minimium contribution size:
    if (ethValue_ < poolPerTransactionMinETH) {
      _revert(AdditionToPoolIsBelowPerTransactionMinimum.selector);
    }
  }

  /**
   * @dev {claimFromPool}
   *
   * A user calls this to burn their DRIP and claim their ERC-20 tokens
   *
   */
  function claimFromPool()
    external
    onlyAfterSuccessfulPoolPhase
    onlyWhenTokensVested
  {
    if (_driPoolType == DRIPoolType.initialBuy && supplyInThePool <= 0) {
      _revert(InitialLiquidityNotYetAdded.selector);
    }

    uint256 holdersDRIP = balanceOf(_msgSender());

    // Calculate the holders share of the pooled token:
    uint256 holdersClaim = ((supplyInThePool * holdersDRIP) / totalSupply());

    // If they are getting no tokens, there is nothing to do here:
    if (holdersClaim == 0) {
      _revert(NothingToClaim.selector);
    }

    // Burn the holders DRIP to the dead address. We do this so that the totalSupply()
    // figure remains constant allowing us to calculate subsequent shares of the total
    // ERC20 pool
    _burnToDead(_msgSender(), holdersDRIP);

    // Send them their createdERC20 token:
    createdERC20.safeTransfer(_msgSender(), holdersClaim);

    uint256 ethToRefundClaimer = _processExcessRefund(_msgSender());

    // Emit the event:
    emit ClaimFromPool(
      _msgSender(),
      holdersDRIP,
      holdersClaim,
      ethToRefundClaimer
    );
  }

  /**
   * @dev {refundExcess}
   *
   * Can be called at any time by a participant to claim and ETH refund of any
   * ETH that will not be used to either fund the pool or for an initial buy
   *
   */
  function refundExcess() external {
    uint256 ethToRefundClaimer = _processExcessRefund(_msgSender());

    if (ethToRefundClaimer == 0) {
      _revert(NothingToClaim.selector);
    }

    // Emit the event:
    emit ExcessRefunded(_msgSender(), ethToRefundClaimer);
  }

  /**
   * @dev {_processExcessRefund}
   *
   * Unified processing of excess refund
   *
   * @param participant_ The address being refunded.
   * @return ethToRefundParticipant_ The amount of ETH refunded.
   */
  function _processExcessRefund(
    address participant_
  ) internal returns (uint256 ethToRefundParticipant_) {
    if (totalExcessETHPooled() > 0) {
      ethToRefundParticipant_ = participantExcessRefundAvailable(participant_);

      if (ethToRefundParticipant_ > 0) {
        // Send them their ETH refund
        participant[participant_].excessRefunded += uint128(
          ethToRefundParticipant_
        );
        totalExcessETHRefunded += uint96(ethToRefundParticipant_);

        (bool success, ) = participant_.call{value: ethToRefundParticipant_}(
          ""
        );
        if (!success) {
          _revert(TransferFailed.selector);
        }
      }
      return (ethToRefundParticipant_);
    }
  }

  /**
   * @dev {_burnToDead}
   *
   * Burn DRIP token to the DEAD address.
   *
   * @param caller_ The address burning the token.
   * @param callersDRIP_ The amount of DRIP being burned.
   */
  function _burnToDead(address caller_, uint256 callersDRIP_) internal {
    _transfer(caller_, DEAD_ADDRESS, callersDRIP_);
  }

  /**
   * @dev {refundFromFailedPool}
   *
   * A user calls this to burn their DRIP and claim an ETH refund where the
   * minimum ETH pooled amount was not exceeded.
   *
   */
  function refundFromFailedPool() external onlyAfterFailedPoolPhase {
    // This looks for standard contributions based on balance of DRIP:
    uint256 holdersDRIP = balanceOf(_msgSender());

    // Calculate the holders share of the pooled ETH.
    uint256 refundAmount = holdersDRIP / ETH_TO_DRIP_MULTIPLIER;

    // Add on the project seed ETH amount if relevant:
    if (_msgSender() == projectSeedContributionAddress) {
      // This was a project seed contribution. We include the project seed ETH in any
      // refund to this address. We combine this with any refund they are owed
      // for a DRIP balance as it is possible (although unlikely) that the seed
      // contributor also made a standard contribution to the launch pool and minted
      // DRIP.

      // Add the seed ETH contribution to the refund amount:
      refundAmount += projectSeedContributionETH;

      // Zero out the contribution as this is being refunded:
      projectSeedContributionETH = 0;
    }

    // If they are getting no ETH, there is nothing to do here:
    if (refundAmount == 0) {
      _revert(NothingToClaim.selector);
    }

    // Burn tokens if the holder's DRIP is greater than 0. We need this check for zero
    // here as this could be a seed ETH refund:
    if (holdersDRIP > 0) {
      // Burn the holders DRIP to the dead address. We do this so that the totalSupply()
      // figure remains constant allowing us to calculate subsequent shares of the total
      // ERC20 pool
      _burnToDead(_msgSender(), holdersDRIP);
    }

    // Send them their ETH refund
    (bool success, ) = _msgSender().call{value: refundAmount}("");
    if (!success) {
      _revert(TransferFailed.selector);
    }

    // Emit the event:
    emit RefundFromFailedPool(_msgSender(), holdersDRIP, refundAmount);
  }

  /**
   * @dev {supplyLiquidity}
   *
   * When the pool phase is over this can be called to supply the pooled ETH to
   * the token contract. There it will be forwarded along with the LP supply of
   * tokens to uniswap to create the funded pair
   *
   * Note that this function can be called by anyone. While clearly it is likely
   * that this will be the project team, having this method open to anyone ensures that
   * liquidity will not be trapped in this contract if the team as unable to perform
   * this action.
   *
   * This method behaves differently depending on the pool type:
   *
   * IN A FUNDING LP POOL:
   *
   * All of the ETH held on this contract is provided to fund the LP
   *
   * IN AN INITIAL BUY POOL:
   *
   * ONLY the project supplied ETH is used to fund the liquidity. The remaining ETH
   * on this contract will fall into two possible categories:
   *
   * 1) ETH used to perform an initial token purchase immediately after the funding of
   * the LP. This will be the total remaining ETH on this contract IF that amount is
   * below the maximum initial buy amount. Otherwise it will be the max initial buy amount and the
   * remaining ETH will remain for refunds.
   *
   * 2) If the ETH on this contract is above the max initial buy amount there will be a
   * proportion of ETH remaining on this contract for refunds.
   *
   * @param lockerFee_ The ETH fee required to lock LP tokens
   *
   */
  function supplyLiquidity(
    uint256 lockerFee_
  ) external payable onlyAfterSuccessfulPoolPhase {
    // The caller can elect to send the locker fee with this call, or the locker
    // fee will automatically taken from the supplied ETH. In either scenario the only
    // acceptable values that can be passed to this method are a) 0 or b) the locker fee
    if (msg.value > 0 && msg.value != lockerFee_) {
      _revert(IncorrectPayment.selector);
    }

    uint256 ethForLiquidity;

    if (_driPoolType == DRIPoolType.fundingLP) {
      // If the locker fee was passed in it is in the balance of this contract, BUT is
      // not contributed ETH. Deduct this from the stored total:
      uint256 ethAvailableForLiquidity = totalETHPooled() - msg.value;
      if (
        maxInitialLiquidity != 0 &&
        maxInitialLiquidity < ethAvailableForLiquidity
      ) {
        ethForLiquidity = maxInitialLiquidity;
      } else {
        ethForLiquidity = ethAvailableForLiquidity;
      }
    } else {
      // For an initial buy pool this is the ETH that the project has contributed for the
      // liquidity pool setup
      ethForLiquidity = projectSeedContributionETH;
    }

    totalETHFundedToLPAndTokenBuy += uint96(ethForLiquidity);

    createdERC20.addInitialLiquidity{value: ethForLiquidity + msg.value}(
      lockerFee_,
      0,
      false
    );

    // If this is a initial buy pool we now perform the intial buy:
    if (_driPoolType == DRIPoolType.initialBuy) {
      uint256 ethAvailableForBuy = totalETHContributed();

      // We don't proceed with the initial buy if there is ZERO ETH in this pool.
      // In this instance we can't know the intention of the team, as they may
      // very well want to proceed with this token even if the pool has not
      // resulted in any pooled ETH. Note that we CANNOT reach this point in the code
      // if the team has specified a minimum ETH amount for the pool, i.e. we know that
      // the minimum ETH amount must have been ZERO to reach this position with zero
      // ETH in the pool. This is equivalent to saying that they token should proceed
      // to a funded state regardless of the performance of this pool. Therefore we
      // supply liquidity in this transation (earlier in the call stack), but do not
      // try and make an initial buy with 0 ETH as that would fail and revert.
      if (ethAvailableForBuy > 0) {
        uint256 ethForBuy;

        // If the total ETH in this contract exceeds the max initial buy, the buy we make
        // will be the max initial buy, with all excess ETH available to DRIP holders
        // as a refund on a pro-rata basis:
        if (maxInitialBuyExceeded()) {
          ethForBuy = maxInitialBuy;
        } else {
          ethForBuy = uint128(ethAvailableForBuy);
        }

        // Buy from DEX:
        address[] memory path = new address[](2);
        path[0] = address(uniswapRouter.WETH());
        path[1] = address(createdERC20);

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
          value: ethForBuy
        }(0, path, address(this), block.timestamp + 600);

        // We need to update the var supplyInThePool to the balance held at this
        // contract:
        supplyInThePool = uint120(createdERC20.balanceOf(address(this)));

        // We also need to record the ETH used in the buy:
        totalETHFundedToLPAndTokenBuy += uint96(ethForBuy);

        // Emit the event:
        emit InitialBuyMade(ethForBuy);
      }
    }

    // Emit the total pooled and the accumulated fees:
    emit PoolClosedSuccessfully(totalETHPooled(), accumulatedFees);

    // Disburse fees (if any)
    if (accumulatedFees > 0) {
      uint256 feesToDisburse = accumulatedFees;
      accumulatedFees = 0;
      (bool success, ) = poolFeeRecipient.call{value: feesToDisburse}("");
      if (!success) {
        _revert(TransferFailed.selector);
      }
    }
  }

  /**
   * @dev function {rescueETH}
   *
   * A withdraw function to allow ETH to be rescued.
   *
   * Fallback safety method, only callable by the fee recipient.
   *
   * @param amount_ The amount to withdraw
   */
  function rescueETH(uint256 amount_) external onlyFeeRecipient {
    (bool success, ) = poolFeeRecipient.call{value: amount_}("");
    if (!success) {
      _revert(TransferFailed.selector);
    }
  }

  /**
   * @dev function {rescueERC20}
   *
   * A withdraw function to allow ERC20s to be rescued.
   *
   * Fallback safety method, only callable by the fee recipient.
   *
   * @param token_ The ERC20 contract
   * @param amount_ The amount to withdraw
   */
  function rescueERC20(
    address token_,
    uint256 amount_
  ) external onlyFeeRecipient {
    IERC20(token_).safeTransfer(poolFeeRecipient, amount_);
  }

  /**
   * @dev {receive}
   *
   * Revert any unidentified ETH
   *
   */
  receive() external payable {
    revert();
  }

  /**
   * @dev {fallback}
   *
   * No fallback allowed
   *
   */
  fallback() external payable {
    revert();
  }
}
