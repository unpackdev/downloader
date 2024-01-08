pragma solidity ^0.7.6;
pragma abicoder v2;

import "./PriceOracle.sol";
import "./ErrorReporter.sol";
import "./PTokenInterfaces.sol";
import "./SafeMath.sol";
import "./UniswapPriceOracleStorage.sol";
import "./EIP20Interface.sol";
import "./Controller.sol";
import "./PTokenFactory.sol";

contract UniswapPriceOracle is UniswapPriceOracleStorageV1, PriceOracle, OracleErrorReporter {
    using FixedPoint for *;
    using SafeMath for uint;

    event PoolAdded(uint id, address poolFactory);
    event PoolRemoved(uint id, address poolFactory);
    event PoolUpdated(uint id, address poolFactory);

    event StableCoinAdded(uint id, address coin);
    event StableCoinRemoved(uint id, address coin);
    event StableCoinUpdated(uint id, address coin);

    event AssetPairUpdated(address asset, address pair);

    constructor() {}

    function initialize(
        address poolFactory_,
        address WETHToken_,
        address ETHUSDPriceFeed_
    )
        public
    {
        require(
            WETHToken == address(0) &&
            ETHUSDPriceFeed == address(0)
            , "Oracle: may only be initialized once"
        );

        WETHToken = WETHToken_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        poolFactories.push(poolFactory_);

        emit PoolAdded(0, poolFactory_);
    }

    function updateUnderlyingPrice(address pToken) public override returns (uint) {
        if (pToken == Registry(registry).pETH()) {
            return uint(Error.NO_ERROR);
        }

        address asset = PErc20Interface(pToken).underlying();

        return update(asset);
    }

    // Get the most recent price for a asset in USD with 18 decimals of precision.
    function getPriceInUSD(address asset) public view virtual returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(ETHUSDPriceFeed).latestAnswer());
        uint AssetETHCourse = getCourseInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    function getCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        return averagePrices[asset];
    }

    function update(address asset) public returns (uint) {
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimeStamp;
        address pair;

        if (isNewAsset(asset)) {
            if (assetPair[asset] == address(0)) {
                // first update from factory or other users
                (pair, ) = searchPair(asset);
            } else {
                // after updatePair function
                pair = assetPair[asset];
            }

            if (pair != address(0)) {
                assetPair[asset] = pair;

                (reserve0, reserve1, blockTimeStamp) = getReservesFromPair(asset);

                if (reserve1 < minReserveLiquidity) {
                    return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
                }

                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve1), reserve0));
            } else {
                return fail(Error.UPDATE_PRICE, FailureInfo.NO_PAIR);
            }
        } else {
            // second and next updates
            (, , blockTimeStamp) = getReservesFromPair(asset);

            if (reserve1 < minReserveLiquidity) {
                cumulativePrices[assetPair[asset]][asset].priceAverage._x = 0;
                cumulativePrices[assetPair[asset]][asset].priceCumulativePrevious = 0;
                cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious = 0;

                return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
            }

            if (!isPeriodElapsed(asset)) {
                return fail(Error.UPDATE_PRICE, FailureInfo.PERIOD_NOT_ELAPSED);
            }

            pair = assetPair[asset];

            uint32 timeElapsed = blockTimeStamp - cumulativePrices[pair][asset].blockTimeStampPrevious;

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            if (asset == IUniswapV2Pair(pair).token0()) {
                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uint224((IUniswapV2Pair(pair).price0CumulativeLast() - cumulativePrices[pair][asset].priceCumulativePrevious) / timeElapsed));
            } else {
                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uint224((IUniswapV2Pair(pair).price1CumulativeLast() - cumulativePrices[pair][asset].priceCumulativePrevious) / timeElapsed));
            }
        }

        cumulativePrices[pair][asset].blockTimeStampPrevious = blockTimeStamp;

        // update data
        if (asset == IUniswapV2Pair(pair).token0()) {
            cumulativePrices[pair][asset].priceCumulativePrevious = IUniswapV2Pair(pair).price0CumulativeLast();
        } else {
            cumulativePrices[pair][asset].priceCumulativePrevious = IUniswapV2Pair(pair).price1CumulativeLast();
        }

        averagePrices[asset] = calcCourseInETH(asset);

        emit PriceUpdated(asset, getCourseInETH(asset));

        return uint(Error.NO_ERROR);
    }

    function checkAndUpdateAllNewAssets() public {
        PTokenFactory factory = PTokenFactory(Registry(registry).factory());
        Controller controller = Controller(factory.controller());

        address[] memory allMarkets = Controller(controller).getAllMarkets();

        updateNewAssets(allMarkets);
    }

    function updateNewAssets(address[] memory pTokens) public {
        address asset;

        for(uint i = 0; i < pTokens.length; i++) {
            if (pTokens[i] == Registry(registry).pETH()) {
                continue;
            }

            asset = PErc20Interface(pTokens[i]).underlying();

            if (isNewAsset(asset)) {
                update(asset);
            }
        }
    }

    function getUnderlyingPrice(address pToken) public view override virtual returns (uint) {
        if (pToken == Registry(registry).pETH()) {
            return getPriceInUSD(Registry(registry).pETH());
        }

        address asset = PErc20Interface(pToken).underlying();
        uint price = getPriceInUSD(asset);
        uint decimals = EIP20Interface(asset).decimals();

        return price.mul(10 ** (36 - decimals)).div(1e18);
    }

    function isNewAsset(address asset) public view returns (bool) {
        return bool(cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious == 0);
    }

    function getPoolPair(address asset, uint poolId) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(poolFactories[poolId]);

        return factory.getPair(WETHToken, asset);
    }

    function getPoolPairWithStableCoin(address asset, uint poolId, uint stableCoinId) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(poolFactories[poolId]);

        return factory.getPair(stableCoins[stableCoinId], asset);
    }

    function getReservesFromPair(address asset) public view returns (uint112, uint112, uint32) {
        uint112 assetReserve;
        uint112 ethOrCoinReserves;
        uint32 blockTimeStamp;

        IUniswapV2Pair pair = IUniswapV2Pair(assetPair[asset]);

        address token0 = pair.token0();

        if (token0 == asset) {
            (assetReserve, ethOrCoinReserves, blockTimeStamp) = pair.getReserves();
        } else {
            (ethOrCoinReserves, assetReserve, blockTimeStamp) = pair.getReserves();
        }

        return (assetReserve, ethOrCoinReserves, blockTimeStamp);
    }

    function isPeriodElapsed(address asset) public view returns (bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(assetPair[asset]);

        ( , , uint32 blockTimeStamp) = pair.getReserves();

        uint timeElapsed = uint(blockTimeStamp).sub(uint(cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious));

        return bool(timeElapsed > period);
    }

    function calcCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        uint power = EIP20Interface(asset).decimals();
        uint amountIn = 10**power;

        return getETHAmount(asset, amountIn);
    }

    function getETHAmount(address asset, uint amountIn) public view returns (uint) {
        address pair = assetPair[asset];

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint power;
        uint result = cumulativePrices[pair][asset].priceAverage.mul(amountIn).decode144();

        if (token0 == WETHToken || token1 == WETHToken) {
            // asset and weth pool
            return result;
        } else {
            // asset and stable coin pool
            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                return result.mul(getCourseInETH(token1)).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                return result.mul(getCourseInETH(token0)).div(10**power);
            }
        }
    }

    function searchPair(address asset) public view returns (address, uint112) {
        address pair;
        uint112 maxReserves;

        IUniswapV2Pair tempPair;
        uint112 ETHReserves;

        for (uint i = 0; i < poolFactories.length; i++) {
            tempPair = IUniswapV2Pair(getPoolPair(asset, i));

            if (address(tempPair) != address(0)) {
                if (tempPair.token0() == asset) {
                    (, ETHReserves, ) = tempPair.getReserves();
                } else {
                    (ETHReserves, , ) = tempPair.getReserves();
                }

                if (ETHReserves > maxReserves) {
                    maxReserves = ETHReserves;
                    pair = address(tempPair);
                }
            }

            for (uint j = 0; j < stableCoins.length; j++) {
                tempPair = IUniswapV2Pair(getPoolPairWithStableCoin(asset, i, j));

                if (address(tempPair) != address(0)) {
                    uint112 stableCoinReserve;
                    uint power;

                    address token0 = tempPair.token0();
                    address token1 = tempPair.token1();

                    if (token0 == asset) {
                        (, stableCoinReserve,) = tempPair.getReserves();
                        power = EIP20Interface(token1).decimals();
                        ETHReserves = uint112(getCourseInETH(token1) * stableCoinReserve / (10**power));
                    } else {
                        (stableCoinReserve, , ) = tempPair.getReserves();
                        power = EIP20Interface(token0).decimals();
                        ETHReserves = uint112(getCourseInETH(token0) * stableCoinReserve / (10**power));
                    }

                    if (ETHReserves > maxReserves) {
                        maxReserves = ETHReserves;
                        pair = address(tempPair);
                    }
                }
            }
        }

        return (pair, maxReserves);
    }

    function _setNewAddresses(address WETHToken_, address ETHUSDPriceFeed_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        WETHToken = WETHToken_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;

        return uint(Error.NO_ERROR);
    }

    function _setMinReserveLiquidity(uint minReserveLiquidity_) public returns (uint) {
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        minReserveLiquidity = minReserveLiquidity_;

        return uint(Error.NO_ERROR);
    }

    function _setPeriod(uint period_) public returns (uint) {
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        period = period_;

        return uint(Error.NO_ERROR);
    }

    function _addPool(address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        poolFactories.push(poolFactory_);
        uint poolId = poolFactories.length - 1;

        emit PoolAdded(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _removePool(uint poolId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactories.length > 1
            , 'Oracle: must have one pool'
        );

        uint lastId = poolFactories.length - 1;

        address factory = poolFactories[lastId];
        poolFactories.pop();
        emit PoolRemoved(lastId, factory);

        if (lastId != poolId) {
            poolFactories[poolId] = factory;
            emit PoolUpdated(poolId, factory);
        }

        return uint(Error.NO_ERROR);
    }

    function _updatePool(uint poolId, address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        poolFactories[poolId] = poolFactory_;

        emit PoolUpdated(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _addStableCoin(address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            stableCoin_ != address(0)
            , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        stableCoins.push(stableCoin_);

        emit StableCoinAdded(stableCoins.length - 1, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function _removeStableCoin(uint coinId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoins.length > 0
            , 'Oracle: stable coins are empty'
        );


        uint lastId = stableCoins.length - 1;

        address stableCoin = stableCoins[lastId];
        stableCoins.pop();
        emit StableCoinRemoved(lastId, stableCoin);

        if (lastId != coinId) {
            stableCoins[coinId] = stableCoin;
            emit StableCoinUpdated(coinId, stableCoin);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateStableCoin(uint coinId, address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoin_ != address(0)
            , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        stableCoins[coinId] = stableCoin_;

        emit StableCoinUpdated(coinId, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function _updateAssetPair(address asset, address pair) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            pair != address(0)
            , 'Oracle: invalid address for pair'
        );

        cumulativePrices[assetPair[asset]][asset].priceAverage._x = 0;
        cumulativePrices[assetPair[asset]][asset].priceCumulativePrevious = 0;
        cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious = 0;

        assetPair[asset] = pair;

        emit AssetPairUpdated(asset, pair);

        return update(asset);
    }

    function getAllPoolFactories() public view returns (address[] memory) {
        return poolFactories;
    }

    function getAllStableCoins() public view returns (address[] memory) {
        return stableCoins;
    }

    function getMyAdmin() public view returns (address) {
        return Registry(registry).admin();
    }

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal view returns (uint224 z) {
        z = uint224(y) * uint224(Q112); // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }

}