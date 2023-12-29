// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import "./IConfigStructures.sol";
import "./IERC20ConfigByMetadrop.sol";
import "./IErrors.sol";

interface IERC20DRIPoolByMetadrop is
  IConfigStructures,
  IERC20ConfigByMetadrop,
  IErrors
{
  enum PhaseStatus {
    before,
    open,
    succeeded,
    failed
  }

  struct Participant {
    uint128 contribution;
    uint128 excessRefunded;
  }

  event DRIPoolCreatedAndInitialised();

  event AddToPool(address dripHolder, uint256 ethPooled, uint256 ethFee);

  event ClaimFromPool(
    address participant,
    uint256 dripTokenBurned,
    uint256 pooledTokenClaimed,
    uint256 ethRefunded
  );

  event ExcessRefunded(address participant, uint256 ethRefunded);

  event RefundFromFailedPool(
    address participant,
    uint256 dripTokenBurned,
    uint256 ethRefunded
  );

  event InitialBuyMade(uint256 ethBuy);

  event UnexpectedTotalETHPooled(
    uint256 totalETHPooled,
    uint256 contractBalance,
    uint256 totalETHFundedToLPAndTokenBuy,
    uint256 totalExcessETHRefunded,
    uint256 projectSeedContributionETH,
    uint256 accumulatedFees
  );

  event PoolClosedSuccessfully(uint256 totalETHPooled, uint256 totalETHFee);

  /**
   * @dev {driType}
   *
   * Returns the type of this DRI pool
   */
  function driType() external view returns (DRIPoolType);

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
  ) external;

  /**
   * @dev {supplyForLP}
   *
   * Convenience function to return the LP supply from the ERC-20 token contract.
   *
   * @return supplyForLP_ The total supply for LP creation.
   */
  function supplyForLP() external view returns (uint256 supplyForLP_);

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
    returns (string memory poolPhaseStatus_);

  /**
   * @dev {vestingEndDate}
   *
   * The vesting end date, being the end of the pool phase plus number of days vesting, if any.
   *
   * @return vestingEndDate_ The vesting end date as a timestamp
   */
  function vestingEndDate() external view returns (uint256 vestingEndDate_);

  /**
   * @dev Return if the pool total has exceeded the minimum:
   *
   * @return poolIsAboveMinimum_ If the pool is above the minimum (or not)
   */
  function poolIsAboveMinimum()
    external
    view
    returns (bool poolIsAboveMinimum_);

  /**
   * @dev Return if the pool is at the maximum.
   *
   * @return poolIsAtMaximum_ If the pool is at the maximum ETH.
   */
  function poolIsAtMaximum() external view returns (bool poolIsAtMaximum_);

  /**
   * @dev Return the total ETH pooled (whether in the balance of this contract
   * or supplied as LP / token buy already).
   *
   * Note that this INCLUDES any seed ETH from the project on create.
   *
   * @return totalETHPooled_ the total ETH pooled in this contract
   */
  function totalETHPooled() external view returns (uint256 totalETHPooled_);

  /**
   * @dev Return the total ETH contributed (whether in the balance of this contract
   * or supplied as LP already).
   *
   * Note that this EXCLUDES any seed ETH from the project on create.
   *
   * @return totalETHContributed_ the total ETH pooled in this contract
   */
  function totalETHContributed()
    external
    view
    returns (uint256 totalETHContributed_);

  /**
   * @dev Return the total ETH pooled that is in excess of requirements
   *
   * @return totalExcessETHPooled_ the total ETH pooled in this contract
   * that is not needed for the initial lp / buy
   */
  function totalExcessETHPooled()
    external
    view
    returns (uint256 totalExcessETHPooled_);

  /**
   * @dev Return the ETH pooled for this recipient
   *
   * @return participantETHPooled_ the total ETH pooled for this address
   */
  function participantETHPooled(
    address participant_
  ) external view returns (uint256 participantETHPooled_);

  /**
   * @dev Return the excess ETH already refunded for this recipient
   *
   * @return participantExcessETHRefunded_ the total excess ETH refunded for this participant
   */
  function participantExcessETHRefunded(
    address participant_
  ) external view returns (uint256 participantExcessETHRefunded_);

  /**
   * @dev Return the excess refund currently owing for the query address
   *
   * Note that this EXCLUDES any seed ETH from the project on create.
   *
   * @return participantExcessRefund_ the total ETH pooled in this contract
   */
  function participantExcessRefundAvailable(
    address participant_
  ) external view returns (uint256 participantExcessRefund_);

  /**
   * @dev Return if the max initial buy has been exceeded
   *
   * @return maxInitialBuyExceeded_
   */
  function maxInitialBuyExceeded()
    external
    view
    returns (bool maxInitialBuyExceeded_);

  /**
   * @dev Return if the max initial lp funding has been exceeded
   *
   * @return maxInitialLiquidityExceeded_
   */
  function maxInitialLiquidityExceeded()
    external
    view
    returns (bool maxInitialLiquidityExceeded_);

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
  ) external payable;

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
  ) external payable;

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
  ) external pure returns (bytes32 messageHash_);

  /**
   * @dev {claimFromPool}
   *
   * A user calls this to burn their DRIP and claim their ERC-20 tokens
   *
   */
  function claimFromPool() external;

  /**
   * @dev {refundExcess}
   *
   * Can be called at any time by a participant to claim and ETH refund of any
   * ETH that will not be used to either fund the pool or for an initial buy
   *
   */
  function refundExcess() external;

  /**
   * @dev {refundFromFailedPool}
   *
   * A user calls this to burn their DRIP and claim an ETH refund where the
   * minimum ETH pooled amount was not exceeded.
   *
   */
  function refundFromFailedPool() external;

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
  function supplyLiquidity(uint256 lockerFee_) external payable;

  /**
   * @dev function {rescueETH}
   *
   * A withdraw function to allow ETH to be rescued.
   *
   * Fallback safety method, only callable by the fee recipient.
   *
   * @param amount_ The amount to withdraw
   */
  function rescueETH(uint256 amount_) external;

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
  function rescueERC20(address token_, uint256 amount_) external;
}
