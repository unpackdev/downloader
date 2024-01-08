// contracts/Adjuster.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RC.sol";
import "./FullMath.sol";
import "./IUniswapV2Pair.sol";
import "./TransferHelper.sol";
import "./Babylonian.sol";
import "./Ownable.sol";

contract Adjuster is Ownable {
    uint256 public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 public constant FIXED_POINT_BASIS = 10**18;
    RC private _rc;
    address private _treasury;
    uint256 private _productionCost;
    uint256 private _productionCostRate;
    uint256 private _productionCostTimestamp;
    mapping(address => bool) private _isAllowedPair;

    /**
     * Emits when a pair adjusted
     */
    event Adjusted(
        uint256 productionCost,
        uint256 rcReserveBefore,
        uint256 stableReserveBefore,
        uint256 rcReserveAfter,
        uint256 stableReserveAfter
    );

    constructor(
        RC rc,
        address treasury,
        uint256 productionCost,
        uint256 productionCostRate,
        uint256 productionCostTimestamp
    ) {
        _rc = rc;
        _treasury = treasury;
        _productionCost = productionCost;
        _productionCostRate = productionCostRate;
        _productionCostTimestamp = productionCostTimestamp;
        transferOwnership(treasury);
    }

    /**
     * Given a Uniswap pair,
     * adds it to the allowed list
     */
    function addAllowedPair(IUniswapV2Pair pair) public onlyOwner {
        require(
            pair.token0() == address(_rc) || pair.token1() == address(_rc),
            "Adjuster: NOT_RC_PAIR"
        );
        _isAllowedPair[address(pair)] = true;
    }

    /**
     * Given a Uniswap pair,
     * removes it from the allowed list
     */
    function removeAllowedPair(IUniswapV2Pair pair) public onlyOwner {
        _isAllowedPair[address(pair)] = false;
    }

    /**
     * Given a Uniswap pair,
     * adjusts the market price if its higher than production costs
     *
     * msg.sender will receive reward for the transaction
     */
    function adjust(IUniswapV2Pair pair, uint256 minReward) public {
        // Only externally owned accounts allowed
        // Smart contracts can't trigger adjuster
        require(msg.sender == tx.origin, "Adjuster: ONLY_EOA_ALLOWED");

        // Check if it's a valid pair
        require(_isAllowedPair[address(pair)], "Adjuster: PAIR_NOT_ALLOWED");

        // Calculate and update current production cost
        uint256 daysDiff =
            getDaysDiff(_productionCostTimestamp, block.timestamp);
        if (daysDiff > 0) {
            _productionCost = FullMath.mulDiv(
                _productionCost,
                pow(_productionCostRate, daysDiff),
                FIXED_POINT_BASIS
            );
            _productionCostTimestamp =
                _productionCostTimestamp +
                (daysDiff * (1 days));
        }

        // Calculate RC amount to swap and check if adjust requireds
        (uint256 rcReserveBefore, uint256 stableReserveBefore) =
            getReserves(pair);
        (bool adjustRequired, uint256 rcIn) =
            getAmountIn(
                _productionCost,
                uint256(rcReserveBefore),
                uint256(stableReserveBefore)
            );
        require(adjustRequired && rcIn > 0, "Adjuster: ADJUST_NOT_REQUIRED");

        // Calculate and check if reward is enough
        uint256 stableOut =
            getAmountOut(rcIn, rcReserveBefore, stableReserveBefore);
        uint256 reward = stableOut / 10;
        require(reward >= minReward, "Adjuster: REWARD_NOT_ENOUGH");

        // Mint RC and swap on Uniswap
        _rc.mint(address(pair), rcIn);
        pair.swap(
            pair.token0() == address(_rc) ? 0 : stableOut,
            pair.token0() == address(_rc) ? stableOut : 0,
            address(this),
            new bytes(0)
        );

        // Transfer reward to the user
        address stableAddress =
            pair.token0() == address(_rc) ? pair.token1() : pair.token0();
        TransferHelper.safeTransfer(stableAddress, msg.sender, reward);

        // Mint RC and add liquidity on Uniswap, transfer pool tokens to the treasury
        (uint256 rcReserveAfter, uint256 stableReserveAfter) =
            getReserves(pair);
        uint256 stableLiquidity = stableOut - reward;
        TransferHelper.safeTransfer(
            stableAddress,
            address(pair),
            stableLiquidity
        );
        _rc.mint(
            address(pair),
            quoteB(stableLiquidity, rcReserveAfter, stableReserveAfter)
        );
        pair.mint(_treasury);

        emit Adjusted(
            _productionCost,
            rcReserveBefore,
            stableReserveBefore,
            rcReserveAfter,
            stableReserveAfter
        );
    }

    /**
     * Returns current production cost, market price and rewards
     * so that adjusters can determine to trigger or not
     *
     * This function is called on remote node for Rising Coin Interface Adjust page
     */
    function adjustCalc(IUniswapV2Pair pair)
        public
        view
        returns (
            uint256 productionCost,
            uint256 marketPrice,
            uint256 reward
        )
    {
        require(_isAllowedPair[address(pair)], "Adjuster: PAIR_NOT_ALLOWED");

        // Calculate current production cost
        uint256 daysDiff =
            getDaysDiff(_productionCostTimestamp, block.timestamp);
        if (daysDiff > 0) {
            productionCost = FullMath.mulDiv(
                _productionCost,
                pow(_productionCostRate, daysDiff),
                FIXED_POINT_BASIS
            );
        } else {
            productionCost = _productionCost;
        }

        // Calculate current market price
        (uint256 rcReserve, uint256 stableReserve) = getReserves(pair);
        marketPrice = FullMath.mulDiv(
            uint256(stableReserve),
            FIXED_POINT_BASIS,
            uint256(rcReserve)
        );

        // Calculate current reward
        (bool adjustRequired, uint256 rcIn) =
            getAmountIn(
                productionCost,
                uint256(rcReserve),
                uint256(stableReserve)
            );
        if (adjustRequired && rcIn > 0) {
            uint256 stableOut = getAmountOut(rcIn, rcReserve, stableReserve);
            reward = stableOut / 10;
        }
    }

    /**
     * Given two timestamps, returns how many days passed between them.
     */
    function getDaysDiff(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        _days = (fromTimestamp >= toTimestamp) ? 0 : (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    /**
     * Given a Uniswap pair, return reserve of rc and stable coin
     */
    function getReserves(IUniswapV2Pair pair)
        internal
        view
        returns (uint256 rcReserve, uint256 stableReserve)
    {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        if (pair.token0() == address(_rc)) {
            rcReserve = uint256(reserve0);
            stableReserve = uint256(reserve1);
        } else {
            rcReserve = uint256(reserve1);
            stableReserve = uint256(reserve0);
        }
    }

    /**
     * Given true price of an asset and pair reserves,
     * returns the input amount of the asset with adjust required flag
     */
    function getAmountIn(
        uint256 truePriceA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (bool adjustRequired, uint256 amountIn) {
        if (
            FullMath.mulDiv(reserveA, truePriceA, reserveB) < FIXED_POINT_BASIS
        ) {
            uint256 invariant = reserveA * reserveB;
            uint256 leftSide =
                Babylonian.sqrt(
                    FullMath.mulDiv(invariant, FIXED_POINT_BASIS, truePriceA)
                );
            uint256 rightSide = reserveA;
            amountIn = leftSide - rightSide;
            return (true, amountIn);
        }
        return (false, 0);
    }

    /**
     * Given an input amount of an asset and pair reserves,
     * returns the maximum output amount of the other asset
     *
     * Taken from UniswapV2Router02
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * Given some amount of an asset and pair reserves,
     * returns an equivalent amount of the other asset
     *
     * Taken from UniswapV2Router02
     */
    function quoteB(
        uint256 amountB,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountA) {
        require(amountB > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountA = FullMath.mulDiv(amountB, reserveA, reserveB);
    }

    /**
     * Given a base and an exponent,
     * returns the base raised to exponent aka power.
     *
     * Base is fixed floating point which has same decimals with FIXED_POINT_BASIS
     */
    function pow(uint256 base, uint256 exponent)
        internal
        pure
        returns (uint256)
    {
        if (exponent == 0) {
            return FIXED_POINT_BASIS;
        } else if (exponent == 1) {
            return base;
        } else {
            uint256 p = pow(base, exponent / 2);
            p = FullMath.mulDiv(p, p, FIXED_POINT_BASIS);
            if (exponent % 2 == 1) {
                p = FullMath.mulDiv(p, base, FIXED_POINT_BASIS);
            }
            return p;
        }
    }
}
