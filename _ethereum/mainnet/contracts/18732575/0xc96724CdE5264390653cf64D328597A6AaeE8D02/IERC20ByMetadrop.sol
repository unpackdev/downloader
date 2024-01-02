// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import "./IConfigStructures.sol";
import "./IERC20.sol";
import "./IERC20ConfigByMetadrop.sol";
import "./IERC20Metadata.sol";

/**
 * @dev Metadrop core ERC-20 contract, interface
 */
interface IERC20ByMetadrop is
  IConfigStructures,
  IERC20,
  IERC20ConfigByMetadrop,
  IERC20Metadata
{
  event AutoSwapThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

  event ExternalCallError(uint256 identifier);

  event InitialLiquidityAdded(uint256 tokenA, uint256 tokenB, uint256 lpToken);

  event LimitsUpdated(
    uint256 oldMaxTokensPerTransaction,
    uint256 newMaxTokensPerTransaction,
    uint256 oldMaxTokensPerWallet,
    uint256 newMaxTokensPerWallet
  );

  event LiquidityLocked(uint256 lpTokens, uint256 lpLockupInDays);

  event LiquidityBurned(uint256 lpTokens);

  event LiquidityPoolCreated(address addedPool);

  event LiquidityPoolAdded(address addedPool);

  event LiquidityPoolRemoved(address removedPool);

  event MetadropTaxBasisPointsChanged(
    uint256 oldBuyBasisPoints,
    uint256 newBuyBasisPoints,
    uint256 oldSellBasisPoints,
    uint256 newSellBasisPoints
  );

  event ProjectTaxBasisPointsChanged(
    uint256 oldBuyBasisPoints,
    uint256 newBuyBasisPoints,
    uint256 oldSellBasisPoints,
    uint256 newSellBasisPoints
  );

  event RevenueAutoSwap();

  event ProjectTaxRecipientUpdated(address treasury);

  event UnlimitedAddressAdded(address addedUnlimted);

  event UnlimitedAddressRemoved(address removedUnlimted);

  event ValidCallerAdded(bytes32 addedValidCaller);

  event ValidCallerRemoved(bytes32 removedValidCaller);

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
  ) external payable;

  /**
   * @dev function {isLiquidityPool}
   *
   * Return if an address is a liquidity pool
   *
   * @param queryAddress_ The address being queried
   * @return bool The address is / isn't a liquidity pool
   */
  function isLiquidityPool(address queryAddress_) external view returns (bool);

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
    returns (address[] memory liquidityPools_);

  /**
   * @dev function {addLiquidityPool} onlyOwner
   *
   * Allows the manager to add a liquidity pool to the pool enumerable set
   *
   * @param newLiquidityPool_ The address of the new liquidity pool
   */
  function addLiquidityPool(address newLiquidityPool_) external;

  /**
   * @dev function {removeLiquidityPool} onlyOwner
   *
   * Allows the manager to remove a liquidity pool
   *
   * @param removedLiquidityPool_ The address of the old removed liquidity pool
   */
  function removeLiquidityPool(address removedLiquidityPool_) external;

  /**
   * @dev function {isUnlimited}
   *
   * Return if an address is unlimited (is not subject to per txn and per wallet limits)
   *
   * @param queryAddress_ The address being queried
   * @return bool The address is / isn't unlimited
   */
  function isUnlimited(address queryAddress_) external view returns (bool);

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
    returns (address[] memory unlimitedAddresses_);

  /**
   * @dev function {addUnlimited} onlyOwner
   *
   * Allows the manager to add an unlimited address
   *
   * @param newUnlimited_ The address of the new unlimited address
   */
  function addUnlimited(address newUnlimited_) external;

  /**
   * @dev function {removeUnlimited} onlyOwner
   *
   * Allows the manager to remove an unlimited address
   *
   * @param removedUnlimited_ The address of the old removed unlimited address
   */
  function removeUnlimited(address removedUnlimited_) external;

  /**
   * @dev function {isValidCaller}
   *
   * Return if an address is a valid caller
   *
   * @param queryHash_ The code hash being queried
   * @return bool The address is / isn't a valid caller
   */
  function isValidCaller(bytes32 queryHash_) external view returns (bool);

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
    returns (bytes32[] memory validCallerHashes_);

  /**
   * @dev function {addValidCaller} onlyOwner
   *
   * Allows the owner to add the hash of a valid caller
   *
   * @param newValidCallerHash_ The hash of the new valid caller
   */
  function addValidCaller(bytes32 newValidCallerHash_) external;

  /**
   * @dev function {removeValidCaller} onlyOwner
   *
   * Allows the owner to remove a valid caller
   *
   * @param removedValidCallerHash_ The hash of the old removed valid caller
   */
  function removeValidCaller(bytes32 removedValidCallerHash_) external;

  /**
   * @dev function {setProjectTaxRecipient} onlyOwner
   *
   * Allows the manager to set the project tax recipient address
   *
   * @param projectTaxRecipient_ New recipient address
   */
  function setProjectTaxRecipient(address projectTaxRecipient_) external;

  /**
   * @dev function {setSwapThresholdBasisPoints} onlyOwner
   *
   * Allows the manager to set the autoswap threshold
   *
   * @param swapThresholdBasisPoints_ New swap threshold in basis points
   */
  function setSwapThresholdBasisPoints(
    uint16 swapThresholdBasisPoints_
  ) external;

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
  ) external;

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
  ) external;

  /**
   * @dev function {limitsEnforced}
   *
   * Return if limits are enforced on this contract
   *
   * @return bool : they are / aren't
   */
  function limitsEnforced() external view returns (bool);

  /**
   * @dev getMetadropBuyTaxBasisPoints
   *
   * Return the metadrop buy tax basis points given the timed expiry
   */
  function getMetadropBuyTaxBasisPoints() external view returns (uint256);

  /**
   * @dev getMetadropSellTaxBasisPoints
   *
   * Return the metadrop sell tax basis points given the timed expiry
   */
  function getMetadropSellTaxBasisPoints() external view returns (uint256);

  /**
   * @dev totalBuyTaxBasisPoints
   *
   * Provide easy to view tax total:
   */
  function totalBuyTaxBasisPoints() external view returns (uint256);

  /**
   * @dev totalSellTaxBasisPoints
   *
   * Provide easy to view tax total:
   */
  function totalSellTaxBasisPoints() external view returns (uint256);

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
   * if the tax balance is above MAX_SWAP_THRESHOLD_MULTIPLE.
   *
   * Testing indicates that these calculations are safe. But given the data / code
   * interactions it remains possible that some edge case set of scenarios may cause
   * an issue with these calculations.
   *
   * This method is therefore provided as a 'fallback' option to safely distribute
   * accumulated taxes from the contract, with a direct transfer of the ERC20 tokens
   * themselves.
   */
  function distributeTaxTokens() external;

  /**
   * @dev function {rescueETH} onlyOwner
   *
   * A withdraw function to allow ETH to be rescued.
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
  function rescueETH(uint256 amount_) external;

  /**
   * @dev function {rescueERC20}
   *
   * A withdraw function to allow ERC20s (except address(this)) to be rescued.
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
  function rescueERC20(address token_, uint256 amount_) external;

  /**
   * @dev function {rescueExcessToken}
   *
   * A withdraw function to allow ERC20s from this address that are above
   * the accrued tax balance to be rescued.
   */
  function rescueExcessToken(uint256 amount_) external;

  /**
   * @dev Destroys a `value` amount of tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 value) external;

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
  function burnFrom(address account, uint256 value) external;
}
