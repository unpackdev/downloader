// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeUint128.sol";
import "./OracleLibrary.sol";
import "./IOracle.sol";
import "./IUniStrategy.sol";

import "./SafeMath.sol";

import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";

contract V3Oracle is IOracle {
    using SafeMath for uint256;

    address public strategy;
    address public governance;
    address public pilotWethPair;
    address public immutable weth;
    address public immutable pilot;
    address public immutable uniswapFactory;

    modifier onlyGovernance() {
        require(msg.sender == governance, "NG");
        _;
    }

    constructor(
        address _uniswapFactory,
        address _weth,
        address _pilot,
        address _pilotWethPair,
        address _strategy,
        address _governance
    ) {
        (uniswapFactory, weth, pilot, pilotWethPair, strategy, governance) = (
            _uniswapFactory,
            _weth,
            _pilot,
            _pilotWethPair,
            _strategy,
            _governance
        );
    }

    function setUniStrategy(address _strategy) external onlyGovernance {
        require(_strategy != address(0), "IUS");
        emit UniStrategyUpdated(strategy, _strategy);
        strategy = _strategy;
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "IGA");
        emit GovernanceUpdated(governance, _governance);
        governance = _governance;
    }

    function getPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) private view returns (address) {
        return IUniswapV3Factory(uniswapFactory).getPool(token0, token1, fee);
    }

    function getPoolDetails(address pool)
        private
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint16 poolCardinality,
            uint128 liquidity,
            uint160 sqrtPriceX96,
            int24 currentTick,
            int24 tickSpacing
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        token0 = uniswapPool.token0();
        token1 = uniswapPool.token1();
        fee = uniswapPool.fee();
        liquidity = uniswapPool.liquidity();
        (sqrtPriceX96, currentTick, , poolCardinality, , , ) = uniswapPool.slot0();
        tickSpacing = uniswapPool.tickSpacing();
    }

    /**
     *   @notice This function returns the pilot amount equivalent to the liquidity
     *   provided in the tokens. It is used when the user chooses to collect fees
     *   in $PILOT
     *   @param token0: address of token0
     *   @param token1: address of token1
     *   @param amount0: amount of token0
     *   @param amount1: amount of token1
     *   @return total Total PILOT amount of token0 & token1 amounts
     **/
    function getPilotAmountForTokens(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address oracle0,
        address oracle1
    ) external view override returns (uint256 total) {
        amount0 = getPilotAmount(token0, amount0, oracle0);
        amount1 = getPilotAmount(token1, amount1, oracle1);
        total = amount0.add(amount1);
    }

    /**
     *   @notice This function returns pilot amount equivalent to the liqudity
     *   provided in the WETH pairs.
     *   @param tokenAlt: address of alt token
     *   @param altAmount: amount of alt token
     *   @param wethAmount: amount of weth token
     **/
    function getPilotAmountWethPair(
        address tokenAlt,
        uint256 altAmount,
        uint256 wethAmount,
        address altOracle
    ) external view override returns (uint256 amount) {
        uint256 pilotAmount0 = ethToAsset(pilot, pilotWethPair, wethAmount);
        uint256 pilotAmount1 = altAmount;
        if (tokenAlt != pilot) {
            pilotAmount1 = getPilotAmount(tokenAlt, altAmount, altOracle);
        }
        amount = pilotAmount0.add(pilotAmount1);
    }

    /**
     *   @notice This function returns the pilot amount equivalent to the
     *   token value provided
     *   @param token: address of token
     *   @param amount: amount of token
     *   @return pilotAmount Total PILOT amount of ALT amount
     **/
    function getPilotAmount(
        address token,
        uint256 amount,
        address pool
    ) public view override returns (uint256 pilotAmount) {
        uint256 ethAmount = assetToEth(token, pool, amount);
        pilotAmount = ethToAsset(pilot, pilotWethPair, ethAmount);
    }

    /**
     *   @notice This function returns the price of an asset into eth value
     *   @param token: address of the token
     *   @param pool: fee tier
     *   @param amountIn: amount of provided token
     *   @return ethAmountOut ETH amount
     **/
    function assetToEth(
        address token,
        address pool,
        uint256 amountIn
    ) public view override returns (uint256 ethAmountOut) {
        return getPrice(token, weth, pool, amountIn);
    }

    /**
     *   @notice This function returns the price of eth into a desired asset
     *   @param tokenOut: address of desired token
     *   @param pool: fee tier
     *   @param amountIn: amount of eth provided
     *   @return amountOut ALT amount
     **/
    function ethToAsset(
        address tokenOut,
        address pool,
        uint256 amountIn
    ) public view override returns (uint256 amountOut) {
        return getPrice(weth, tokenOut, pool, amountIn);
    }

    /**
     *   @notice This function returns the price of a token equivalent
     *   to the price of the other token in a pool
     *   @param tokenA: address of tokenA
     *   @param tokenB: address of tokenB
     *   @param poolAddress: fee tier of the intended pool
     *   @param _amountIn: amount of tokenIn
     *   @return amountOut The out amount from Oracle
     **/
    function getPrice(
        address tokenA,
        address tokenB,
        address poolAddress,
        uint256 _amountIn
    ) public view override returns (uint256 amountOut) {
        int256 twapTick = IUniStrategy(strategy).getTwap(poolAddress);
        return
            OracleLibrary.getQuoteAtTick(
                int24(twapTick),
                SafeUint128.toUint128(_amountIn),
                tokenA,
                tokenB
            );
    }
}
