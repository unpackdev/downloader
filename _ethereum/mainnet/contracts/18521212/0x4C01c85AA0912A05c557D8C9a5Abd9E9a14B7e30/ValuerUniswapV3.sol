// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./INonfungiblePositionManager.sol";
import "./LiquidityAmounts.sol";
import "./IUniswapV3Pool.sol";
import "./FixedPoint128.sol";
import "./RewardsBoosterErrors.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Math.sol";
import "./Tick.sol";
import "./IValuer.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 ValuerUniswapV3
 * @author Asymetrix Protocol Inc Team
 * @notice A valuer for Uniswap V3 Pool positions.
 */
contract ValuerUniswapV3 is Ownable, IValuer {
    using Address for address;

    INonfungiblePositionManager private positionManager;
    IUniswapV3Pool private pool;
    IOracle private oracle0;
    IOracle private oracle1;
    uint32 private twapPeriod;

    /**
     * @notice Deploy the ValuerUniswapV3 contract.
     * @param _positionManager Uniswap V3 NonfungiblePositionManager contract.
     * @param _pool Uniswap V3 Pool contract.
     * @param _oracle0 An oracle address for the first asset from the pool.
     * @param _oracle1 An oracle address for the second asset from the pool.
     * @param _twapPeriod TWAP period (in seconds) that will be used to value positions.
     */
    constructor(address _positionManager, address _pool, address _oracle0, address _oracle1, uint32 _twapPeriod) {
        onlyContract(_positionManager);
        onlyContract(_pool);
        onlyContract(_oracle0);
        onlyContract(_oracle1);

        positionManager = INonfungiblePositionManager(_positionManager);
        pool = IUniswapV3Pool(_pool);
        oracle0 = IOracle(_oracle0);
        oracle1 = IOracle(_oracle1);
        twapPeriod = _twapPeriod;
    }

    /**
     * @notice Sets a new TWAP period (in seconds) by an owner.
     * @param _newTwapPeriod New TWAP period (in seconds) that will be used to value positions.
     */
    function setTwapPeriod(uint32 _newTwapPeriod) external onlyOwner {
        twapPeriod = _newTwapPeriod;
    }

    /// @inheritdoc IValuer
    function value(uint256 _id) external view returns (uint256 _value) {
        (uint256 _value0, uint256 _value1) = getTokenAmountsInUSD(_id);

        return (_value0 + _value1) / 1e18;
    }

    /**
     * @notice Returns token amounts inside the position.
     * @param _id Id of the Uniswap V3 position.
     * @return _amount0 The first token amount.
     * @return _amount1 The second token amount.
     */
    function getTokenAmounts(uint256 _id) external view returns (uint256 _amount0, uint256 _amount1) {
        (_amount0, _amount1, ) = _getTokenAmounts(positionManager.positions(_id));
    }

    /**
     * @notice Returns NonfungiblePositionManager address.
     * @return NonfungiblePositionManager address.
     */
    function getPositionManager() external view returns (INonfungiblePositionManager) {
        return positionManager;
    }

    /**
     * @notice Returns Uniswap V3 Pool address.
     * @return Uniswap V3 Pool address.
     */
    function getPool() external view returns (IUniswapV3Pool) {
        return pool;
    }

    /**
     * @notice Returns an oracle address for the first asset from the pool.
     * @return An oracle address for the first asset from the pool.
     */
    function getOracle0() external view returns (IOracle) {
        return oracle0;
    }

    /**
     * @notice Returns an oracle address for the second asset from the pool.
     * @return An oracle address for the second asset from the pool.
     */
    function getOracle1() external view returns (IOracle) {
        return oracle1;
    }

    /**
     * @notice Returns TWAP period in seconds.
     * @return TWAP period in seconds.
     */
    function getTwapPeriod() external view returns (uint32) {
        return twapPeriod;
    }

    /// @inheritdoc IValuer
    function getTokenAmountsInUSD(uint256 _id) public view returns (uint256 _value0, uint256 _value1) {
        INonfungiblePositionManager.Position memory _position = positionManager.positions(_id);
        (uint256 _amount0, uint256 _amount1, int24 _tick) = _getTokenAmounts(_position);

        (_value0, _value1) = _calculateUSD(_position, pool, _amount0, _amount1, _tick);
    }

    /**
     * @notice Internal calculation for token amounts inside the position.
     * @param _position Uniswap V3 position.
     * @return The first token amount.
     * @return The second token amount.
     * @return The tick.
     */
    function _getTokenAmounts(
        INonfungiblePositionManager.Position memory _position
    ) internal view returns (uint256, uint256, int24) {
        int24 _tick;

        {
            uint32 _twapPeriod = twapPeriod;
            uint32[] memory _secondsAgos = new uint32[](2);

            _secondsAgos[0] = _twapPeriod;

            (int56[] memory _tickCumulatives, ) = pool.observe(_secondsAgos);

            _tick = int24((_tickCumulatives[1] - _tickCumulatives[0]) / int32(_twapPeriod));
        }

        (uint256 _amount0, uint256 _amount1) = LiquidityAmounts.getAmountsForLiquidity(
            TickMath.getSqrtRatioAtTick(_tick),
            TickMath.getSqrtRatioAtTick(_position.tickLower),
            TickMath.getSqrtRatioAtTick(_position.tickUpper),
            _position.liquidity
        );

        return (_amount0, _amount1, _tick);
    }

    /**
     * @notice Internal calculation for token amounts in USD inside the position.
     * @param _position Uniswap V3 position.
     * @param _pool Uniswap V3 pool.
     * @param _value0 The first token amount.
     * @param _value1 The second token amount.
     * @param _tick The tick.
     * @return _value0 The first token amount in USD.
     * @return _value1 The second token amount in USD.
     */
    function _calculateUSD(
        INonfungiblePositionManager.Position memory _position,
        IUniswapV3Pool _pool,
        uint256 _amount0,
        uint256 _amount1,
        int24 _tick
    ) private view returns (uint256 _value0, uint256 _value1) {
        {
            (uint256 _feeGrowthInside0X128, uint256 _feeGrowthInside1X128) = Tick.getFeeGrowthInside(
                address(_pool),
                _position.tickLower,
                _position.tickUpper,
                _tick,
                _pool.feeGrowthGlobal0X128(),
                _pool.feeGrowthGlobal1X128()
            );
            uint256 _newTokensOwed0 = FullMath.mulDiv(
                _feeGrowthInside0X128 - Math.min(_feeGrowthInside0X128, _position.feeGrowthInside0LastX128),
                _position.liquidity,
                FixedPoint128.Q128
            );
            uint256 _newTokensOwed1 = FullMath.mulDiv(
                _feeGrowthInside1X128 - Math.min(_feeGrowthInside1X128, _position.feeGrowthInside1LastX128),
                _position.liquidity,
                FixedPoint128.Q128
            );

            _amount0 += uint256(_position.tokensOwed0) + _newTokensOwed0;
            _amount1 += uint256(_position.tokensOwed1) + _newTokensOwed1;
        }

        _value0 = ((uint256(oracle0.latestAnswer()) * 1e18) / 10 ** oracle0.decimals()) * _amount0;
        _value1 = ((uint256(oracle1.latestAnswer()) * 1e18) / 10 ** oracle1.decimals()) * _amount1;
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function onlyContract(address _contract) private view {
        if (!_contract.isContract()) revert RewardsBoosterErrors.NotContract();
    }
}
