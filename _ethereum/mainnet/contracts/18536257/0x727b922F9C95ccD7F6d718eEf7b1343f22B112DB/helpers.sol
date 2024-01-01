// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
import "./variables.sol";
import "./Utils.sol";
import "./WadRayMath.sol";

contract Helpers is Variables {
    using WadRayMath for uint256;

    function convertWstethRateForSteth(
        uint256 wstEthSupplyRate,
        uint256 stEthPerWsteth_
    ) public pure returns (uint256) {
        return (wstEthSupplyRate * 1e18) / stEthPerWsteth_;
    }

    function getAaveV2Rates()
        public
        view
        returns (uint256 stETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Steth supply rate = 0. Add Lido APR.
        (, , , stETHSupplyRate_, , , , , , ) = AAVE_V2_DATA.getReserveData(
            STETH_ADDRESS
        );

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , wethBorrowRate_, , , , , ) = AAVE_V2_DATA.getReserveData(
            WETH_ADDRESS
        );

        stETHSupplyRate_ = ((stETHSupplyRate_ * 1e6) / 1e27);
        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e27);
    }

    function getAaveV3Rates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Add staking apr to the supply rate.
        (, , , , , wstETHSupplyRate_, , , , , , ) = AAVE_V3_DATA.getReserveData(
            WSTETH_ADDRESS
        );

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , , , wethBorrowRate_, , , , , ) = AAVE_V3_DATA.getReserveData(
            WETH_ADDRESS
        );

        wstETHSupplyRate_ = ((wstETHSupplyRate_ * 1e6) / 1e27);
        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e27);
    }

    function getCompoundV3Rates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        uint256 utilization_ = COMPOUND_V3_DATA.getUtilization();

        // Only base token has a supply rate. Add Lido staking APR.
        wstETHSupplyRate_ = 0;

        // The per-second borrow rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
        wethBorrowRate_ = COMPOUND_V3_DATA.getBorrowRate(utilization_);

        // The per-year borrow rate scaled up by 10 ^ 18
        wethBorrowRate_ = wethBorrowRate_ * 60 * 60 * 24 * 365;

        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e18);
    }

    function getEulerRates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // This is the base supply rate (IN RAY). Add Lido APR
        (, , wstETHSupplyRate_) = EULER_SIMPLE_VIEW.interestRates(
            WSTETH_ADDRESS
        );

        // This is the base borrow rate (IN RAY).
        (, wethBorrowRate_, ) = EULER_SIMPLE_VIEW.interestRates(WETH_ADDRESS);

        // https://etherscan.io/address/0x5077B7642abF198b4a5b7C4BdCE4f03016C7089C#readContract
        wstETHSupplyRate_ = (wstETHSupplyRate_ * 1e6) / 1e27;

        wethBorrowRate_ = (wethBorrowRate_ * 1e6) / 1e27;
    }

    function getMorphoAaveV2Rates()
        public
        view
        returns (
            uint256 stETHSupplyPoolRate_,
            uint256 stETHSupplyP2PRate_,
            uint256 wethBorrowPoolRate_,
            uint256 wethBorrowP2PRate_
        )
    {
        /// stETHSupplyP2PRate_ => market's peer-to-peer supply rate per year (in RAY).
        /// stETHSupplyPoolRate_ => market's pool supply rate per year (in RAY).
        (stETHSupplyP2PRate_, , stETHSupplyPoolRate_, ) = MORPHO_AAVE_LENS
            .getRatesPerYear(A_STETH_ADDRESS);

        /// wethBorrowP2PRate_ => market's peer-to-peer borrow rate per year (in RAY).
        /// wethBorrowPoolRate_ => market's pool borrow rate per year (in RAY).
        (, wethBorrowP2PRate_, , wethBorrowPoolRate_) = MORPHO_AAVE_LENS
            .getRatesPerYear(A_WETH_ADDRESS);

        stETHSupplyP2PRate_ = ((stETHSupplyP2PRate_ * 1e6) / 1e27);
        stETHSupplyPoolRate_ = ((stETHSupplyPoolRate_ * 1e6) / 1e27);
        wethBorrowP2PRate_ = ((wethBorrowP2PRate_ * 1e6) / 1e27);
        wethBorrowPoolRate_ = ((wethBorrowPoolRate_ * 1e6) / 1e27);
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded up.
    /// @param x Ray.
    /// @param y Wad.
    /// @return z The result of x * y, in ray.
    function rayMulUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        uint256 maxUintMinusRayMinusOne = MAX_UINT256_MINUS_RAY_MINUS_ONE;
        uint256 rayMinusOne = RAY_MINUS_ONE;
        // Overflow if
        //     x * y + RAY_MINUS_ONE > type(uint256).max
        // <=> x * y > type(uint256).max - RAY_MINUS_ONE
        // <=> y > 0 and x > (type(uint256).max - RAY_MINUS_ONE) / y
        assembly {
            if mul(y, gt(x, div(maxUintMinusRayMinusOne, y))) {
                revert(0, 0)
            }

            z := div(add(mul(x, y), rayMinusOne), RAY)
        }
    }

    function getMorphoAaveV3Rates()
        public
        view
        returns (
            uint256 wstETHSupplyRate_,
            uint256 wethBorrowPoolRate_,
            uint256 wethBorrowP2PRate_,
            uint256 wethReceivedRate_
        )
    {
        (wstETHSupplyRate_, ) = morphoAaveV3PoolAPR(WSTETH_ADDRESS); // In Ray

        (wethBorrowP2PRate_, wethBorrowPoolRate_) = getP2PAPR(WETH_ADDRESS); // In Ray

        wethReceivedRate_ = borrowAPRUser(WETH_ADDRESS, VAULT_DSA); // In Ray

        wstETHSupplyRate_ = ((wstETHSupplyRate_ * 1e6) / 1e27);
        wethBorrowPoolRate_ = ((wethBorrowPoolRate_ * 1e6) / 1e27);
        wethBorrowP2PRate_ = ((wethBorrowP2PRate_ * 1e6) / 1e27);
        wethReceivedRate_ = ((wethReceivedRate_ * 1e6) / 1e27);
    }

    /// @notice Computes and returns the current borrow rate per year experienced on average on a given market.
    /// @param underlying The address of the underlying asset.
    /// @return p2pBorrowRatePerYear The market's p2p borrow rate per year (in ray).
    ///@return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function getP2PAPR(
        address underlying
    )
        public
        view
        returns (uint256 p2pBorrowRatePerYear, uint256 poolBorrowRatePerYear)
    {
        IMorphoAaveV3.Market memory market = MORPHO_AAVE_V3.market(underlying);
        IMorphoAaveV3.Indexes256 memory indexes = MORPHO_AAVE_V3.updatedIndexes(
            underlying
        );

        uint256 poolSupplyRatePerYear;
        (poolSupplyRatePerYear, poolBorrowRatePerYear) = morphoAaveV3PoolAPR(
            underlying
        );

        p2pBorrowRatePerYear = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRatePerYear,
                poolBorrowRatePerYear: poolBorrowRatePerYear,
                poolIndex: indexes.borrow.poolIndex,
                p2pIndex: indexes.borrow.p2pIndex,
                proportionIdle: 0,
                p2pDelta: 0, // Simpler to account for the delta in the weighted avg.
                p2pTotal: 0,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );
    }

    /// @notice Returns the borrow rate per year a given user is currently experiencing on a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to compute the borrow rate per year for.
    /// @return borrowRatePerYear The borrow rate per year the user is currently experiencing (in ray).
    function borrowAPRUser(
        address underlying,
        address user
    ) internal view returns (uint256 borrowRatePerYear) {
        (uint256 balanceInP2P, uint256 balanceOnPool, ) = borrowBalanceUser(
            underlying,
            user
        );
        (uint256 poolSupplyRate, uint256 poolBorrowRate) = morphoAaveV3PoolAPR(
            underlying
        );

        IMorphoAaveV3.Market memory market = MORPHO_AAVE_V3.market(underlying);
        IMorphoAaveV3.Indexes256 memory indexes = MORPHO_AAVE_V3.updatedIndexes(
            underlying
        );

        uint256 p2pBorrowRate = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRate,
                poolBorrowRatePerYear: poolBorrowRate,
                poolIndex: indexes.borrow.poolIndex,
                p2pIndex: indexes.borrow.p2pIndex,
                proportionIdle: 0,
                p2pDelta: market.deltas.borrow.scaledDelta,
                p2pTotal: market.deltas.borrow.scaledP2PTotal,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        borrowRatePerYear = Utils.weightedRate(
            p2pBorrowRate,
            poolBorrowRate,
            balanceInP2P,
            balanceOnPool
        );
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function borrowBalanceUser(
        address underlying,
        address user
    )
        internal
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        IMorphoAaveV3.Indexes256 memory indexes = MORPHO_AAVE_V3.updatedIndexes(
            underlying
        );

        balanceInP2P = MORPHO_AAVE_V3
            .scaledP2PBorrowBalance(underlying, user)
            .rayMulUp(indexes.borrow.p2pIndex);
        balanceOnPool = MORPHO_AAVE_V3
            .scaledPoolBorrowBalance(underlying, user)
            .rayMulUp(indexes.borrow.poolIndex);
        totalBalance = balanceInP2P + balanceOnPool;
    }

    /// @dev Computes and returns the underlying pool rates for a specific market.
    /// @param underlying The underlying pool market address.
    /// @return poolSupplyRatePerYear The market's pool supply rate per year (in ray).
    /// @return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function morphoAaveV3PoolAPR(
        address underlying
    )
        internal
        view
        returns (uint256 poolSupplyRatePerYear, uint256 poolBorrowRatePerYear)
    {
        IAaveV3Pool.ReserveData memory reserve = AAVE_V3_POOL.getReserveData(
            underlying
        );
        poolSupplyRatePerYear = reserve.currentLiquidityRate;
        poolBorrowRatePerYear = reserve.currentVariableBorrowRate;
    }

    function getSparkRates()
        public
        view
        returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Add staking apr to the supply rate.
        (, , , , , wstETHSupplyRate_, , , , , , ) = SPARK_DATA.getReserveData(
            WSTETH_ADDRESS
        );

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , , , wethBorrowRate_, , , , , ) = SPARK_DATA.getReserveData(
            WETH_ADDRESS
        );

        wstETHSupplyRate_ = ((wstETHSupplyRate_ * 1e6) / 1e27);
        wethBorrowRate_ = ((wethBorrowRate_ * 1e6) / 1e27);
    }
}
