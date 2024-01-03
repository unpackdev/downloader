// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./CurveParameter.sol";
import "./Enums.sol";
import "./Constants.sol";

/**
 * @title   : Inverse bonding curve contract interface
 * @dev
 * @notice
 */

interface IInverseBondingCurve {
    /// EVENTS ///
    /**
     * @notice  Emitted when curve is initialized
     * @dev     Curve is initialized by deployer contract and initial parameters
     * @param   from : Which account initialized curve contract
     * @param   reserve : Initial reserve
     * @param   supply : Initial supply credit to fee owner
     * @param   initialPrice : Initial IBC token price
     * @param   parameterInvariant : Parameter invariant which won't change during buy/sell: Reserve/ (Supply ** utilization)
     */
    event CurveInitialized(
        address indexed from,
        address indexed reserveTokenAddress,
        uint256 reserve,
        uint256 supply,
        uint256 initialPrice,
        uint256 parameterInvariant
    );

    /**
     * @notice  Emitted when new LP position added
     * @dev     Virtual credited IBC token is assigned to LP
     * @param   from : Account to create LP position
     * @param   recipient : Account to receive LP position and LP reward
     * @param   amountIn : Reserve amount
     * @param   amountOut : LP token amount
     * @param   newParameterInvariant : New parameter invariant after LP added
     */
    event LiquidityAdded(
        address indexed from, address indexed recipient, uint256 amountIn, uint256 amountOut, uint256 newParameterInvariant
    );

    /**
     * @notice  Emitted when LP position removed
     * @dev     Mint IBC to LP if inverseTokenCredit > inverseTokenBurned, otherwise burn IBC from LP
     * @param   from : The account to burn LP
     * @param   recipient : The account to receive reserve
     * @param   amountIn : The LP token amount burned
     * @param   reserveAmountOut : Reserve send to recipient
     * @param   inverseTokenCredit : IBC token credit
     * @param   inverseTokenBurned : IBC token debt which need to burn
     * @param   newParameterInvariant : New parameter invariant after LP removed
     */
    event LiquidityRemoved(
        address indexed from,
        address indexed recipient,
        uint256 amountIn,
        uint256 reserveAmountOut,
        uint256 inverseTokenCredit,
        uint256 inverseTokenBurned,
        uint256 newParameterInvariant
    );

    /**
     * @notice  Emitted when token staked
     * @dev
     * @param   from : Staked from account
     * @param   recipient : Account to stake for, the staked token holder will be changed to recipient
     * @param   amount : Staked token amount
     */
    event TokenStaked(address indexed from, address indexed recipient, uint256 amount);

    /**
     * @notice  Emitted when token unstaked
     * @dev
     * @param   from : Unstaked from account
     * @param   recipient : Account to receive the unstaked IBC token
     * @param   amount : Unstaked token amount
     */
    event TokenUnstaked(address indexed from, address indexed recipient, uint256 amount);

    /**
     * @notice  Emitted when token bought by user
     * @dev
     * @param   from : Buy from account
     * @param   recipient : Account to receive IBC token
     * @param   amountIn : Reserve amount provided
     * @param   amountOut : IBC token bought
     */
    event TokenBought(address indexed from, address indexed recipient, uint256 amountIn, uint256 amountOut);

    /**
     * @notice  Emitted when token sold by user
     * @dev
     * @param   from : Sell from account
     * @param   recipient : Account to receive reserve
     * @param   amountIn : IBC amount provided
     * @param   amountOut : Reserve amount received
     */
    event TokenSold(address indexed from, address indexed recipient, uint256 amountIn, uint256 amountOut);

    /**
     * @notice  Emitted when reward claimed
     * @dev
     * @param   from : Claim from account
     * @param   recipient : Account to recieve reward
     * @param   inverseTokenAmount : IBC token amount of reward
     * @param   reserveAmount : Reserve amount of reward
     */
    event RewardClaimed(address indexed from, address indexed recipient, uint256 inverseTokenAmount, uint256 reserveAmount);

    /**
     * @notice  Add reserve liquidity to inverse bonding curve
     * @dev     LP will get virtual LP token(non-transferable), and one account can only hold one LP position(Need to close and reopen if user want to change)
     * @param   recipient : Account to receive LP token
     * @param   priceLimits : [minPriceLimit, maxPriceLimit], if maxPriceLimit = 0, then no limitation for max price
     */
    function addLiquidity(address recipient, uint256 reserveIn, uint256[2] memory priceLimits) external;

    /**
     * @notice  Remove reserve liquidity from inverse bonding curve
     * @dev     IBC token may needed to burn LP
     * @param   recipient : Account to receive reserve
     * @param   priceLimits :[minPriceLimit, maxPriceLimit], if maxPriceLimit = 0, then no limitation for max price
     */
    function removeLiquidity(address recipient, uint256 inverseTokenIn, uint256[2] memory priceLimits) external;

    /**
     * @notice  Buy IBC token with reserve
     * @dev     If exactAmountOut greater than zero, then it will mint exact token to recipient
     * @param   recipient : Account to receive IBC token
     * @param   exactAmountOut : Exact amount IBC token to mint to user
     * @param   priceLimits : [minPriceLimit, maxPriceLimit], if maxPriceLimit = 0, then no limitation for max price
     * @param   reserveLimits : [minReserveLimit, maxReserveLimit], if maxReserveLimit = 0, then no limitation for max reserve
     */
    function buyTokens(
        address recipient,
        uint256 reserveIn,
        uint256 exactAmountOut,
        uint256[2] memory priceLimits,
        uint256[2] memory reserveLimits
    ) external;

    /**
     * @notice  Sell IBC token to get reserve back
     * @dev
     * @param   recipient : Account to receive reserve
     * @param   inverseTokenIn : IBC token amount to sell
     * @param   priceLimits : [minPriceLimit, maxPriceLimit], if maxPriceLimit = 0, then no limitation for max price
     * @param   reserveLimits : [minReserveLimit, maxReserveLimit], if maxReserveLimit = 0, then no limitation for max reserve
     */
    function sellTokens(address recipient, uint256 inverseTokenIn, uint256[2] memory priceLimits, uint256[2] memory reserveLimits)
        external;

    /**
     * @notice  Stake IBC token to get fee reward
     * @dev
     * @param   amount : Token amount to stake
     */
    function stake(address recipient, uint256 amount) external;

    /**
     * @notice  Unstake staked IBC token
     * @dev
     * @param   amount : Token amount to unstake
     */
    function unstake(address recipient, uint256 amount) external;

    /**
     * @notice  Claim fee reward
     * @dev
     * @param   recipient : Account to receive fee reward
     */
    function claimReward(address recipient) external;

    /**
     * @notice  Query LP position
     * @dev
     * @param   account : Account to query position
     * @return  lpTokenAmount : LP virtual token amount
     * @return  inverseTokenCredit : IBC token credited(Virtual, not able to sell/stake/transfer)
     */
    function liquidityPositionOf(address account) external view returns (uint256 lpTokenAmount, uint256 inverseTokenCredit);

    /**
     * @notice  Query staking balance
     * @dev
     * @param   account : Account address to query
     * @return  uint256 : Staking balance
     */
    function stakingBalanceOf(address account) external view returns (uint256);

    /**
     * @notice  Get IBC token contract address
     * @dev
     * @return  address : IBC token contract address
     */
    function inverseTokenAddress() external view returns (address);

    /**
     * @notice  Query reserve token contract address
     * @dev     
     * @return  address : Reserve token address of curve
     */
    function reserveTokenAddress() external view returns (address);

    /**
     * @notice  Query current inverse bonding curve parameter
     * @dev
     * @return  parameters : See CurveParameter for detail
     */
    function curveParameters() external view returns (CurveParameter memory parameters);

    /**
     * @notice  Query reward of account
     * @dev
     * @param   recipient : Account to query
     * @return  inverseTokenForLp : IBC token reward for account as LP
     * @return  inverseTokenForStaking : IBC token reward for account as Staker
     * @return  reserveForLp : Reserve reward for account as LP
     * @return  reserveForStaking : Reserve reward for account as Staker
     */
    function rewardOf(address recipient)
        external
        view
        returns (uint256 inverseTokenForLp, uint256 inverseTokenForStaking, uint256 reserveForLp, uint256 reserveForStaking);

    /**
     * @notice  Query total staked IBC token amount
     * @dev
     * @return  uint256 : Total staked amount
     */
    function totalStaked() external view returns (uint256);

    /**
     * @notice  Query EMA(exponential moving average) reward per second
     * @dev
     * @param   rewardType : Reward type: LP or staking
     * @return  inverseTokenReward : EMA IBC token reward per second
     * @return  reserveReward : EMA reserve reward per second
     */
    function rewardEMAPerSecond(RewardType rewardType) external view returns (uint256 inverseTokenReward, uint256 reserveReward);

    /**
     * @notice  Query fee state
     * @dev     Each array contains value for IBC, IBC from LP removal, Reserve, and each sub array for LP/Staker/Protocol
     * @return  totalReward : Total IBC token reward
     * @return  totalPendingReward : IBC token reward not claimed
     */
    function rewardState()
        external
        view
        returns (
            uint256[MAX_FEE_TYPE_COUNT][MAX_FEE_STATE_COUNT] memory totalReward,
            uint256[MAX_FEE_TYPE_COUNT][MAX_FEE_STATE_COUNT] memory totalPendingReward
        );
}
