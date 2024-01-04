// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== External Interfaces ========== */
import "./IDelegateCallProxyManager.sol";

/* ========== External Libraries ========== */
import "./SaltyLib.sol";
import "./SafeMath.sol";

/* ========== Internal Interfaces ========== */
import "./IIndexPool.sol";
import "./IPoolFactory.sol";
import "./IPoolInitializer.sol";
import "./IUnboundTokenSeller.sol";

/* ========== Internal Inheritance ========== */
import "./ScoredTokenLists.sol";
import "./ControllerConstants.sol";


/**
 * @title SigmaControllerV1
 * @author d1ll0n
 * @dev This contract is used to deploy and manage index pools.
 * It implements the methodology for rebalancing and asset selection, as well as other
 * controls such as pausing public swaps and managing fee configuration.
 *
 * ===== Pool Configuration =====
 * When an index pool is deployed, it is assigned a token list and a target size.
 *
 * The token list is the set of tokens and configuration used for selecting and weighting
 * assets, which is detailed in the documentation for the ScoredTokenLists contract.
 *
 * The size is the target number of underlying assets held by the pool, it is used to determine
 * which assets the pool will hold.
 *
 * The list's scoring strategy is used to assign weights.
 *
 * ===== Asset Selection =====
 * When the pool is deployed and when it is re-indexed, the top assets from the pool's token list
 * are selected using the index size. They are selected after sorting the token list in descending
 * order by the scores of tokens.
 *
 * ===== Rebalancing =====
 * Every week, pools are either re-weighed or re-indexed.
 * They are re-indexed once for every three re-weighs.
 * The contract owner can also force a reindex out of the normal schedule.
 *
 * Re-indexing involves re-selecting the top tokens from the pool's token list using the pool's index
 * size, assigning target weights and setting balance targets for new tokens.
 *
 * Re-weighing involves assigning target weights to only the tokens already included in the pool.
 *
 * ===== Toggling Swaps =====
 * The contract owner can set a circuitBreaker address which is allowed to toggle public swaps on index pools.
 * The contract owner also has the ability to toggle swaps.
 * 
 * ===== Fees =====
 * The contract owner can change the swap fee on index pools, and can change the premium paid on swaps in the
 * unbound token seller contracts.
 */
contract SigmaControllerV1 is ScoredTokenLists, ControllerConstants {
  using SafeMath for uint256;

/* ==========  Constants  ========== */
  // Pool factory contract
  IPoolFactory public immutable poolFactory;

  // Proxy manager & factory
  IDelegateCallProxyManager public immutable proxyManager;

  // Exit fee recipient for the index pools
  address public immutable defaultExitFeeRecipient;

/* ==========  Events  ========== */

  /** @dev Emitted when a pool is initialized and made public. */
  event PoolInitialized(
    address pool,
    address unboundTokenSeller,
    uint256 listID,
    uint256 indexSize
  );

  /** @dev Emitted when a pool and its initializer are deployed. */
  event NewPoolInitializer(
    address pool,
    address initializer,
    uint256 listID,
    uint256 indexSize
  );

/* ==========  Structs  ========== */

  /**
   * @dev Data structure with metadata about an index pool.
   *
   * Includes the number of times a pool has been either reweighed
   * or re-indexed, as well as the timestamp of the last such action.
   *
   * To reweigh or re-index, the last update must have occurred at
   * least `POOL_REWEIGH_DELAY` seconds ago.
   *
   * If `++index % REWEIGHS_BEFORE_REINDEX + 1` is 0, the pool will
   * re-index, otherwise it will reweigh.
   *
   * The struct fields are assigned their respective integer sizes so
   * that solc can pack the entire struct into a single storage slot.
   * `reweighIndex` is intended to overflow, `listID` will never
   * reach 2**16, `indexSize` is capped at 10 and it is unlikely that
   * this protocol will be in use in the year 292277026596 (unix time
   * for 2**64 - 1).
   *
   * @param initialized Whether the pool has been initialized with the
   * starting balances.
   * @param listID Token list identifier for the pool.
   * @param indexSize Number of tokens the pool should hold.
   * @param reweighIndex Number of times the pool has either re-weighed or re-indexed
   * @param lastReweigh Timestamp of last pool re-weigh or re-index
   */
  struct IndexPoolMeta {
    bool initialized;
    uint16 listID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
  }

/* ==========  Storage  ========== */

  // Default slippage rate for token seller contracts.
  uint8 public defaultSellerPremium;

  // Metadata about index pools
  mapping(address => IndexPoolMeta) public indexPoolMetadata;

  // Address able to halt swaps
  address public circuitBreaker;

/* ========== Modifiers ========== */

  modifier isInitializedPool(address poolAddress) {
    require(
      indexPoolMetadata[poolAddress].initialized,
      "ERR_POOL_NOT_FOUND"
    );
    _;
  }

  modifier onlyInitializer(address poolAddress) {
    require(
      msg.sender == computeInitializerAddress(poolAddress),
      "ERR_NOT_PRE_DEPLOY_POOL"
    );
    _;
  }

/* ==========  Constructor  ========== */

  /**
   * @dev Deploy the controller and configure the addresses
   * of the related accounts.
   */
  constructor(
    IIndexedUniswapV2Oracle uniswapOracle_,
    IPoolFactory poolFactory_,
    IDelegateCallProxyManager proxyManager_,
    address defaultExitFeeRecipient_
  )
    public
    ScoredTokenLists(uniswapOracle_)
  {
    poolFactory = poolFactory_;
    proxyManager = proxyManager_;
    defaultExitFeeRecipient = defaultExitFeeRecipient_;
  }

/* ==========  Initializer  ========== */

  /**
   * @dev Initialize the controller with the owner address and default seller premium.
   * This sets up the controller which is deployed as a singleton proxy.
   */
  function initialize(address circuitBreaker_) public {
    super.initialize();
    defaultSellerPremium = 2;
    circuitBreaker = circuitBreaker_;
  }

/* ==========  Configuration  ========== */

  /**
   * @dev Sets the default premium rate for token seller contracts.
   */
  function setDefaultSellerPremium(uint8 _defaultSellerPremium) external onlyOwner {
    require(_defaultSellerPremium > 0 && _defaultSellerPremium < 20, "ERR_PREMIUM");
    defaultSellerPremium = _defaultSellerPremium;
  }

  /**
   * @dev Sets the circuit breaker address allowed to toggle public swaps.
   */
  function setCircuitBreaker(address circuitBreaker_) external onlyOwner {
    circuitBreaker = circuitBreaker_;
  }

/* ==========  Pool Deployment  ========== */

  /**
   * @dev Deploys an index pool and a pool initializer.
   * The initializer contract is a pool with specific token
   * balance targets which gives pool tokens in the finished
   * pool to users who provide the underlying tokens needed
   * to initialize it.
   */
  function prepareIndexPool(
    uint256 listID,
    uint256 indexSize,
    uint256 initialWethValue,
    string calldata name,
    string calldata symbol
  )
    external
    onlyOwner
    returns (address poolAddress, address initializerAddress)
  {
    require(indexSize >= MIN_INDEX_SIZE, "ERR_MIN_INDEX_SIZE");
    require(indexSize <= MAX_INDEX_SIZE, "ERR_MAX_INDEX_SIZE");
    require(initialWethValue < uint144(-1), "ERR_MAX_UINT144");

    poolAddress = poolFactory.deployPool(
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(listID, indexSize))
    );
    IIndexPool(poolAddress).configure(address(this), name, symbol);

    indexPoolMetadata[poolAddress] = IndexPoolMeta({
      initialized: false,
      listID: uint16(listID),
      indexSize: uint8(indexSize),
      lastReweigh: 0,
      reweighIndex: 0
    });

    initializerAddress = proxyManager.deployProxyManyToOne(
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );

    IPoolInitializer initializer = IPoolInitializer(initializerAddress);

    // Get the initial tokens and balances for the pool.
    (address[] memory tokens, uint256[] memory balances) = getInitialTokensAndBalances(
      listID,
      indexSize,
      uint144(initialWethValue)
    );

    initializer.initialize(address(this), poolAddress, tokens, balances);

    emit NewPoolInitializer(
      poolAddress,
      initializerAddress,
      listID,
      indexSize
    );
  }

  /**
   * @dev Initializes a pool which has been deployed but not initialized
   * and transfers the underlying tokens from the initialization pool to
   * the actual pool.
   *
   * The actual weights assigned to tokens is calculated based on the
   * relative values of the acquired balances, rather than the initial
   * weights computed from the token scores.
   */
  function finishPreparedIndexPool(
    address poolAddress,
    address[] calldata tokens,
    uint256[] calldata balances
  )
    external
    onlyInitializer(poolAddress)
  {
    uint256 len = tokens.length;
    require(balances.length == len, "ERR_ARR_LEN");

    IndexPoolMeta memory meta = indexPoolMetadata[poolAddress];
    require(!meta.initialized, "ERR_INITIALIZED");

    uint256[] memory ethValues = uniswapOracle.computeAverageEthForTokens(
      tokens,
      balances,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint96[] memory denormalizedWeights = ethValues.computeDenormalizedWeights();

    address sellerAddress = proxyManager.deployProxyManyToOne(
      SELLER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );

    IIndexPool(poolAddress).initialize(
      tokens,
      balances,
      denormalizedWeights,
      msg.sender,
      sellerAddress,
      defaultExitFeeRecipient
    );

    IUnboundTokenSeller(sellerAddress).initialize(
      address(this),
      poolAddress,
      defaultSellerPremium
    );

    meta.lastReweigh = uint64(now);
    meta.initialized = true;
    indexPoolMetadata[poolAddress] = meta;

    emit PoolInitialized(
      poolAddress,
      sellerAddress,
      meta.listID,
      meta.indexSize
    );
  }

/* ==========  Pool Management  ========== */

  /**
   * @dev Sets the premium rate on `sellerAddress` to the given rate.
   */
  function updateSellerPremium(address tokenSeller, uint8 premiumPercent) external onlyOwner {
    require(premiumPercent > 0 && premiumPercent < 20, "ERR_PREMIUM");
    IUnboundTokenSeller(tokenSeller).setPremiumPercent(premiumPercent);
  }

  /**
   * @dev Sets the swap fee on an index pool.
   */
  function setSwapFee(address poolAddress, uint256 swapFee) external onlyOwner isInitializedPool(poolAddress) {
    IIndexPool(poolAddress).setSwapFee(swapFee);
  }

  /**
   * @dev Updates the minimum balance of an uninitialized token, which is
   * useful when the token's price on the pool is too low relative to
   * external prices for people to trade it in.
   */
  function updateMinimumBalance(address pool, address tokenAddress) external isInitializedPool(address(pool)) {
    IIndexPool.Record memory record = IIndexPool(pool).getTokenRecord(tokenAddress);
    require(!record.ready, "ERR_TOKEN_READY");
    uint256 poolValue = _estimatePoolValue(pool);
    uint256 minimumBalance = uniswapOracle.computeAverageTokensForEth(
      tokenAddress,
      poolValue / 100,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    IIndexPool(pool).setMinimumBalance(tokenAddress, minimumBalance);
  }

  /**
   * @dev Delegates a comp-like governance token from an index pool to a provided address.
   */
  function delegateCompLikeTokenFromPool(
    address pool,
    address token,
    address delegatee
  )
    external
    onlyOwner
    isInitializedPool(pool)
  {
    IIndexPool(pool).delegateCompLikeToken(token, delegatee);
  }

  /**
   * @dev Enable/disable public swaps on an index pool.
   * Callable by the contract owner and the `circuitBreaker` address.
   */
  function setPublicSwap(address indexPool_, bool publicSwap) external isInitializedPool(indexPool_) {
    require(
      msg.sender == circuitBreaker || msg.sender == owner(),
      "ERR_NOT_AUTHORIZED"
    );
    IIndexPool(indexPool_).setPublicSwap(publicSwap);
  }

/* ==========  Pool Rebalance Actions  ========== */

  /**
   * @dev Re-indexes a pool by setting the underlying assets to the top
   * tokens in its candidates list by score.
   */
  function reindexPool(address poolAddress) external {
    IndexPoolMeta storage meta = indexPoolMetadata[poolAddress];
    require(meta.initialized, "ERR_POOL_NOT_FOUND");
    require(
      now - meta.lastReweigh >= POOL_REWEIGH_DELAY,
      "ERR_POOL_REWEIGH_DELAY"
    );
    require(
      (++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) == 0,
      "ERR_REWEIGH_INDEX"
    );
    _reindexPool(meta, poolAddress);
  }

  function forceReindexPool(address poolAddress) external onlyOwner {
    IndexPoolMeta storage meta = indexPoolMetadata[poolAddress];
    uint8 divisor = REWEIGHS_BEFORE_REINDEX + 1;
    uint8 remainder = ++meta.reweighIndex % divisor;

    meta.reweighIndex += divisor - remainder;
    _reindexPool(meta, poolAddress);
  }

  function _reindexPool(IndexPoolMeta storage meta, address poolAddress) internal {
    uint256 size = meta.indexSize;
    (address[] memory tokens, uint256[] memory scores) = getTopTokensAndScores(meta.listID, size);
    uint256 wethValue = _estimatePoolValue(poolAddress);
    uint256 minValue = wethValue / 100;
    uint256[] memory ethValues = new uint256[](size);
    for (uint256 i = 0; i < size; i++){
      ethValues[i] = minValue;
    }
    uint256[] memory minimumBalances = uniswapOracle.computeAverageTokensForEth(
      tokens,
      ethValues,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint96[] memory denormalizedWeights = scores.computeDenormalizedWeights();

    meta.lastReweigh = uint64(now);

    IIndexPool(poolAddress).reindexTokens(
      tokens,
      denormalizedWeights,
      minimumBalances
    );
  }

  /**
   * @dev Reweighs the assets in a pool by their scores and sets the
   * desired new weights, which will be adjusted over time.
   */
  function reweighPool(address poolAddress) external {
    IndexPoolMeta memory meta = indexPoolMetadata[poolAddress];
    require(meta.initialized, "ERR_POOL_NOT_FOUND");

    require(
      now - meta.lastReweigh >= POOL_REWEIGH_DELAY,
      "ERR_POOL_REWEIGH_DELAY"
    );

    require(
      (++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) != 0,
      "ERR_REWEIGH_INDEX"
    );

    TokenList storage list = _lists[meta.listID];

    address[] memory tokens = IIndexPool(poolAddress).getCurrentDesiredTokens();
    uint256[] memory scores = IScoringStrategy(list.scoringStrategy).getTokenScores(tokens);
    uint96[] memory denormalizedWeights = scores.computeDenormalizedWeights();

    meta.lastReweigh = uint64(now);
    indexPoolMetadata[poolAddress] = meta;
    IIndexPool(poolAddress).reweighTokens(tokens, denormalizedWeights);
  }

/* ==========  Pool Queries  ========== */

  /**
   * @dev Compute the create2 address for a pool initializer.
   */
  function computeInitializerAddress(address poolAddress)
    public
    view
    returns (address initializerAddress)
  {
    initializerAddress = SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(this),
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  /**
   * @dev Compute the create2 address for a pool's unbound token seller.
   */
  function computeSellerAddress(address poolAddress)
    public
    view
    returns (address sellerAddress)
  {
    sellerAddress = SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(this),
      SELLER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  /**
   * @dev Compute the create2 address for a pool.
   */
  function computePoolAddress(uint256 listID, uint256 indexSize)
    public
    view
    returns (address poolAddress)
  {
    poolAddress = SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(poolFactory),
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(
        address(this),
        keccak256(abi.encodePacked(listID, indexSize))
      ))
    );
  }

  /**
   * @dev Queries the top `indexSize` tokens in a list from the market oracle,
   * computes their relative weights and determines the weighted balance of each
   * token to meet a specified total value.
   */
  function getInitialTokensAndBalances(
    uint256 listID,
    uint256 indexSize,
    uint256 wethValue
  )
    public
    view
    returns (
      address[] memory tokens,
      uint256[] memory balances
    )
  {
    uint256[] memory scores;
    (tokens, scores) = getTopTokensAndScores(listID, indexSize);
    uint256[] memory relativeEthValues = wethValue.computeProportionalAmounts(scores);
    balances = uniswapOracle.computeAverageTokensForEth(
      tokens,
      relativeEthValues,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint256 len = balances.length;
    for (uint256 i = 0; i < len; i++) {
      require(balances[i] >= MIN_BALANCE, "ERR_MIN_BALANCE");
    }
  }

/* ==========  Internal Pool Utility Functions  ========== */

  /**
   * @dev Estimate the total value of a pool by taking its first token's
   * "virtual balance" (balance * (totalWeight/weight)) and multiplying
   * by that token's average ether price from UniSwap.
   */
  function _estimatePoolValue(address pool) internal view returns (uint256) {
    (address token, uint256 value) = IIndexPool(pool).extrapolatePoolValueFromToken();
    return uniswapOracle.computeAverageEthForTokens(
      token,
      value,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
  }
}
