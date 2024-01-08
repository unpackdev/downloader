// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ConfigurableRightsPool.sol";
import "./CRPFactory.sol";
import "./BRegistry.sol";
import "./IERC20DecimalsExt.sol";
import "./Ownable.sol";

import "./BConst.sol";

// LBPController is a contract that acts as a very limited deployer and controller of a Balancer CRP Liquidity Pool
// The purpose it was created instead of just using DSProxy is to have a better control over the created pool, such as:
// - All of the LBP Parameters are hardcoded into the contract, thus are independent from human or software errors
// - Stop swapping immedialy at pool deployment, so nobody can swap until the StartBlock of the LBP
// - Allow to enable swapping only at StartBlock of the LBP, by anyone (so we don't rely only on ourselves for starting the LBP - mitigates start delay because of network congestions)
// - As the LBPController is the only controller of the CRP - all code here is set in stone - thus GradualWeights are called only once in constructor and cannot be altered afterwards, etc
// - We have limited anyone to add or remove liquidity or tokens from the pool - even the owner.
// - Although we have an escape-hatch to withdraw liquidity ("but it's also disabled while the pool is running" - TODO: we shall decide on escape-hatch behavior)
// - After EndBlock - anyone can stop the pool and liquidate it - all the assets will be transferred to the LBP Owner
// - Pool is liquidated by removing the tokens
// - TODO: "BONUS: We have an integrated poker-miner, which will use arbitrage on the weight change, for the users to extract more tokens from the pool, which will also incentivise them to do Poking"

/// @title LBP Controller
/// @author oiler.network
/// @notice Helper contract used to initialize and manage the Balancer LBP and its underlying contracts such as BPool and CRP
contract LBPController is BConst, Ownable {
  /// @dev Enum-like constants used as array-indices for better readability
  uint constant TokenIndex = 0; 
  uint constant CollateralIndex = 1;

  /// @dev Number of different tokens used in the pool -> collateral and token
  uint constant ConstituentsCount = 2;

  /// @dev Balancer's Configurable Rights Pools Factory address
  address public CRPFactoryAddress;

  /// @dev Balancer's Registry address
  address public BRegistryAddress;

  /// @dev Balancer Pools Factory address
  address public BFactoryAddress;

  /// @dev Address of the token to be distributed during the LBP
  address public tokenAddress;

  /// @dev Address of the collateral token to be used during the LBP
  address public collateralAddress;

  uint public constant initialTokenAmount = 1_775_000;    // LBP initial token amount
  uint public constant initialCollateralAmount = 147_546; // LBP initial collateral amount
  uint public constant startTokenWeight = 36 * BONE;      // 90% LBP initial token weight
  uint public constant startCollateralWeight = 4 * BONE;  // 10% LBP initial collateral weight
  uint public constant endTokenWeight = 12 * BONE;        // 30% LBP end token weight
  uint public constant endCollateralWeight = 28 * BONE;   // 70% LBP end collateral weight
  uint public constant swapFee = 0.01 * 1e18;             // x% fee taken on BPool swaps - it is protecting the pool against the bot activity during the LBP. We can't use BONE here, cause this fractional multiplication is still treatened like an integer literal

  uint immutable public startBlock; // LBP start block is when Gradual Weights start to shift and pool can be started
  uint immutable public endBlock;   // LBP end block is when Gradual Weights shift stops and pool can be ended with funds withdrawal
  uint public listed;               // Listed just returns 1 when the pool is listed in the BRegistry

  // [multisig] ----owns----> [LBPCONTROLLER] ----controls----> [CRP] ----controls----> [BPOOL]
  ConfigurableRightsPool public crp;
  BPool public pool;

  ConfigurableRightsPool.PoolParams public poolParams;
  ConfigurableRightsPool.CrpParams public crpParams;
  RightsManager.Rights public rights;


  /**
   * @param _CRPFactoryAddress - Balancer CRP Factory address
   * @param _BRegistryAddress - Balancer registry address
   * @param _BFactoryAddress - Balancer Pools Factory address
   * @param _tokenAddress - Address of the token to be distributed during the LBP
   * @param _collateralAddress - Collateral address
   * @param _startBlock - LBP start block. NOTE: must be bigger than the block number in which the LBPController deployment tx will be included to the chain
   * @param _endBlock - LBP end block. NOTE: LBP duration cannot be longer than 500k blocks (2-3 months)
   * @param _owner - Address of the Multisig contract to become the owner of the LBP Controller
   */
  constructor (
      address _CRPFactoryAddress,
      address _BRegistryAddress,
      address _BFactoryAddress,
      address _tokenAddress,
      address _collateralAddress,
      uint _startBlock,
      uint _endBlock,
      address _owner
    ) Ownable() // Owner - multisig address for LBP Management and retrieval of funds after the LBP ends
  {
    require(_startBlock > block.number, "LBPController: startBlock must be in the future");
    require(_startBlock < _endBlock, "LBPController: endBlock must be greater than startBlock");
    require(_endBlock < _startBlock + 500_000, "LBPController: endBlock is too far in the future");

    Ownable.transferOwnership(_owner);
    CRPFactoryAddress = _CRPFactoryAddress;
    BRegistryAddress = _BRegistryAddress;
    BFactoryAddress = _BFactoryAddress;
    tokenAddress = _tokenAddress;
    collateralAddress = _collateralAddress;

    startBlock = _startBlock;
    endBlock = _endBlock;

    // We don't use SafeMath in this contract because the tokens are specified by us in constructor, and multiplications will not overflow
    uint initialTokenAmountWei = (10**IERC20DecimalsExt(tokenAddress).decimals()) * initialTokenAmount;
    uint initialCollateralAmountWei = (10**IERC20DecimalsExt(collateralAddress).decimals()) * initialCollateralAmount;
    
    address[] memory constituentTokens = new address[](ConstituentsCount);
    constituentTokens[TokenIndex] = tokenAddress;
    constituentTokens[CollateralIndex] = collateralAddress;

    uint[] memory tokenBalances = new uint[](ConstituentsCount);
    tokenBalances[TokenIndex] = initialTokenAmountWei;
    tokenBalances[CollateralIndex] = initialCollateralAmountWei;

    uint[] memory tokenWeights = new uint[](ConstituentsCount);
    tokenWeights[TokenIndex] = startTokenWeight;
    tokenWeights[CollateralIndex] = startCollateralWeight;
    
    poolParams = ConfigurableRightsPool.PoolParams(
      "OILLBP",         // string poolTokenSymbol;
      "OilerTokenLBP",  // string poolTokenName;
      constituentTokens,// address[] constituentTokens;
      tokenBalances,    // uint[] tokenBalances;
      tokenWeights,     // uint[] tokenWeights;
      swapFee           // uint swapFee;
    );

    crpParams = ConfigurableRightsPool.CrpParams(
      100 * BONE,          // uint initialSupply - amount of LiquidityTokens the owner of the pool gets when creating pool
      _endBlock - _startBlock - 1, // uint minimumWeightChangeBlockPeriod - (NOTE: this does not restrict poking interval) We lock the gradualUpdate time to be equal to the LBP length
      _endBlock - _startBlock - 1  // uint addTokenTimeLockInBlocks - when adding a new token (we don't do it) after creation of the pool - there's a commit period before it appears. We limit it to LBP length
    );

    rights = RightsManager.Rights(
      true, // bool canPauseSwapping; = true - so we can enable swapping only during the LBP event
      false,// bool canChangeSwapFee; = false - we cannot change fees
      true, // bool canChangeWeights; = true - to be able to do updateGradualWeights (and then poke)
      true, // bool canAddRemoveTokens; = true - so we can remove tokens to kill the pool. It also allows adding tokens, but we don't have these functions
      true, // bool canWhitelistLPs; = true - so nobody, even owner - cannot add more liquidity to the pool without whitelisting, and we don't have whitelisting functions - so Whitelist is always empty
      false // bool canChangeCap; = false - not needed, as we protect that nobody can add Liquidity by using an empty and immutable Whitelisting above already
    );
  }

  /// @notice Creates the CRP smart pool and initializes its parameters
  /// @dev Needs owner to have approved the tokens and collateral before calling this (manually and externally)
  /// @dev This LBPController becomes the Controller of the CRP and holds its liquidity tokens
  /// @dev Most of the logic was taken from https://github.com/balancer-labs/bactions-proxy/blob/master/contracts/BActions.sol
  function createSmartPool() external onlyOwner {
    require(address(crp) == address(0), "LBPController.createSmartPool, pool already exists");
    CRPFactory factory = CRPFactory(CRPFactoryAddress);

    require(poolParams.constituentTokens.length == ConstituentsCount, "ERR_LENGTH_MISMATCH");
    require(poolParams.tokenBalances.length == ConstituentsCount, "ERR_LENGTH_MISMATCH");
    require(poolParams.tokenWeights.length == ConstituentsCount, "ERR_LENGTH_MISMATCH");

    crp = factory.newCrp(BFactoryAddress, poolParams, rights);

    // Pull the tokens and collateral from Owner and Approve them to CRP
    IERC20 token = IERC20(poolParams.constituentTokens[TokenIndex]);
    require(token.transferFrom(msg.sender, address(this), poolParams.tokenBalances[TokenIndex]), "ERR_TRANSFER_FAILED");
    _safeApprove(token, address(crp), poolParams.tokenBalances[TokenIndex]);

    IERC20 collateral = IERC20(poolParams.constituentTokens[CollateralIndex]);
    require(collateral.transferFrom(msg.sender, address(this), poolParams.tokenBalances[CollateralIndex]), "ERR_TRANSFER_FAILED");
    _safeApprove(collateral, address(crp), poolParams.tokenBalances[CollateralIndex]);

    crp.createPool(
      crpParams.initialSupply,
      crpParams.minimumWeightChangeBlockPeriod,
      crpParams.addTokenTimeLockInBlocks
    );

    pool = BPool(crp.bPool());

    // Disable swapping. Can be enabled back only when LBP starts
    crp.setPublicSwap(false);
    
    // Initialize Gradual Weights shift for the whole LBP duration
    uint[] memory endWeights = new uint[](ConstituentsCount);
    endWeights[TokenIndex] = endTokenWeight;
    endWeights[CollateralIndex] = endCollateralWeight;
    crp.updateWeightsGradually(endWeights, startBlock, endBlock);
  }

  /// @notice Registers the newly created BPool into the Balancer Registry, so it appears on Balancer app website
  /// @dev Can only be called by the Owner after createSmartPool()
  function registerPool() external onlyOwner {
    require (address(pool) != address(0), "Pool doesn't exist yet");
    require (listed == 0, "Pool already registered");
    listed = BRegistry(BRegistryAddress).addPoolPair(address(pool), tokenAddress, collateralAddress);
  }

  /// @notice Starts the trading on the pool
  /// @dev Can be called by anyone after LBP start block
  function startPool() external {
    require(block.number >= startBlock, "LBP didn't start yet");
    require(block.number <= endBlock, "LBP already ended");
    crp.setPublicSwap(true);
  }
  
  /// @notice End the trading on the pool, destroys pool, and sends all funds to Owner
  /// @notice Works only if LBPController has 100% of LP Pool Tokens in it,
  /// @notice otherwise one of the removeToken() will lack them and revert the entire endPool() transaction
  /// @dev Can be called by anyone after LBP end block
  function endPool() external {
    require(block.number > endBlock, "LBP didn't end yet");
    crp.setPublicSwap(false);

    // Destroy the pool by removing all tokens, and transfer the funds to Owner
    crp.removeToken(collateralAddress);
    crp.removeToken(tokenAddress);
    IERC20 collateral = IERC20(collateralAddress);
    IERC20 token = IERC20(tokenAddress);
    uint collateralBalance = collateral.balanceOf(address(this));
    uint tokenBalance = token.balanceOf(address(this));
    collateral.transfer(owner(), collateralBalance);
    token.transfer(owner(), tokenBalance);
  }

  /// @notice Escape Hatch - in case the Owner wants to withdraw Liquidity Tokens
  /// @dev If we withdraw the LP Tokens - we cannot kill the pool with endPool() unless we put 100% of LP Tokens back.
  /// @dev All the underlying assets of bPool can be withdrawn if you have LP Tokens - via exitPool() function of CRP.
  /// @dev You cannot withdraw 100% of assets because of bPool MIN_BALANCE restriction (minimum balance of any token in bPool should be at least 1 000 000 wei).
  /// @dev But you can withdraw 99.999% of assets (BONE*99999/1000) which leaves just 1 Collateral token and 17 Tokens in bPool if called before LBP has any trades.
  /// @dev This escape hatch is deliberately not disabled during the LBP run (although we could) - just for the sake of our peace of mind - that we can withdraw anytime.
  /// @dev If you do a withdrawal (partial or full) - you can still endPool() if you put all the remaining LP Token balance back to LBPController.
 function withdrawLBPTokens() public onlyOwner {
    uint amount = crp.balanceOf(address(this));
    require(crp.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
  }

  /// @notice Poke Weights must be called at regular intervals - so the LBP price gradually changes
  /// @dev Can be called by anyone after LBP start block
  /// @dev Just calling CRP function - for simpler FrontEnd access
  function pokeWeights() external {
    crp.pokeWeights();
  }

  /// @notice Get the current weights of the LBP
  /// @return tokenWeight
  /// @return collateralWeight
  function getWeights() external view returns (uint tokenWeight, uint collateralWeight) {
    tokenWeight = pool.getNormalizedWeight(tokenAddress);
    collateralWeight = pool.getNormalizedWeight(collateralAddress);
  }

  // --- Internal ---

  /// @notice Safe approval is needed for tokens that require prior reset to 0, before setting another approval
  /// @dev Imported from https://github.com/balancer-labs/bactions-proxy/blob/master/contracts/BActions.sol
  function _safeApprove(IERC20 token, address spender, uint amount) internal {
    if (token.allowance(address(this), spender) > 0) {
      token.approve(spender, 0);
    }
      token.approve(spender, amount);
    }
}