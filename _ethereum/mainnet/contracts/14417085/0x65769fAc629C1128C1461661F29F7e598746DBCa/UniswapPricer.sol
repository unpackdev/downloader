// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import "./IUniswapV3Pool.sol";
import "./OracleInterface.sol";
import "./ERC20Interface.sol";
import "./OpynPricerInterface.sol";
import "./OracleLibrary.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @notice A Pricer contract for many assets as reported by their Uniswap V3 pool
 */
contract UniswapPricer is Ownable, OpynPricerInterface {
    using SafeMath for uint256;

    /// @dev struct to store pool address and the twap period for the pool
    struct Pool {
        address pool;
        uint32 secondsAgo;
        bool token0;
    }

    /// @notice the opyn oracle address
    OracleInterface public immutable oracle;
    /// @notice the uniswap v3 pool for each asset
    mapping(address => Pool) public pools;

    /// @dev decimals used by oracle price
    uint256 internal constant BASE_UNITS = 10**8;
    /// @dev default twap period (30 mins)
    uint24 internal constant DEFAULT_SECONDS_AGO = 30 * 60;

    /// @notice emits an event when the pool is updated for an asset
    event PoolUpdated(address indexed asset, address indexed pool, uint32 secondsAgo);

    /**
     * @param _oracle Opyn Oracle address
     */
    constructor(address _oracle) public {
        require(_oracle != address(0), "UniswapPricer: Cannot set 0 address as oracle");

        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice sets the pools for the assets, allows overriding existing pools
     * @dev can only be called by the owner
     * @param _assets assets to set the pools for
     * @param _pools uniswap pools for the assets
     * @param _secondsAgo twap period for the pool
     */
    function setPools(
        address[] calldata _assets,
        address[] calldata _pools,
        uint32[] calldata _secondsAgo
    ) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            require(_assets[i] != address(0), "UniswapPricer: Cannot set 0 address as asset");

            bool _token0;
            if (_pools[i] != address(0)) {
                address token0 = IUniswapV3Pool(_pools[i]).token0();
                require(
                    _assets[i] == token0 || _assets[i] == IUniswapV3Pool(_pools[i]).token1(),
                    "UniswapPricer: Invalid pool"
                );
                _token0 = _assets[i] == token0;
            }

            pools[_assets[i]] = Pool(_pools[i], _secondsAgo[i], _token0);

            emit PoolUpdated(_assets[i], _pools[i], _secondsAgo[i]);
        }
    }

    /**
     * @notice sets the expiry prices in the oracle
     * @dev requires that the underlying price has been set before setting a cToken price
     * @param _assets assets to set the price for
     * @param _expiryTimestamps expiries to set a price for
     */
    function setExpiryPriceInOracle(address[] calldata _assets, uint256[] calldata _expiryTimestamps) external {
        for (uint256 i = 0; i < _assets.length; i++) {
            require(_expiryTimestamps[i] <= now, "UniswapPricer: timestamp too high");
            (address quoteToken, uint256 quoteAmount) = _getPool(_assets[i]);
            (uint256 _quotePrice, bool _isFinalized) = oracle.getExpiryPrice(quoteToken, _expiryTimestamps[i]);
            require(_quotePrice > 0 || _isFinalized, "UniswapPricer: price not finalized");
            oracle.setExpiryPrice(
                _assets[i],
                _expiryTimestamps[i],
                quoteAmount.mul(_quotePrice).div(10**uint256(ERC20Interface(quoteToken).decimals()))
            );
        }
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @param _asset asset that this pricer will get a price for
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice(address _asset) external view override returns (uint256) {
        (address quoteToken, uint256 quoteAmount) = _getPool(_asset);
        return quoteAmount.mul(oracle.getPrice(quoteToken)).div(10**uint256(ERC20Interface(quoteToken).decimals()));
    }

    function getHistoricalPrice(address, uint80) external view override returns (uint256, uint256) {
        revert("UniswapPricer: Deprecated");
    }

    /**
     * @dev gets the quote token and the quote amount for an asset
     * @param _asset asset to get the quote amount of
     * @return quoteToken the quote token for the asset
     * @return quoteAmount the price of the asset in terms of the quoteToken
     */
    function _getPool(address _asset) internal view returns (address quoteToken, uint256 quoteAmount) {
        Pool memory _pool = pools[_asset];
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(
            _pool.pool,
            _pool.secondsAgo == 0 ? DEFAULT_SECONDS_AGO : _pool.secondsAgo
        );
        quoteToken = _pool.token0 ? IUniswapV3Pool(_pool.pool).token1() : IUniswapV3Pool(_pool.pool).token0();
        quoteAmount = OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            uint128(10**uint256(ERC20Interface(_asset).decimals())),
            _asset,
            quoteToken
        );
    }
}
