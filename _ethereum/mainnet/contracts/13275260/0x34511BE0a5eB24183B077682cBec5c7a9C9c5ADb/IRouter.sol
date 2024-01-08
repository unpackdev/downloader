pragma solidity >=0.7.5;

import "./IERC20.sol";
import "./IUniswapV3Pool.sol";

import "./IFactory.sol";
import "./IVault.sol";

/// @title Aastra Router
/// @author 0xKal1
/// @notice Aastra Router provides simple interface for SM to interact with vault
interface IRouter {

    /// @notice Emitted on successfull rebalance of base liquidity of vault
    /// @param vault Address of aastra vault
    /// @param baseLower Lower tick of new rebalanced liquidity
    /// @param baseUpper Upper tick of new rebalanced liquidity
    /// @param percentage Percentage of funds to be used for rebalance
    event RebalanceBaseLiqudity(
        address indexed vault,
        int24 baseLower,
        int24 baseUpper,
        uint8 percentage
    );

    /// @notice Emitted on successfull rebalance of base liquidity of vault
    /// @param vault Address of aastra vault
    /// @param limitLower Lower tick of new rebalanced liquidity
    /// @param limitUpper Upper tick of new rebalanced liquidity
    /// @param percentage Percentage of funds to be used for rebalance
    event RebalanceLimitLiqudity(
        address indexed vault,
        int24 limitLower,
        int24 limitUpper,
        uint8 percentage
    );
    
    /// @notice returns address of Aastra factory contract
    /// @return IFactory Address of aastra factory contract
    function factory() external returns (IFactory);

    /// @notice Retrieve amounts present in base position
    /// @param vault Address of the vault
    /// @return liquidity Liquidity amount of the position
    /// @return amount0 Amount of token0 present in the position after last poke
    /// @return amount1 Amount of token1 present in the position after last poke
    function getBaseAmounts(address vault)
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Retrieve amounts present in limit position
    /// @param vault Address of the vault
    /// @return liquidity Liquidity amount of the position
    /// @return amount0 Amount of token0 present in the position after last poke
    /// @return amount1 Amount of token1 present in the position after last poke
    function getLimitAmounts(address vault)
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Used to create a new base liquidity position on uniswap. This will burn and remove any existing position held by the vault 
    /// @param _baseLower The lower limit of the liquidity position
    /// @param _baseUpper The upper limit of the liquidity position
    /// @param _percentage The percentage of funds of the vault to be used for liquidity position
    /// @param swapEnabled Enable/disable the automatic swapping for optimal liqudity minting
    function newBaseLiquidity(
        int24 _baseLower,
        int24 _baseUpper,
        uint8 _percentage,
        bool swapEnabled
    ) external;

    /// @notice Used to create a new limit liquidity position on uniswap. This will burn and remove any existing position held by the vault 
    /// @param _limitLower The lower limit of the liquidity position
    /// @param _limitUpper The upper limit of the liquidity position
    /// @param _percentage The percentage of funds of the vault to be used for liquidity position
    function newLimitLiquidity(
        int24 _limitLower,
        int24 _limitUpper,
        uint8 _percentage, 
        bool swapEnabled
    ) external;

    /// @notice Used to collect and compound fee for a specific vault
    /// @param _vault Address of the vault
    function compoundFee(address _vault) external;

    /// @notice Retrieve lower and upper ticks of vault\'s base position
    /// @param vault Address of the vault
    /// @return lowerTick Lower limit of the vault\'s base position
    /// @return upperTick Upper limit of the vault\'s base position
    function getBaseTicks(address vault)
        external
        returns (int24 lowerTick, int24 upperTick);

    /// @notice Retrieve lower and upper ticks of vault\'s limit position
    /// @param vault Address of the vault
    /// @return lowerTick Lower limit of the vault\'s limit position
    /// @return upperTick Upper limit of the vault\'s limit position
    function getLimitTicks(address vault)
        external
        returns (int24 lowerTick, int24 upperTick);
}
