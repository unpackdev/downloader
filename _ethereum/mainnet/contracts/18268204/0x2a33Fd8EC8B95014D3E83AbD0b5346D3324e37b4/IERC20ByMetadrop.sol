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
  struct SocialLinks {
    string linkType;
    string link;
  }

  event AutoSwapThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

  event ExternalCallError(uint256 identifier);

  event InitialLiquidityAdded(uint256 tokenA, uint256 tokenB, uint256 lpToken);

  event LinksUpdated();

  event LiquidityLocked(uint256 lpLockupInDays);

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
   * @dev function {_1___website}
   *
   * Returns the stored website address, with prefixed chars
   *
   * @return string The website address
   */
  function _1___website() external view returns (string memory);

  /**
   * @dev function {_2___twitter}
   *
   * Returns the stored twitter address, with prefixed chars
   *
   * @return string The twitter address
   */
  function _2___twitter() external view returns (string memory);

  /**
   * @dev function {_3___telegram}
   *
   * Returns the stored telegram address, with prefixed chars
   *
   * @return string The telegram address
   */
  function _3___telegram() external view returns (string memory);

  /**
   * @dev function {_4___discord}
   *
   * Returns the stored discord address, with prefixed chars
   *
   * @return string The discord address
   */
  function _4___discord() external view returns (string memory);

  /**
   * @dev function {addInitialLiquidity}
   *
   * Add initial liquidity to the uniswap pair
   *
   * @param lockerFee_ The locker fee in wei. This must match the required fee from the external locker contract.
   * @param lpLockupInDays_ The number of days to lock liquidity NOTE you can pass 0 to use the stored immutable value.
   */
  function addInitialLiquidity(
    uint256 lockerFee_,
    uint256 lpLockupInDays_
  ) external payable;

  /**
   * @dev function {updateLinks} onlyOwner
   *
   * Allows the owner to update links
   *
   * @param linkHasChanged_ a bool array, set to true where the corresponding link has been updated
   * @param links_ a string array, holds updated links
   */
  function updateLinks(
    bool[4] memory linkHasChanged_,
    string[4] memory links_
  ) external;

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
   * @dev function {addLiquidityPool} onlyManager
   *
   * Allows the manager to add a liquidity pool to the pool enumerable set
   *
   * @param newLiquidityPool_ The address of the new liquidity pool
   */
  function addLiquidityPool(address newLiquidityPool_) external;

  /**
   * @dev function {removeLiquidityPool} onlyManager
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
   * @dev function {addUnlimited} onlyManager
   *
   * Allows the manager to add an unlimited address
   *
   * @param newUnlimited_ The address of the new unlimited address
   */
  function addUnlimited(address newUnlimited_) external;

  /**
   * @dev function {removeUnlimited} onlyManager
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
   * @dev function {setProjectTaxRecipient} onlyManager
   *
   * Allows the manager to set the project tax recipient address
   *
   * @param projectTaxRecipient_ New recipient address
   */
  function setProjectTaxRecipient(address projectTaxRecipient_) external;

  /**
   * @dev function {setSwapThresholdBasisPoints} onlyManager
   *
   * Allows the manager to set the autoswap threshold
   *
   * @param swapThresholdBasisPoints_ New swap threshold in basis points
   */
  function setSwapThresholdBasisPoints(
    uint16 swapThresholdBasisPoints_
  ) external;

  /**
   * @dev function {setProjectTaxRates} onlyManager
   *
   * Change the tax rates, subject to max rate
   *
   * @param newProjectBuyTaxBasisPoints_ The new buy tax rate
   * @param newProjectSellTaxBasisPoints_ The new sell tax rate
   */
  function setProjectTaxRates(
    uint16 newProjectBuyTaxBasisPoints_,
    uint16 newProjectSellTaxBasisPoints_
  ) external;

  /**
   * @dev function {setMetadropTaxRates} onlyManager
   *
   * Change the tax rates, subject to max rate and minimum tax period.
   *
   * @param newMetadropBuyTaxBasisPoints_ The new buy tax rate
   * @param newMetadropSellTaxBasisPoints_ The new sell tax rate
   */
  function setMetadropTaxRates(
    uint16 newMetadropBuyTaxBasisPoints_,
    uint16 newMetadropSellTaxBasisPoints_
  ) external;

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
   * @dev function {withdrawETH} onlyManager
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
  function withdrawETH(uint256 amount_) external;

  /**
   * @dev function {withdrawERC20} onlyManager
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
  function withdrawERC20(address token_, uint256 amount_) external;

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
