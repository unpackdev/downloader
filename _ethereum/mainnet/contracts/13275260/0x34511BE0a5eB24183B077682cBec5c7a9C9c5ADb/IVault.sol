pragma solidity >=0.7.5;

import "./IERC20.sol";
import "./IUniswapV3Pool.sol";
import "./IFactory.sol";
import "./IERC20Metadata.sol";

/// @title Aastra Vault
/// @author 0xKal1
/// @notice Aastra Vault is a Uniswap V3 liquidity management vault enabling you to automate yield generation on your idle funds
/// @dev Provides an interface to the Aastra Vault
interface IVault is IERC20 {

    /// @notice Emitted when a deposit made to a vault
    /// @param sender The sender of the deposit transaction
    /// @param to The recipient of LP tokens
    /// @param shares Amount of LP tokens paid to recipient
    /// @param amount0 Amount of token0 deposited
    /// @param amount1 Amount of token1 deposited
    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when a withdraw made to a vault
    /// @param sender The sender of the withdraw transaction
    /// @param to The recipient of withdrawn amounts
    /// @param shares Amount of LP tokens paid back to vault
    /// @param amount0 Amount of token0 withdrawn
    /// @param amount1 Amount of token1 withdrawn
    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees collected from uniswap
    /// @param feesToVault0 Amount of token0 earned as fee by protocol
    /// @param feesToVault1 Amount of token1 earned as fee by protocol
    /// @param feesToStrategy0 Amount of token0 earned as fee by strategy manager
    /// @param feesToStrategy1 Amount of token1 earned as fee by strategy manager
    event CollectFees(
        uint256 feesToVault0,
        uint256 feesToVault1,
        uint256 feesToStrategy0,
        uint256 feesToStrategy1
    );

    /// @notice Retrieve first token of Uniswap V3 pool
    /// @return IERC20Metadata token address
    function token0() external view returns (IERC20Metadata);

    /// @notice Retrieve second token of Uniswap V3 pool
    /// @return IERC20Metadata token address
    function token1() external view returns (IERC20Metadata);

    /// @notice Retrieve usable amount of token0 available in the vault
    /// @return amount0 Amount of token0
    function getBalance0() external view returns (uint256);

    /// @notice Retrieve usable amount of token1 available in the vault
    /// @return amount1 Amount of token0
    function getBalance1() external view returns (uint256);

    /// @notice Retrieve tickSpacing of Pool used in the vault
    /// @return tickSpacing tickSpacing of the Uniswap V3 pool
    function tickSpacing() external view returns (int24);

    /// @notice Retrieve lower tick of base position of Pool used in the vault
    /// @return baseLower of the Uniswap V3 pool
    function baseLower() external view returns (int24);

    /// @notice Retrieve upper tick of base position of Pool used in the vault
    /// @return baseUpper of the Uniswap V3 pool
    function baseUpper() external view returns (int24);

    /// @notice Retrieve lower tick of limit position of Pool used in the vault
    /// @return limitLower of the Uniswap V3 pool
    function limitLower() external view returns (int24);

    /// @notice Retrieve upper tick of limit position of Pool used in the vault
    /// @return limitUpper of the Uniswap V3 pool
    function limitUpper() external view returns (int24);

    /// @notice Retrieve address of Uni V3 Pool used in the vault
    /// @return IUniswapV3Pool address of Uniswap V3 Pool
    function pool() external view returns (IUniswapV3Pool);

    /// @notice Retrieve address of Factory used to create the vault
    /// @return IFactory address of Aastra factory contract
    function factory() external view returns (IFactory);

    /// @notice Retrieve address of current router in Aastra
    /// @return router address of Aastra router contract
    function router() external view returns (address);

    /// @notice Retrieve address of strategy manager used to manage the vault
    /// @return manager address of vault manager
    function strategy() external view returns (address);

    /**
     * @notice Calculates the vault's total holdings of token0 and token1 - in
     * other words, how much of each token the vault would hold if it withdrew
     * all its liquidity from Uniswap.
     * @return total0 Total token0 holdings of the vault
     * @return total1 Total token1 holdings of the vault
     */
    function getTotalAmounts() external view returns (uint256, uint256);

    /// @dev Wrapper around `IUniswapV3Pool.positions()`.
    /// @notice Provides the current data on a position in the vault according to lower and upper tick
    /// @param tickLower Lower tick of the vault's position
    /// @param tickUpper Upper tick of the vault's position
    function position(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            uint128,
            uint256,
            uint256,
            uint128,
            uint128
        );

    /**
     * @notice Amounts of token0 and token1 held in vault's position. Includes owed fees but excludes the proportion of fees that will be paid to the protocol. Doesn't include fees accrued since last poke.
     * @param tickLower Lower tick of the vault's position
     * @param tickUpper Upper tick of the vault's position
     * @return amount0 Amount of token0 held in the vault's position
     * @return amount1 Amount of token1 held in the vault's position
     */
    function getPositionAmounts(int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    /// ------------- Router Functions ------------- ///

    /// @notice Updates due amount in uniswap owed for a tick range
    /// @dev Do zero-burns to poke a position on Uniswap so earned fees are updated. Should be called if total amounts needs to include up-to-date fees.
    /// @param tickLower Lower bound of the tick range
    /// @param tickUpper Upper bound of the tick range
    function poke(int24 tickLower, int24 tickUpper) external;

    /// @notice Used to update the new base position ticks of the vault
    /// @param _baseLower The new lower tick of the vault
    /// @param _baseUpper The new upper tick of the vault
    function setBaseTicks(int24 _baseLower, int24 _baseUpper) external;

    /// @notice Used to update the new limit position ticks of the vault
    /// @param _limitLower The new lower tick of the vault
    /// @param _limitUpper The new upper tick of the vault
    function setLimitTicks(int24 _limitLower, int24 _limitUpper) external;

    /// @notice Withdraws all liquidity from a range and collects all the fees in the process
    /// @param tickLower Lower bound of the tick range
    /// @param tickUpper Upper bound of the tick range
    /// @param liquidity Liquidity to be withdrawn from the range
    /// @return burned0 Amount of token0 that was burned
    /// @return burned1 Amount of token1 that was burned
    /// @return feesToVault0 Amount of token0 fees vault earned
    /// @return feesToVault1 Amount of token1 fees vault earned
    function burnAndCollect(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 feesToVault0,
            uint256 feesToVault1
        );

    /// @notice This method will optimally use all the funds provided in argument to mint the maximum possible liquidity
    /// @param _lowerTick Lower bound of the tick range
    /// @param _upperTick Upper bound of the tick range
    /// @param amount0 Amount of token0 to be used for minting liquidity
    /// @param amount1 Amount of token1 to be used for minting liquidity
    function mintOptimalLiquidity(
        int24 _lowerTick,
        int24 _upperTick,
        uint256 amount0,
        uint256 amount1,
        bool swapEnabled
    ) external;

    /// @notice Swaps tokens from the pool
    /// @param direction The direction of the swap, true for token0 to token1, false for reverse
    /// @param amountInToSwap Desired amount of token0 or token1 wished to swap
    /// @return amountOut Amount of token0 or token1 received from the swap
    function swapTokensFromPool(bool direction, uint256 amountInToSwap)
        external
        returns (uint256 amountOut);

    /// @notice Collects liquidity fee earned from both positions of vault and reinvests them back into the same position
    function compoundFee() external;

    /// @notice Used to collect accumulated strategy fees.
    /// @param amount0 Amount of token0 to collect
    /// @param amount1 Amount of token1 to collect
    /// @param to Address to send collected fees to
    function collectStrategy(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external;

    /// ------------- GOV Functions ------------- ///

    /**
     * @notice Emergency method to freeze actions performed by a strategy
     * @param value To be set to true in case of active freeze
     */
    function freezeStrategy(bool value) external;

    /**
     * @notice Emergency method to freeze actions performed by a vault user
     * @param value To be set to true in case of active freeze
     */
    function freezeUser(bool value) external;

    /// @notice Used to collect accumulated protocol fees.
    /// @param amount0 Amount of token0 to collect
    /// @param amount1 Amount of token1 to collect
    /// @param to Address to send collected fees to
    function collectProtocol(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external;

    /**
     * @notice Used to change deposit cap for a guarded launch or to ensure
     * vault doesn't grow too large relative to the pool. Cap is on total
     * supply rather than amounts of token0 and token1 as those amounts
     * fluctuate naturally over time.
     * @param _maxTotalSupply The new max total cap of the vault
     */
    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    /**
     * @notice Removes liquidity in case of emergency.
     * @param to Address to withdraw funds to
     */
    function emergencyBurnAndCollect(address to) external;

    /// ------------- User Functions ------------- ///

    /**
     * @notice Deposits tokens in proportion to the vault's current holdings.
     * @param amount0Desired Max amount of token0 to deposit
     * @param amount1Desired Max amount of token1 to deposit
     * @param amount0Min Revert if resulting `amount0` is less than this
     * @param amount1Min Revert if resulting `amount1` is less than this
     * @param to Recipient of shares
     * @return shares Number of shares minted
     * @return amount0 Amount of token0 deposited
     * @return amount1 Amount of token1 deposited
     */
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice Withdraws tokens in proportion to the vault's holdings.
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @param to Recipient of tokens
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1);
}
