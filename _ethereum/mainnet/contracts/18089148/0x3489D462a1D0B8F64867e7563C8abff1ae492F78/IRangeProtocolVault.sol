//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./IUniswapV3MintCallback.sol";
import "./IUniswapV3SwapCallback.sol";
import "./DataTypesLib.sol";
import "./IRangeProtocolVaultGetters.sol";

interface IRangeProtocolVault is
    IERC20Upgradeable,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    IRangeProtocolVaultGetters
{
    event Minted(address indexed receiver, uint256 shares, uint256 amount);
    event Burned(address indexed receiver, uint256 burnAmount, uint256 amount);
    event LiquidityAdded(
        uint256 liquidityMinted,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0In,
        uint256 amount1In
    );
    event LiquidityRemoved(
        uint256 liquidityRemoved,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Out,
        uint256 amount1Out
    );
    event FeesEarned(uint256 feesEarned0, uint256 feesEarned1);
    event FeesUpdated(uint16 managingFee, uint16 performanceFee);
    event InThePositionStatusSet(bool inThePosition);
    event Swapped(bool zeroForOne, int256 amount0, int256 amount1);
    event TicksSet(int24 lowerTick, int24 upperTick);
    event CollateralSupplied(address token, uint256 amount);
    event CollateralWithdrawn(address token, uint256 amount);
    event GHOMinted(uint256 amount);
    event GHOBurned(uint256 amount);
    event PoolRebalanced();

    // @notice intializes the vault.
    function initialize(address _pool, int24 _tickSpacing, bytes memory data) external;

    // @notice updates the ticks and is only called by the manager.
    function updateTicks(int24 _lowerTick, int24 _upperTick) external;

    // @notice mints vault shares to users by accepting the liquidity in collateral token.
    function mint(uint256 amount) external returns (uint256 shares);

    // @notice burns vault shares from user and returns then their share in collateral token.
    function burn(uint256 burnAmount) external returns (uint256 amount);

    // @notice mints shares to users. Only callable by the vault contract through library.
    function mintShares(address to, uint256 shares) external;

    // @notice burns shares from users. Only callable by the vault contract through library.
    function burnShares(address from, uint256 shares) external;

    // @notice removes liquidity from the vault. Only callable by vault manager.
    function removeLiquidity() external;

    // @notice swaps token0 to token1 and vice-versa within the vault. Only callable by vault manager.
    function swap(
        bool zeroForOne,
        int256 swapAmount,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1);

    // @notice adds liquidity to newer tick range. Only callable by vault manager.
    function addLiquidity(
        int24 newLowerTick,
        int24 newUpperTick,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 remainingAmount0, uint256 remainingAmount1);

    // @notice collects manager fee by manager. Only callable by vault manager.
    function collectManager() external;

    // @notice updates fees percentages. Only callable by the vault manager.
    function updateFees(uint16 newManagingFee, uint16 newPerformanceFee) external;

    // @notice returns the underlying balance of vault in collateral token.
    function getBalanceInCollateralToken() external view returns (uint256 amount);

    // @notice returns the underlying balance based on the amount of {shares}.
    function getUnderlyingBalanceByShare(uint256 shares) external view returns (uint256 amount);

    // @notice returns currenly unclaimed fee in the contract.
    function getCurrentFees() external view returns (uint256 fee0, uint256 fee1);

    // @notice returns current position id of the contract.
    function getPositionID() external view returns (bytes32 positionID);

    // @notice returns users vaults based on the passed indexes.
    function getUserVaults(uint256 fromIdx, uint256 toIdx) external view returns (DataTypesLib.UserVaultInfo[] memory);

    // @notice supplies collateral to Aave in collateral token.
    function supplyCollateral(uint256 supplyAmount) external;

    // @notice withdraws collateral from Aave in collateral token.
    function withdrawCollateral(uint256 withdrawAmount) external;

    // @notice borrows GHO token from Aave.
    function mintGHO(uint256 mintAmount) external;

    // @notice payback the debt in GHO token to Aave.
    function burnGHO(uint256 burnAmount) external;

    // @notice multicall function to rebalance the AMM pool.
    function rebalance(bytes[] memory calldatas) external returns (bytes[] memory returndatas);
}
