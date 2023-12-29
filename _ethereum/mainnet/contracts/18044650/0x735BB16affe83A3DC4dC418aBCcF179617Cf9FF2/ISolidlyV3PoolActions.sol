// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
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
