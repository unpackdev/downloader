// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;
import "./Context.sol";
import "./EnumerableSet.sol";
import "./IERC20ByMetadrop.sol";
import "./IERC20FactoryByMetadrop.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Locker.sol";
import "./IWETH.sol";
import "./Ownable2Step.sol";
import "./Revert.sol";
import "./SafeERC20.sol";

/**
 * @dev Metadrop core ERC-20 contract
 *
 * @dev Implementation of the {IERC20} interface.
 *
 */
contract ERC20ByMetadrop is Context, IERC20ByMetadrop, Ownable2Step {
  bytes32 public constant x_META_ID_HASH =
    0x4D45544144524F504D45544144524F504D45544144524F504D45544144524F50;

  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using SafeERC20 for IERC20;

  uint256 public constant x_CONST_VERSION = 100020001000000000;
  uint256 internal constant CONST_BP_DENOM = 10000;
  uint256 internal constant CONST_ROUND_DEC = 100000000000;
  uint256 internal constant CONST_CALL_GAS_LIMIT = 50000;
  uint256 internal constant CONST_MAX_SWAP_THRESHOLD_MULTIPLE = 20;

  uint256 public immutable lpSupply;
  uint256 public immutable projectSupply;
  uint256 public immutable botProtectionDurationInSeconds;
  address public immutable metadropTaxRecipient;
  address public immutable uniswapV2Pair;
  address public immutable driPool;
  address public immutable lpOwner;
  address public immutable projectSupplyRecipient;
  address public immutable metadropFactory;
  uint256 public immutable metadropTaxPeriodInDays;
  bool internal immutable _tokenHasTax;
  IUniswapV2Locker internal immutable _tokenVault;
  IUniswapV2Router02 internal immutable _uniswapRouter;
  VaultType public immutable vaultType;

  /** @dev {Storage Slot 1} Vars read as part of transfers packed to a single
   * slot for warm reads.
   *   Slot 1:
   *      128
   *       32
   *   16 * 5
   *    8 * 2
   *   ------
   *      256
   *   ------ */
  uint128 private _totalSupply;
  uint32 public fundedDate;
  uint16 public projectBuyTaxBasisPoints;
  uint16 public projectSellTaxBasisPoints;
  uint16 public metadropBuyTaxBasisPoints;
  uint16 public metadropSellTaxBasisPoints;
  uint16 public swapThresholdBasisPoints;
  /** @dev {_autoSwapInProgress} We start with {_autoSwapInProgress} ON, as we don't want to
   * call autoswap when processing initial liquidity from this address. We turn this OFF when
   * liquidity has been loaded, and use this bool to control processing during auto-swaps
   * from that point onwards. */
  bool private _autoSwapInProgress = true;

  /** @dev {Storage Slot 2} Vars read as part of transfers packed to a single
   * slot for warm reads.
   *   Slot 1:
   *      128
   *      128
   *   ------
   *      256
   *   ------ */
  uint128 public maxTokensPerTransaction;
  uint128 public maxTokensPerWallet;

  /** @dev {Storage Slot 3} Not read / written in transfers (unless autoswap taking place):
   *      160
   *       88
   *        8
   *   ------
   *      256
   *   ------ */
  address public projectTaxRecipient;
  uint88 public lpLockupInDays;
  bool public burnLPTokens;

  /** @dev {Storage Slot 4} Potentially written in transfers:
   *   Slot 3:
   *      128
   *      128
   *   ------
   *      256
   *   ------ */
  uint128 public projectTaxPendingSwap;
  uint128 public metadropTaxPendingSwap;

  /** @dev {Storage Slot 5 to n} Not read as part of transfers etc. */
  string private _name;
  string private _symbol;

  /** @dev {_balances} Addresses balances */
  mapping(address => uint256) private _balances;

  /** @dev {_allowances} Addresses allocance details */
  mapping(address => mapping(address => uint256)) private _allowances;

  /** @dev {_validCallerCodeHashes} Code hashes of callers we consider valid */
  EnumerableSet.Bytes32Set private _validCallerCodeHashes;

  /** @dev {_liquidityPools} Enumerable set for liquidity pool addresses */
  EnumerableSet.AddressSet private _liquidityPools;

  /** @dev {_unlimited} Enumerable set for addresses where limits do not apply */
  EnumerableSet.AddressSet private _unlimited;

  /**
   * @dev {constructor}
   *
   * @param integrationAddresses_ The project owner, uniswap router, unicrypt vault, metadrop factory and pool template.
   * @param baseParams_ configuration of this ERC20.
   * @param supplyParams_ Supply configuration of this ERC20.
   * @param taxParams_  Tax configuration of this ERC20
   * @param taxParams_  Launch pool configuration of this ERC20
   */
  constructor(
    address[5] memory integrationAddresses_,
    bytes memory baseParams_,
    bytes memory supplyParams_,
    bytes memory taxParams_,
    bytes memory poolParams_
  ) {
    _decodeBaseParams(integrationAddresses_[0], baseParams_);
    _uniswapRouter = IUniswapV2Router02(integrationAddresses_[1]);
    _tokenVault = IUniswapV2Locker(integrationAddresses_[2]);
    metadropFactory = (integrationAddresses_[3]);

    ERC20SupplyParameters memory supplyParams = abi.decode(
      supplyParams_,
      (ERC20SupplyParameters)
    );

    ERC20TaxParameters memory taxParams = abi.decode(
      taxParams_,
      (ERC20TaxParameters)
    );

    driPool = integrationAddresses_[4];

    ERC20PoolParameters memory poolParams;

    if (integrationAddresses_[4] != address(0)) {
      poolParams = abi.decode(poolParams_, (ERC20PoolParameters));
    }

    _processSupplyParams(supplyParams, poolParams);
    projectSupplyRecipient = supplyParams.projectSupplyRecipient;
    lpSupply = supplyParams.lpSupply * (10 ** decimals());
    projectSupply = supplyParams.projectSupply * (10 ** decimals());
    maxTokensPerWallet = uint128(
      supplyParams.maxTokensPerWallet * (10 ** decimals())
    );
    maxTokensPerTransaction = uint128(
      supplyParams.maxTokensPerTxn * (10 ** decimals())
    );
    lpLockupInDays = uint88(supplyParams.lpLockupInDays);
    botProtectionDurationInSeconds = supplyParams
      .botProtectionDurationInSeconds;
    lpOwner = supplyParams.projectLPOwner;
    burnLPTokens = supplyParams.burnLPTokens;

    _tokenHasTax = _processTaxParams(taxParams);
    metadropTaxPeriodInDays = taxParams.metadropTaxPeriodInDays;
    swapThresholdBasisPoints = uint16(taxParams.taxSwapThresholdBasisPoints);
    projectTaxRecipient = taxParams.projectTaxRecipient;
    metadropTaxRecipient = taxParams.metadropTaxRecipient;

    vaultType = VaultType.unicrypt;

    _mintBalances(
      lpSupply,
      projectSupply,
      poolParams.poolSupply * (10 ** decimals())
    );

    uniswapV2Pair = _createPair();
  }

  /**
   * @dev {onlyOwnerFactoryOrPool}
   *
   * Throws if called by any account other than the owner, factory or pool.
   */
  modifier onlyOwnerFactoryOrPool() {
    if (
      metadropFactory != _msgSender() &&
      owner() != _msgSender() &&
      driPool != _msgSender()
    ) {
      _revert(CallerIsNotFactoryProjectOwnerOrPool.selector);
    }
    _;
  }

  /**
   * @dev function {_decodeBaseParams}
   *
   * Decode NFT Parameters
   *
   * @param projectOwner_ The owner of this contract
   * @param encodedBaseParams_ The base params encoded into a bytes array
   */
  function _decodeBaseParams(
    address projectOwner_,
    bytes memory encodedBaseParams_
  ) internal {
    _transferOwnership(projectOwner_);

    (_name, _symbol) = abi.decode(encodedBaseParams_, (string, string));
  }

  /**
   * @dev function {_processSupplyParams}
   *
   * Process provided supply params
   *
   * @param erc20SupplyParameters_ The supply params
   * @param erc20PoolParameters_ The pool params
   */
  function _processSupplyParams(
    ERC20SupplyParameters memory erc20SupplyParameters_,
    ERC20PoolParameters memory erc20PoolParameters_
  ) internal {
    if (
      erc20SupplyParameters_.maxSupply !=
      (erc20SupplyParameters_.lpSupply +
        erc20SupplyParameters_.projectSupply +
        erc20PoolParameters_.poolSupply)
    ) {
      _revert(SupplyTotalMismatch.selector);
    }

    if (erc20SupplyParameters_.maxSupply > type(uint128).max) {
      _revert(MaxSupplyTooHigh.selector);
    }

    if (erc20SupplyParameters_.lpLockupInDays > type(uint88).max) {
      _revert(LPLockUpMustFitUint88.selector);
    }

    _unlimited.add(erc20SupplyParameters_.projectSupplyRecipient);
    _unlimited.add(address(this));
    _unlimited.add(address(0));
  }

  /**
   * @dev function {_processTaxParams}
   *
   * Process provided tax params
   *
   * @param erc20TaxParameters_ The tax params
   */
  function _processTaxParams(
    ERC20TaxParameters memory erc20TaxParameters_
  ) internal returns (bool tokenHasTax_) {
    /**
     * @dev We use the immutable var {_tokenHasTax} to avoid unneccesary storage writes and reads. If this
     * token does NOT have tax applied then there is no need to store or read these parameters, and we can
     * avoid this simply by checking the immutable var. Pass back the value for this var from this method.
     */
    if (
      erc20TaxParameters_.projectBuyTaxBasisPoints == 0 &&
      erc20TaxParameters_.projectSellTaxBasisPoints == 0 &&
      erc20TaxParameters_.metadropBuyTaxBasisPoints == 0 &&
      erc20TaxParameters_.metadropSellTaxBasisPoints == 0
    ) {
      return false;
    } else {
      projectBuyTaxBasisPoints = uint16(
        erc20TaxParameters_.projectBuyTaxBasisPoints
      );
      projectSellTaxBasisPoints = uint16(
        erc20TaxParameters_.projectSellTaxBasisPoints
      );
      metadropBuyTaxBasisPoints = uint16(
        erc20TaxParameters_.metadropBuyTaxBasisPoints
      );
      metadropSellTaxBasisPoints = uint16(
        erc20TaxParameters_.metadropSellTaxBasisPoints
      );
      return true;
    }
  }

  /**
   * @dev function {_mintBalances}
   *
   * Mint initial balances
   *
   * @param lpMint_ The number of tokens for liquidity
   * @param projectMint_ The number of tokens for the project treasury
   * @param poolMint_ The number of tokens for the launch pool
   */
  function _mintBalances(
    uint256 lpMint_,
    uint256 projectMint_,
    uint256 poolMint_
  ) internal {
    if (lpMint_ > 0) {
      _mint(address(this), lpMint_);
    }

    if (projectMint_ > 0) {
      _mint(projectSupplyRecipient, projectMint_);
    }

    if (poolMint_ > 0) {
      _mint(driPool, poolMint_);
    }
  }

  /**
   * @dev function {_createPair}
   *
   * Create the uniswap pair
   *
   * @return uniswapV2Pair_ The pair address
   */
  function _createPair() internal returns (address uniswapV2Pair_) {
    if (_totalSupply > 0) {
      uniswapV2Pair_ = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
        address(this),
        _uniswapRouter.WETH()
      );

      _liquidityPools.add(uniswapV2Pair_);
      emit LiquidityPoolCreated(uniswapV2Pair_);
    }
    _unlimited.add(address(_uniswapRouter));
    _unlimited.add(uniswapV2Pair_);
    return (uniswapV2Pair_);
  }

  /**
   * @dev function {addInitialLiquidity}
   *
   * Add initial liquidity to the uniswap pair
   *
   * @param vaultFee_ The vault fee in wei. This must match the required fee from the external vault contract.
   * @param lpLockupInDaysOverride_ The number of days to lock liquidity NOTE you can pass 0 to use the stored value.
   * This value is an override, and will override a stored value which is LOWER that it. If the value you are passing is
   * LOWER than the stored value the stored value will not be reduced.
   *
   * Example usage 1: When creating the coin the lpLockupInDays is set to 0. This means that on this call the
   * user can set the lockup to any value they like, as all integer values greater than zero will be used to override
   * that set in storage.
   *
   * Example usage 2: When using a DRI Pool the lockup period is set on this contract and the pool need not know anything
   * about this setting. The pool can pass back a 0 on this call and know that the existing value stored on this contract
   * will be used.
   * @param burnLPTokensOverride_ If the LP tokens should be burned (otherwise they are locked). This is an override field
   * that can ONLY be used to override a held value of FALSE with a new value of TRUE.
   *
   * Example usage 1: When creating the coin the user didn't add liquidity, or specify that the LP tokens were to be burned.
   * So burnLPTokens is held as FALSE. When they add liquidity they want to lock tokens, so they pass this in as FALSE again,
   * and it remains FALSE.
   *
   * Example usage 2: As above, but when later adding liquidity the user wants to burn the LP. So the stored value is FALSE
   * and the user passes TRUE into this method. The TRUE overrides the held value of FALSE and the tokens are burned.
   *
   * Example uusage 3: The user is using a DRI pool and they have specified on the coin creation that the LP tokens are to
   * be burned. This contract therefore holds TRUE for burnLPTokens. The DRI pool does not need to know what the user has
   * selected. It can safely pass back FALSE to this method call and the stored value of TRUE will remain, resulting in the
   * LP tokens being burned.
   */
  function addInitialLiquidity(
    uint256 vaultFee_,
    uint256 lpLockupInDaysOverride_,
    bool burnLPTokensOverride_
  ) external payable onlyOwnerFactoryOrPool {
    uint256 ethForLiquidity;

    if ((burnLPTokens == false) && (burnLPTokensOverride_ == true)) {
      burnLPTokens = true;
    }

    if (burnLPTokens) {
      if (msg.value == 0) {
        _revert(NoETHForLiquidityPair.selector);
      }
      ethForLiquidity = msg.value;
    } else {
      if (vaultFee_ >= msg.value) {
        // The amount of ETH MUST exceed the vault fee, otherwise what liquidity are we adding?
        _revert(NoETHForLiquidityPair.selector);
      }
      ethForLiquidity = msg.value - vaultFee_;
    }

    if (lpLockupInDaysOverride_ > lpLockupInDays) {
      lpLockupInDays = uint88(lpLockupInDaysOverride_);
    }

    _addInitialLiquidity(ethForLiquidity, vaultFee_);
  }

  /**
   * @dev function {_addInitialLiquidity}
   *
   * Add initial liquidity to the uniswap pair (internal function that does processing)
   *
   * @param ethAmount_ The amount of ETH passed into the call
   * @param vaultFee_ The vault fee in wei. This must match the required fee from the external vault contract.
   */
  function _addInitialLiquidity(
    uint256 ethAmount_,
    uint256 vaultFee_
  ) internal {
    // Funded date is the date of first funding. We can only add initial liquidity once. If this date is set,
    // we cannot proceed
    if (fundedDate != 0) {
      _revert(InitialLiquidityAlreadyAdded.selector);
    }

    fundedDate = uint32(block.timestamp);

    // Can only do this if this contract holds tokens:
    if (balanceOf(address(this)) == 0) {
      _revert(NoTokenForLiquidityPair.selector);
    }

    // Approve the uniswap router for an inifinite amount (max uint256)
    // This means that we don't need to worry about later incrememtal
    // approvals on tax swaps, as the uniswap router allowance will never
    // be decreased (see code in decreaseAllowance for reference)
    _approve(address(this), address(_uniswapRouter), type(uint256).max);

    // Add the liquidity:
    (uint256 amountA, uint256 amountB, uint256 lpTokens) = _uniswapRouter
      .addLiquidityETH{value: ethAmount_}(
      address(this),
      balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );

    emit InitialLiquidityAdded(amountA, amountB, lpTokens);

    // We now set this to false so that future transactions can be eligibile for autoswaps
    _autoSwapInProgress = false;

    // Are we locking, or burning?
    if (burnLPTokens) {
      _burnLiquidity(lpTokens);
    } else {
      // Lock the liquidity:
      _addLiquidityToVault(vaultFee_, lpTokens);
    }
  }

  /**
   * @dev function {_addLiquidityToVault}
   *
   * Lock initial liquidity on vault contract
   *
   * @param vaultFee_ The vault fee in wei. This must match the required fee from the external vault contract.
   * @param lpTokens_ The amount of LP tokens to be locked
   */
  function _addLiquidityToVault(uint256 vaultFee_, uint256 lpTokens_) internal {
    IERC20(uniswapV2Pair).approve(address(_tokenVault), lpTokens_);

    _tokenVault.lockLPToken{value: vaultFee_}(
      uniswapV2Pair,
      IERC20(uniswapV2Pair).balanceOf(address(this)),
      block.timestamp + (lpLockupInDays * 1 days),
      payable(address(0)),
      true,
      payable(lpOwner)
    );

    emit LiquidityLocked(lpTokens_, lpLockupInDays);
  }

  /**
   * @dev function {_burnLiquidity}
   *
   * Burn LP tokens
   *
   * @param lpTokens_ The amount of LP tokens to be locked
   */
  function _burnLiquidity(uint256 lpTokens_) internal {
    IERC20(uniswapV2Pair).transfer(address(0), lpTokens_);

    emit LiquidityBurned(lpTokens_);
  }

  /**
   * @dev function {isLiquidityPool}
   *
   * Return if an address is a liquidity pool
   *
   * @param queryAddress_ The address being queried
   * @return bool The address is / isn't a liquidity pool
   */
  function isLiquidityPool(address queryAddress_) public view returns (bool) {
    /** @dev We check the uniswapV2Pair address first as this is an immutable variable and therefore does not need
     * to be fetched from storage, saving gas if this address IS the uniswapV2Pool. We also add this address
     * to the enumerated set for ease of reference (for example it is returned in the getter), and it does
     * not add gas to any other calls, that still complete in 0(1) time.
     */
    return (queryAddress_ == uniswapV2Pair ||
      _liquidityPools.contains(queryAddress_));
  }

  /**
   * @dev function {liquidityPools}
   *
   * Returns a list of all liquidity pools
   *
   * @return liquidityPools_ a list of all liquidity pools
   */
  function liquidityPools()
    external
    view
    returns (address[] memory liquidityPools_)
  {
    return (_liquidityPools.values());
  }

  /**
   * @dev function {addLiquidityPool} onlyOwner
   *
   * Allows the manager to add a liquidity pool to the pool enumerable set
   *
   * @param newLiquidityPool_ The address of the new liquidity pool
   */
  function addLiquidityPool(address newLiquidityPool_) public onlyOwner {
    // Don't allow calls that didn't pass an address:
    if (newLiquidityPool_ == address(0)) {
      _revert(LiquidityPoolCannotBeAddressZero.selector);
    }
    // Only allow smart contract addresses to be added, as only these can be pools:
    if (newLiquidityPool_.code.length == 0) {
      _revert(LiquidityPoolMustBeAContractAddress.selector);
    }
    // Add this to the enumerated list:
    _liquidityPools.add(newLiquidityPool_);
    emit LiquidityPoolAdded(newLiquidityPool_);
  }

  /**
   * @dev function {removeLiquidityPool} onlyOwner
   *
   * Allows the manager to remove a liquidity pool
   *
   * @param removedLiquidityPool_ The address of the old removed liquidity pool
   */
  function removeLiquidityPool(
    address removedLiquidityPool_
  ) external onlyOwner {
    // Remove this from the enumerated list:
    _liquidityPools.remove(removedLiquidityPool_);
    emit LiquidityPoolRemoved(removedLiquidityPool_);
  }

  /**
   * @dev function {isUnlimited}
   *
   * Return if an address is unlimited (is not subject to per txn and per wallet limits)
   *
   * @param queryAddress_ The address being queried
   * @return bool The address is / isn't unlimited
   */
  function isUnlimited(address queryAddress_) public view returns (bool) {
    return (_unlimited.contains(queryAddress_));
  }

  /**
   * @dev function {unlimitedAddresses}
   *
   * Returns a list of all unlimited addresses
   *
   * @return unlimitedAddresses_ a list of all unlimited addresses
   */
  function unlimitedAddresses()
    external
    view
    returns (address[] memory unlimitedAddresses_)
  {
    return (_unlimited.values());
  }

  /**
   * @dev function {addUnlimited} onlyOwner
   *
   * Allows the manager to add an unlimited address
   *
   * @param newUnlimited_ The address of the new unlimited address
   */
  function addUnlimited(address newUnlimited_) external onlyOwner {
    // Add this to the enumerated list:
    _unlimited.add(newUnlimited_);
    emit UnlimitedAddressAdded(newUnlimited_);
  }

  /**
   * @dev function {removeUnlimited} onlyOwner
   *
   * Allows the manager to remove an unlimited address
   *
   * @param removedUnlimited_ The address of the old removed unlimited address
   */
  function removeUnlimited(address removedUnlimited_) external onlyOwner {
    // Remove this from the enumerated list:
    _unlimited.remove(removedUnlimited_);
    emit UnlimitedAddressRemoved(removedUnlimited_);
  }

  /**
   * @dev function {isValidCaller}
   *
   * Return if an address is a valid caller
   *
   * @param queryHash_ The code hash being queried
   * @return bool The address is / isn't a valid caller
   */
  function isValidCaller(bytes32 queryHash_) public view returns (bool) {
    return (_validCallerCodeHashes.contains(queryHash_));
  }

  /**
   * @dev function {validCallers}
   *
   * Returns a list of all valid caller code hashes
   *
   * @return validCallerHashes_ a list of all valid caller code hashes
   */
  function validCallers()
    external
    view
    returns (bytes32[] memory validCallerHashes_)
  {
    return (_validCallerCodeHashes.values());
  }

  /**
   * @dev function {addValidCaller} onlyOwner
   *
   * Allows the owner to add the hash of a valid caller
   *
   * @param newValidCallerHash_ The hash of the new valid caller
   */
  function addValidCaller(bytes32 newValidCallerHash_) external onlyOwner {
    _validCallerCodeHashes.add(newValidCallerHash_);
    emit ValidCallerAdded(newValidCallerHash_);
  }

  /**
   * @dev function {removeValidCaller} onlyOwner
   *
   * Allows the owner to remove a valid caller
   *
   * @param removedValidCallerHash_ The hash of the old removed valid caller
   */
  function removeValidCaller(
    bytes32 removedValidCallerHash_
  ) external onlyOwner {
    // Remove this from the enumerated list:
    _validCallerCodeHashes.remove(removedValidCallerHash_);
    emit ValidCallerRemoved(removedValidCallerHash_);
  }

  /**
   * @dev function {setProjectTaxRecipient} onlyOwner
   *
   * Allows the manager to set the project tax recipient address
   *
   * @param projectTaxRecipient_ New recipient address
   */
  function setProjectTaxRecipient(
    address projectTaxRecipient_
  ) external onlyOwner {
    projectTaxRecipient = projectTaxRecipient_;
    emit ProjectTaxRecipientUpdated(projectTaxRecipient_);
  }

  /**
   * @dev function {setSwapThresholdBasisPoints} onlyOwner
   *
   * Allows the manager to set the autoswap threshold
   *
   * @param swapThresholdBasisPoints_ New swap threshold in basis points
   */
  function setSwapThresholdBasisPoints(
    uint16 swapThresholdBasisPoints_
  ) external onlyOwner {
    uint256 oldswapThresholdBasisPoints = swapThresholdBasisPoints;
    swapThresholdBasisPoints = swapThresholdBasisPoints_;
    emit AutoSwapThresholdUpdated(
      oldswapThresholdBasisPoints,
      swapThresholdBasisPoints_
    );
  }

  /**
   * @dev function {setProjectTaxRates} onlyOwner
   *
   * Change the tax rates, subject to only ever decreasing
   *
   * @param newProjectBuyTaxBasisPoints_ The new buy tax rate
   * @param newProjectSellTaxBasisPoints_ The new sell tax rate
   */
  function setProjectTaxRates(
    uint16 newProjectBuyTaxBasisPoints_,
    uint16 newProjectSellTaxBasisPoints_
  ) external onlyOwner {
    uint16 oldBuyTaxBasisPoints = projectBuyTaxBasisPoints;
    uint16 oldSellTaxBasisPoints = projectSellTaxBasisPoints;

    // Cannot increase, down only
    if (newProjectBuyTaxBasisPoints_ > oldBuyTaxBasisPoints) {
      _revert(CanOnlyReduce.selector);
    }
    // Cannot increase, down only
    if (newProjectSellTaxBasisPoints_ > oldSellTaxBasisPoints) {
      _revert(CanOnlyReduce.selector);
    }

    projectBuyTaxBasisPoints = newProjectBuyTaxBasisPoints_;
    projectSellTaxBasisPoints = newProjectSellTaxBasisPoints_;

    // If either rate has been reduced to zero we set the metadrop tax rate
    // (if non zero) to zero as well:
    if (
      newProjectBuyTaxBasisPoints_ == 0 || newProjectSellTaxBasisPoints_ == 0
    ) {
      uint16 oldMetadropBuyTaxBasisPoints = metadropBuyTaxBasisPoints;
      uint16 oldMetadropSellTaxBasisPoints = metadropSellTaxBasisPoints;
      uint16 newMetadropBuyTaxBasisPoints = oldMetadropBuyTaxBasisPoints;
      uint16 newMetadropSellTaxBasisPoints = oldMetadropSellTaxBasisPoints;

      if (newProjectBuyTaxBasisPoints_ == 0) {
        newMetadropBuyTaxBasisPoints = 0;
        metadropBuyTaxBasisPoints = 0;
      }
      if (newProjectSellTaxBasisPoints_ == 0) {
        newMetadropSellTaxBasisPoints = 0;
        metadropSellTaxBasisPoints = 0;
      }

      emit MetadropTaxBasisPointsChanged(
        oldMetadropBuyTaxBasisPoints,
        newMetadropBuyTaxBasisPoints,
        oldMetadropSellTaxBasisPoints,
        newMetadropSellTaxBasisPoints
      );
    }

    emit ProjectTaxBasisPointsChanged(
      oldBuyTaxBasisPoints,
      newProjectBuyTaxBasisPoints_,
      oldSellTaxBasisPoints,
      newProjectSellTaxBasisPoints_
    );
  }

  /**
   * @dev function {setLimits} onlyOwner
   *
   * Change the limits on transactions and holdings
   *
   * @param newMaxTokensPerTransaction_ The new per txn limit
   * @param newMaxTokensPerWallet_ The new tokens per wallet limit
   */
  function setLimits(
    uint256 newMaxTokensPerTransaction_,
    uint256 newMaxTokensPerWallet_
  ) external onlyOwner {
    uint256 oldMaxTokensPerTransaction = maxTokensPerTransaction;
    uint256 oldMaxTokensPerWallet = maxTokensPerWallet;
    // Limit can only be increased:
    if (
      (oldMaxTokensPerTransaction == 0 && newMaxTokensPerTransaction_ != 0) ||
      (oldMaxTokensPerWallet == 0 && newMaxTokensPerWallet_ != 0)
    ) {
      _revert(LimitsCanOnlyBeRaised.selector);
    }
    if (
      ((newMaxTokensPerTransaction_ != 0) &&
        newMaxTokensPerTransaction_ < oldMaxTokensPerTransaction) ||
      ((newMaxTokensPerWallet_ != 0) &&
        newMaxTokensPerWallet_ < oldMaxTokensPerWallet)
    ) {
      _revert(LimitsCanOnlyBeRaised.selector);
    }

    maxTokensPerTransaction = uint128(newMaxTokensPerTransaction_);
    maxTokensPerWallet = uint128(newMaxTokensPerWallet_);

    emit LimitsUpdated(
      oldMaxTokensPerTransaction,
      newMaxTokensPerTransaction_,
      oldMaxTokensPerWallet,
      newMaxTokensPerWallet_
    );
  }

  /**
   * @dev function {limitsEnforced}
   *
   * Return if limits are enforced on this contract
   *
   * @return bool : they are / aren't
   */
  function limitsEnforced() public view returns (bool) {
    // Limits are not enforced if
    // this is renounced AND after then protection end date
    // OR prior to LP funding:
    // The second clause of 'fundedDate == 0' isn't strictly needed, since with a funded
    // date of 0 we would always expect the block.timestamp to be less than 0 plus
    // the botProtectionDurationInSeconds. But, to cover the miniscule chance of a user
    // selecting a truly enormous bot protection period, such that when added to 0 it
    // is more than the current block.timestamp, we have included this second clause. There
    // is no permanent gas overhead (the logic will be returning from the first clause after
    // the bot protection period has expired). During the bot protection period there is a minor
    // gas overhead from evaluating the fundedDate == 0 (which will be false), but this is minimal.
    if (
      (owner() == address(0) &&
        block.timestamp > fundedDate + botProtectionDurationInSeconds) ||
      fundedDate == 0
    ) {
      return false;
    } else {
      // LP has been funded AND we are within the protection period:
      return true;
    }
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the default value returned by this function, unless
   * it's overridden.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev getMetadropBuyTaxBasisPoints
   *
   * Return the metadrop buy tax basis points given the timed expiry
   */
  function getMetadropBuyTaxBasisPoints() public view returns (uint256) {
    // If we are outside the metadrop tax period this is ZERO
    if (block.timestamp > (fundedDate + (metadropTaxPeriodInDays * 1 days))) {
      return 0;
    } else {
      return metadropBuyTaxBasisPoints;
    }
  }

  /**
   * @dev getMetadropSellTaxBasisPoints
   *
   * Return the metadrop sell tax basis points given the timed expiry
   */
  function getMetadropSellTaxBasisPoints() public view returns (uint256) {
    // If we are outside the metadrop tax period this is ZERO
    if (block.timestamp > (fundedDate + (metadropTaxPeriodInDays * 1 days))) {
      return 0;
    } else {
      return metadropSellTaxBasisPoints;
    }
  }

  /**
   * @dev totalBuyTaxBasisPoints
   *
   * Provide easy to view tax total:
   */
  function totalBuyTaxBasisPoints() public view returns (uint256) {
    return projectBuyTaxBasisPoints + getMetadropBuyTaxBasisPoints();
  }

  /**
   * @dev totalSellTaxBasisPoints
   *
   * Provide easy to view tax total:
   */
  function totalSellTaxBasisPoints() public view returns (uint256) {
    return projectSellTaxBasisPoints + getMetadropSellTaxBasisPoints();
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(
    address account
  ) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(
    address to,
    uint256 amount
  ) public virtual override(IERC20) returns (bool) {
    address owner = _msgSender();
    _transfer(
      owner,
      to,
      amount,
      (isLiquidityPool(owner) || isLiquidityPool(to))
    );
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(
    address owner,
    address spender
  ) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
   * `transferFrom`. This is semantically equivalent to an infinite approval.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(
    address spender,
    uint256 amount
  ) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * NOTE: Does not update the allowance if the current allowance
   * is the maximum `uint256`.
   *
   * Requirements:
   *
   * - `from` and `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   * - the caller must have allowance for ``from``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount, (isLiquidityPool(from) || isLiquidityPool(to)));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public virtual returns (bool) {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance < subtractedValue) {
      _revert(AllowanceDecreasedBelowZero.selector);
    }
    unchecked {
      _approve(owner, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `from` to `to`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool applyTax
  ) internal virtual {
    _beforeTokenTransfer(from, to, amount);

    // Perform pre-tax validation (e.g. amount doesn't exceed balance, max txn amount)
    uint256 fromBalance = _pretaxValidationAndLimits(from, to, amount);

    // Perform autoswap if eligible
    _autoSwap(from, to);

    // Process taxes
    uint256 amountMinusTax = _taxProcessing(applyTax, to, from, amount);

    // Perform post-tax validation (e.g. total balance after post-tax amount applied)
    _posttaxValidationAndLimits(from, to, amountMinusTax);

    _balances[from] = fromBalance - amount;
    _balances[to] += amountMinusTax;

    emit Transfer(from, to, amountMinusTax);

    _afterTokenTransfer(from, to, amount);
  }

  /**
   * @dev function {_pretaxValidationAndLimits}
   *
   * Perform validation on pre-tax amounts
   *
   * @param from_ From address for the transaction
   * @param to_ To address for the transaction
   * @param amount_ Amount of the transaction
   */
  function _pretaxValidationAndLimits(
    address from_,
    address to_,
    uint256 amount_
  ) internal view returns (uint256 fromBalance_) {
    // This can't be a transfer to the liquidity pool before the funding date
    // UNLESS the from address is this contract. This ensures that the initial
    // LP funding transaction is from this contract using the supply of tokens
    // designated for the LP pool, and therefore the initial price in the pool
    // is being set as expected.
    //
    // This protects from, for example, tokens from a team minted supply being
    // paired with ETH and added to the pool, setting the initial price, BEFORE
    // the initial liquidity is added through this contract.
    if (to_ == uniswapV2Pair && from_ != address(this) && fundedDate == 0) {
      _revert(InitialLiquidityNotYetAdded.selector);
    }

    if (from_ == address(0)) {
      _revert(TransferFromZeroAddress.selector);
    }

    if (to_ == address(0)) {
      _revert(TransferToZeroAddress.selector);
    }

    fromBalance_ = _balances[from_];

    if (fromBalance_ < amount_) {
      _revert(TransferAmountExceedsBalance.selector);
    }

    if (
      limitsEnforced() &&
      (maxTokensPerTransaction != 0) &&
      ((isLiquidityPool(from_) && !isUnlimited(to_)) ||
        (isLiquidityPool(to_) && !isUnlimited(from_)))
    ) {
      // Liquidity pools aren't always going to round cleanly. This can (and does)
      // mean that a limit of 5,000 tokens (for example) will trigger on a transfer
      // of 5,000 tokens, as the transfer is actually for 5,000.00000000000000213.
      // While 4,999 will work fine, it isn't hugely user friendly. So we buffer
      // the limit with rounding decimals, which in all cases are considerably less
      // than one whole token:
      uint256 roundedLimited;

      unchecked {
        roundedLimited = maxTokensPerTransaction + CONST_ROUND_DEC;
      }

      if (amount_ > roundedLimited) {
        _revert(MaxTokensPerTxnExceeded.selector);
      }
    }

    return (fromBalance_);
  }

  /**
   * @dev function {_posttaxValidationAndLimits}
   *
   * Perform validation on post-tax amounts
   *
   * @param to_ To address for the transaction
   * @param amount_ Amount of the transaction
   */
  function _posttaxValidationAndLimits(
    address from_,
    address to_,
    uint256 amount_
  ) internal view {
    if (
      limitsEnforced() &&
      (maxTokensPerWallet != 0) &&
      !isUnlimited(to_) &&
      // If this is a buy (from a liquidity pool), we apply if the to_
      // address isn't noted as unlimited:
      (isLiquidityPool(from_) && !isUnlimited(to_))
    ) {
      // Liquidity pools aren't always going to round cleanly. This can (and does)
      // mean that a limit of 5,000 tokens (for example) will trigger on a max holding
      // of 5,000 tokens, as the transfer to achieve that is actually for
      // 5,000.00000000000000213. While 4,999 will work fine, it isn't hugely user friendly.
      // So we buffer the limit with rounding decimals, which in all cases are considerably
      // less than one whole token:
      uint256 roundedLimited;

      unchecked {
        roundedLimited = maxTokensPerWallet + CONST_ROUND_DEC;
      }

      if ((amount_ + balanceOf(to_) > roundedLimited)) {
        _revert(MaxTokensPerWalletExceeded.selector);
      }
    }
  }

  /**
   * @dev function {_taxProcessing}
   *
   * Perform tax processing
   *
   * @param applyTax_ Do we apply tax to this transaction?
   * @param to_ The reciever of the token
   * @param from_ The sender of the token
   * @param sentAmount_ The amount being send
   * @return amountLessTax_ The amount that will be recieved, i.e. the send amount minus tax
   */
  function _taxProcessing(
    bool applyTax_,
    address to_,
    address from_,
    uint256 sentAmount_
  ) internal returns (uint256 amountLessTax_) {
    amountLessTax_ = sentAmount_;
    unchecked {
      if (_tokenHasTax && applyTax_ && !_autoSwapInProgress) {
        uint256 tax;

        // on sell
        if (isLiquidityPool(to_) && totalSellTaxBasisPoints() > 0) {
          if (projectSellTaxBasisPoints > 0) {
            uint256 projectTax = ((sentAmount_ * projectSellTaxBasisPoints) /
              CONST_BP_DENOM);
            projectTaxPendingSwap += uint128(projectTax);
            tax += projectTax;
          }
          uint256 metadropSellTax = getMetadropSellTaxBasisPoints();
          if (metadropSellTax > 0) {
            uint256 metadropTax = ((sentAmount_ * metadropSellTax) /
              CONST_BP_DENOM);
            metadropTaxPendingSwap += uint128(metadropTax);
            tax += metadropTax;
          }
        }
        // on buy
        else if (isLiquidityPool(from_) && totalBuyTaxBasisPoints() > 0) {
          if (projectBuyTaxBasisPoints > 0) {
            uint256 projectTax = ((sentAmount_ * projectBuyTaxBasisPoints) /
              CONST_BP_DENOM);
            projectTaxPendingSwap += uint128(projectTax);
            tax += projectTax;
          }
          uint256 metadropBuyTax = getMetadropBuyTaxBasisPoints();
          if (metadropBuyTax > 0) {
            uint256 metadropTax = ((sentAmount_ * metadropBuyTax) /
              CONST_BP_DENOM);
            metadropTaxPendingSwap += uint128(metadropTax);
            tax += metadropTax;
          }
        }

        if (tax > 0) {
          _balances[address(this)] += tax;
          emit Transfer(from_, address(this), tax);
          amountLessTax_ -= tax;
        }
      }
    }
    return (amountLessTax_);
  }

  /**
   * @dev function {_autoSwap}
   *
   * Automate the swap of accumulated tax fees to native token
   *
   * @param from_ The sender of the token
   * @param to_ The recipient of the token
   */
  function _autoSwap(address from_, address to_) internal {
    if (_tokenHasTax) {
      uint256 contractBalance = projectTaxPendingSwap + metadropTaxPendingSwap;
      uint256 swapBalance = contractBalance;

      uint256 swapThresholdInTokens = (_totalSupply *
        swapThresholdBasisPoints) / CONST_BP_DENOM;

      if (_eligibleForSwap(from_, to_, swapBalance, swapThresholdInTokens)) {
        // Store that a swap back is in progress:
        _autoSwapInProgress = true;
        // Check if we need to reduce the amount of tokens for this swap:
        if (
          swapBalance >
          swapThresholdInTokens * CONST_MAX_SWAP_THRESHOLD_MULTIPLE
        ) {
          swapBalance =
            swapThresholdInTokens *
            CONST_MAX_SWAP_THRESHOLD_MULTIPLE;
        }
        // Perform the auto swap to native token:
        _swapTaxForNative(swapBalance, contractBalance);
        // Flag that the autoswap is complete:
        _autoSwapInProgress = false;
      }
    }
  }

  /**
   * @dev function {_eligibleForSwap}
   *
   * Is the current transfer eligible for autoswap
   *
   * @param from_ The sender of the token
   * @param to_ The recipient of the token
   * @param taxBalance_ The current accumulated tax balance
   * @param swapThresholdInTokens_ The swap threshold as a token amount
   */
  function _eligibleForSwap(
    address from_,
    address to_,
    uint256 taxBalance_,
    uint256 swapThresholdInTokens_
  ) internal view returns (bool) {
    return (taxBalance_ >= swapThresholdInTokens_ &&
      !_autoSwapInProgress &&
      !isLiquidityPool(from_) &&
      from_ != address(_uniswapRouter) &&
      to_ != address(_uniswapRouter));
  }

  /**
   * @dev function {_swapTaxForNative}
   *
   * Swap tokens taken as tax for native token
   *
   * @param swapBalance_ The current accumulated tax balance to swap
   * @param contractBalance_ The current accumulated total tax balance
   */
  function _swapTaxForNative(
    uint256 swapBalance_,
    uint256 contractBalance_
  ) internal {
    uint256 preSwapBalance = address(this).balance;

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _uniswapRouter.WETH();

    // Wrap external calls in try / catch to handle errors
    try
      _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        swapBalance_,
        0,
        path,
        address(this),
        block.timestamp + 600
      )
    {
      uint256 postSwapBalance = address(this).balance;

      uint256 balanceToDistribute = postSwapBalance - preSwapBalance;

      uint256 totalPendingSwap = projectTaxPendingSwap + metadropTaxPendingSwap;

      uint256 projectBalanceToDistribute = (balanceToDistribute *
        projectTaxPendingSwap) / totalPendingSwap;

      uint256 metadropBalanceToDistribute = (balanceToDistribute *
        metadropTaxPendingSwap) / totalPendingSwap;

      // We will not have swapped all tax tokens IF the amount was greater than the max auto swap.
      // We therefore cannot just set the pending swap counters to 0. Instead, in this scenario,
      // we must reduce them in proportion to the swap amount vs the remaining balance + swap
      // amount.
      //
      // For example:
      //  * swap Balance is 250
      //  * contract balance is 385.
      //  * projectTaxPendingSwap is 300
      //  * metadropTaxPendingSwap is 85.
      //
      // The new total for the projectTaxPendingSwap is:
      //   = 300 - ((300 * 250) / 385)
      //   = 300 - 194
      //   = 106
      // The new total for the metadropTaxPendingSwap is:
      //   = 85 - ((85 * 250) / 385)
      //   = 85 - 55
      //   = 30
      //
      if (swapBalance_ < contractBalance_) {
        projectTaxPendingSwap -= uint128(
          (projectTaxPendingSwap * swapBalance_) / contractBalance_
        );
        metadropTaxPendingSwap -= uint128(
          (metadropTaxPendingSwap * swapBalance_) / contractBalance_
        );
      } else {
        (projectTaxPendingSwap, metadropTaxPendingSwap) = (0, 0);
      }
      // Distribute to treasuries:
      bool success;
      address weth;
      uint256 gas;

      if (projectBalanceToDistribute > 0) {
        // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
        gas = (CONST_CALL_GAS_LIMIT == 0 || CONST_CALL_GAS_LIMIT > gasleft())
          ? gasleft()
          : CONST_CALL_GAS_LIMIT;

        // We limit the gas passed so that a called address cannot cause a block out of gas error:
        (success, ) = projectTaxRecipient.call{
          value: projectBalanceToDistribute,
          gas: gas
        }("");

        // If the ETH transfer fails, wrap the ETH and send it as WETH. We do this so that a called
        // address cannot cause this transfer to fail, either intentionally or by mistake:
        if (!success) {
          if (weth == address(0)) {
            weth = _uniswapRouter.WETH();
          }

          try IWETH(weth).deposit{value: projectBalanceToDistribute}() {
            try
              IERC20(address(weth)).transfer(
                projectTaxRecipient,
                projectBalanceToDistribute
              )
            {} catch {
              // Dont allow a failed external call (in this case to WETH) to stop a transfer.
              // Emit that this has occured and continue.
              emit ExternalCallError(1);
            }
          } catch {
            // Dont allow a failed external call (in this case to WETH) to stop a transfer.
            // Emit that this has occured and continue.
            emit ExternalCallError(2);
          }
        }
      }

      if (metadropBalanceToDistribute > 0) {
        // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
        gas = (CONST_CALL_GAS_LIMIT == 0 || CONST_CALL_GAS_LIMIT > gasleft())
          ? gasleft()
          : CONST_CALL_GAS_LIMIT;

        (success, ) = metadropTaxRecipient.call{
          value: metadropBalanceToDistribute,
          gas: gas
        }("");

        // If the ETH transfer fails, wrap the ETH and send it as WETH. We do this so that a called
        // address cannot cause this transfer to fail, either intentionally or by mistake:
        if (!success) {
          if (weth == address(0)) {
            weth = _uniswapRouter.WETH();
          }
          try IWETH(weth).deposit{value: metadropBalanceToDistribute}() {
            try
              IERC20(address(weth)).transfer(
                metadropTaxRecipient,
                metadropBalanceToDistribute
              )
            {} catch {
              // Dont allow a failed external call (in this case to WETH) to stop a transfer.
              // Emit that this has occured and continue.
              emit ExternalCallError(3);
            }
          } catch {
            // Dont allow a failed external call (in this case to WETH) to stop a transfer.
            // Emit that this has occured and continue.
            emit ExternalCallError(4);
          }
        }
      }
    } catch {
      // Dont allow a failed external call (in this case to uniswap) to stop a transfer.
      // Emit that this has occured and continue.
      emit ExternalCallError(5);
    }
  }

  /**
   * @dev distributeTaxTokens
   *
   * Allows the distribution of tax tokens to the designated recipient(s)
   *
   * As part of standard processing the tax token balance being above the threshold
   * will trigger an autoswap to ETH and distribution of this ETH to the designated
   * recipients. This is automatic and there is no need for user involvement.
   *
   * As part of this swap there are a number of calculations performed, particularly
   * if the tax balance is above CONST_MAX_SWAP_THRESHOLD_MULTIPLE.
   *
   * Testing indicates that these calculations are safe. But given the data / code
   * interactions it remains possible that some edge case set of scenarios may cause
   * an issue with these calculations.
   *
   * This method is therefore provided as a 'fallback' option to safely distribute
   * accumulated taxes from the contract, with a direct transfer of the ERC20 tokens
   * themselves.
   */
  function distributeTaxTokens() external {
    if (projectTaxPendingSwap > 0) {
      uint256 projectDistribution = projectTaxPendingSwap;
      projectTaxPendingSwap = 0;
      _transfer(address(this), projectTaxRecipient, projectDistribution, false);
    }

    if (metadropTaxPendingSwap > 0) {
      uint256 metadropDistribution = metadropTaxPendingSwap;
      metadropTaxPendingSwap = 0;
      _transfer(
        address(this),
        metadropTaxRecipient,
        metadropDistribution,
        false
      );
    }
  }

  /**
   * @dev function {withdrawETH} onlyOwner
   *
   * A withdraw function to allow ETH to be withdrawn by the manager
   *
   * This contract should never hold ETH. The only envisaged scenario where
   * it might hold ETH is a failed autoswap where the uniswap swap has completed,
   * the recipient of ETH reverts, the contract then wraps to WETH and the
   * wrap to WETH fails.
   *
   * This feels unlikely. But, for safety, we include this method.
   *
   * @param amount_ The amount to withdraw
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = _msgSender().call{value: amount_}("");
    if (!success) {
      _revert(TransferFailed.selector);
    }
  }

  /**
   * @dev function {withdrawERC20} onlyOwner
   *
   * A withdraw function to allow ERC20s (except address(this)) to be withdrawn.
   *
   * This contract should never hold ERC20s other than tax tokens. The only envisaged
   * scenario where it might hold an ERC20 is a failed autoswap where the uniswap swap
   * has completed, the recipient of ETH reverts, the contract then wraps to WETH, the
   * wrap to WETH succeeds, BUT then the transfer of WETH fails.
   *
   * This feels even less likely than the scenario where ETH is held on the contract.
   * But, for safety, we include this method.
   *
   * @param token_ The ERC20 contract
   * @param amount_ The amount to withdraw
   */
  function withdrawERC20(address token_, uint256 amount_) external onlyOwner {
    if (token_ == address(this)) {
      _revert(CannotWithdrawThisToken.selector);
    }
    IERC20(token_).safeTransfer(_msgSender(), amount_);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    if (account == address(0)) {
      _revert(MintToZeroAddress.selector);
    }

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += uint128(amount);
    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      _balances[account] += amount;
    }
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    if (account == address(0)) {
      _revert(BurnFromTheZeroAddress.selector);
    }

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    if (accountBalance < amount) {
      _revert(BurnExceedsBalance.selector);
    }

    unchecked {
      _balances[account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply -= uint128(amount);
    }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    if (owner == address(0)) {
      _revert(ApproveFromTheZeroAddress.selector);
    }

    if (spender == address(0)) {
      _revert(ApproveToTheZeroAddress.selector);
    }

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {Approval} event.
   */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      if (currentAllowance < amount) {
        _revert(InsufficientAllowance.selector);
      }

      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  /**
   * @dev Destroys a `value` amount of tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 value) public virtual {
    _burn(_msgSender(), value);
  }

  /**
   * @dev Destroys a `value` amount of tokens from `account`, deducting from
   * the caller's allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `value`.
   */
  function burnFrom(address account, uint256 value) public virtual {
    _spendAllowance(account, _msgSender(), value);
    _burn(account, value);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  receive() external payable {}
}
