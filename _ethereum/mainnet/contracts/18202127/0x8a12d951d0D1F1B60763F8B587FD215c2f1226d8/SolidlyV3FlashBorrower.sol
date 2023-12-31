// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Callback for ISolidlyV3PoolActions#flash
/// @notice Any contract that calls ISolidlyV3PoolActions#flash must implement this interface
interface ISolidlyV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from ISolidlyV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a SolidlyV3Pool deployed by the canonical SolidlyV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the ISolidlyV3PoolActions#flash call
    function solidlyV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

interface ISolidlyV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of ISolidlyV3MintCallback#solidlyV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of ISolidlyV3MintCallback#SolidlyV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param amount0Min The minimum amount of token0 to spend, which serves as a slippage check
    /// @param amount1Min The minimum amount of token1 to spend, which serves as a slippage check
    /// @param deadline A constraint on the time by which the mint transaction must mined
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Convenience method to burn liquidity and then collect owed tokens in one go
    /// @param recipient The address which should receive the tokens collected
    /// @param tickLower The lower tick of the position for which to collect tokens
    /// @param tickUpper The upper tick of the position for which to collect tokens
    /// @param amountToBurn How much liquidity to burn
    /// @param amount0ToCollect How much token0 should be withdrawn from the tokens owed
    /// @param amount1ToCollect How much token1 should be withdrawn from the tokens owed
    /// @return amount0FromBurn The amount of token0 accrued to the position from the burn
    /// @return amount1FromBurn The amount of token1 accrued to the position from the burn
    /// @return amount0Collected The amount of token0 collected from the positions
    /// @return amount1Collected The amount of token1 collected from the positions
    function burnAndCollect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amountToBurn,
        uint128 amount0ToCollect,
        uint128 amount1ToCollect
    )
    external
    returns (uint256 amount0FromBurn, uint256 amount1FromBurn, uint128 amount0Collected, uint128 amount1Collected);

    /// @notice Convenience method to burn liquidity and then collect owed tokens in one go
    /// @param recipient The address which should receive the tokens collected
    /// @param tickLower The lower tick of the position for which to collect tokens
    /// @param tickUpper The upper tick of the position for which to collect tokens
    /// @param amountToBurn How much liquidity to burn
    /// @param amount0FromBurnMin The minimum amount of token0 that should be accounted for the burned liquidity
    /// @param amount1FromBurnMin The minimum amount of token1 that should be accounted for the burned liquidity
    /// @param amount0ToCollect How much token0 should be withdrawn from the tokens owed
    /// @param amount1ToCollect How much token1 should be withdrawn from the tokens owed
    /// @param deadline A constraint on the time by which the burn transaction must mined
    /// @return amount0FromBurn The amount of token0 accrued to the position from the burn
    /// @return amount1FromBurn The amount of token1 accrued to the position from the burn
    /// @return amount0Collected The amount of token0 collected from the positions
    /// @return amount1Collected The amount of token1 collected from the positions
    function burnAndCollect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amountToBurn,
        uint256 amount0FromBurnMin,
        uint256 amount1FromBurnMin,
        uint128 amount0ToCollect,
        uint128 amount1ToCollect,
        uint256 deadline
    )
    external
    returns (uint256 amount0FromBurn, uint256 amount1FromBurn, uint128 amount0Collected, uint128 amount1Collected);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute tokens earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed are from burned liquidity.
    /// @param recipient The address which should receive the tokens collected
    /// @param tickLower The lower tick of the position for which to collect tokens
    /// @param tickUpper The upper tick of the position for which to collect tokens
    /// @param amount0Requested How much token0 should be withdrawn from the tokens owed
    /// @param amount1Requested How much token1 should be withdrawn from the tokens owed
    /// @return amount0 The amount of tokens collected in token0
    /// @return amount1 The amount of tokens collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Tokens must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Tokens must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @param amount0Min The minimum amount of token0 that should be accounted for the burned liquidity
    /// @param amount1Min The minimum amount of token1 that should be accounted for the burned liquidity
    /// @param deadline A constraint on the time by which the burn transaction must mined
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed to the function, to be used for source/referrer tracking
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param amountLimit A constraint on the minimum amount out received (for exact input swaps) or maxium amount spent (exact output swaps)
    /// @param deadline A constraint on the time by which the swap transaction must mined
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 amountLimit,
        uint256 deadline
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param amountLimit A constraint on the minimum amount out received (for exact input swaps) or maxium amount spent (exact output swaps)
    /// @param deadline A constraint on the time by which the swap transaction must mined
    /// @param data Any data to be passed to the function, to be used for source/referrer tracking
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 amountLimit,
        uint256 deadline,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of ISolidlyV3FlashCallback#solidlyV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface ISolidlyV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the ISolidlyV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

interface ISolidlyV3Pool is ISolidlyV3PoolImmutables, ISolidlyV3PoolActions
{
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUSDT {
    function transfer(address, uint256) external;
}

contract SolidlyV3FlashBorrower is ISolidlyV3FlashCallback {
    function borrow(ISolidlyV3Pool pool, uint256 amount0, uint256 amount1)  public{
        pool.flash(address(this), amount0, amount1, abi.encode(address(pool), pool.token0(), pool.token1(), amount0, amount1));
    }

    function solidlyV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) public {
        (address pool, address token0, address token1, uint256 amount0, uint256 amount1) = abi.decode(data, (address, address, address, uint256, uint256));
        IERC20(token0).transfer(pool, amount0 + fee0);
        IUSDT(token1).transfer(pool, amount1 + fee1);
    }
}