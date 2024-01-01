// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Pool.sol";

/**
 * @title Interface to MstWrapper
 */
interface IMstWrapper {
    /*--------------------------------------------------------------------------*/
    /* Errors                                                                   */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Redemption not pending
     */
    error RedemptionNotPending();

    /**
     * @notice Invalid node state
     */
    error InvalidNodeState();

    /**
     * @notice Deposit exceeds capacity
     */
    error DepositExceedsCapacity();

    /*--------------------------------------------------------------------------*/
    /* Events                                                                   */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Deposit event
     *
     * @param account Address of depositor
     * @param amount Amount deposited in underlying currency
     * @param tokens Amount of mstWrapper tokens minted
     */
    event Deposited(address indexed account, uint256 amount, uint256 tokens);

    /**
     * @notice Emitted when deposit shares are redeemed
     *
     * @param account Account
     * @param redemptionId Redemption Id
     * @param tokens mstWrapper tokens redeemed
     */
    event Redeemed(address indexed account, uint128 indexed redemptionId, uint256 tokens);

    /**
     * @notice Emitted when redeemed tokens are withdrawn
     *
     * @param account Account
     * @param tokens mstWrapper tokens withdrawn
     * @param amount Amount withdrawn in underlying currency
     */
    event Withdrawn(address indexed account, uint128 indexed redemptionId, uint256 tokens, uint256 amount);

    /*--------------------------------------------------------------------------*/
    /* Getters                                                                  */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice The pool the wrapped tick belongs to
     *
     * @return The pool
     */
    function pool() external view returns (Pool);

    /**
     * @notice The wrapped tick
     *
     * @return Tick from pool
     */
    function tick() external view returns (uint128);

    /**
     * @notice The tick's loan limit
     *
     * @return Loan limit from tick
     */
    function limit() external view returns (uint128);

    /**
     * @notice The tick's duration
     *
     * @return Duration from tick
     */
    function duration() external view returns (uint64);

    /**
     * @notice The tick's rate
     *
     * @return Rate from tick
     */
    function rate() external view returns (uint64);

    /**
     * @notice The tick wrapper capacity
     *
     * @dev This is the maximum amount of mstWrapper tokens that can be minted
     *
     * @return Capacity
     */
    function capacity() external view returns (uint256);

    /**
     * @notice Getter for withdrawal available
     *
     * @param redemptionId Redemption Id
     * @return Shares available
     * @return Amount available
     * @return Amount of pending shares ahead in queue
     */
    function withdrawalAvailable(uint128 redemptionId) external view returns (uint256, uint256, uint256);

    /**
     * @notice Get value of mstWrapper token denominated in underlying currency token
     *
     * @param amount Amount of mstWrapper tokens
     * @return Value of mstWrapper tokens in currency token
     */
    function mstTokenToUnderlying(uint256 amount) external view returns (uint256);

    /**
     * @notice Get value of underlying currency token denominated in mstWrapper tokens
     *
     * @param amount Amount of underlying currency token
     * @return Value of underlying currency token in mstWrapper tokens
     */
    function underlyingToMstToken(uint256 amount) external view returns (uint256);

    /*--------------------------------------------------------------------------*/
    /* Deposit API                                                              */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Deposit tokens into MstWrapper
     *
     * @dev A MstWrapper token is a 1:1 representation of a share of the linked
     *      tick within the linked pool.
     *
     * @param amount Deposit amount in underlying currency units
     * @param minTokensOut Minimum number of mstWrapper tokens to receive
     *
     * @return mstWrapper tokens minted
     */
    function deposit(uint256 amount, uint256 minTokensOut) external returns (uint256);

    /**
     * @notice Redeem tokens
     *
     * @param amount Amount of mstWrapper tokens to redeem
     *
     * @return RedemptionId
     */
    function redeem(uint256 amount) external returns (uint128);

    /**
     * @notice Withdraw redeemed tokens
     *
     * @dev Does not validate tokens are available for withdraw, relies on Pool
     *      to check redemption available and return 0 if not available.
     *
     * @param redemptionId RedemptionId
     *
     * @return MstWrapper Amount of underlying currency withdrawn
     */
    function withdraw(uint128 redemptionId) external returns (uint256);
}
