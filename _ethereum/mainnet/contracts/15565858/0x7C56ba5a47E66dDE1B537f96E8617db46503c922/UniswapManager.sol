// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV3Pool.sol";
import "./IUniswapV3PoolActions.sol";

import "./AipPayments.sol";
import "./UniswapPoolAddress.sol";
import "./UniswapCallbackValidation.sol";
import "./SafeCast.sol";
import "./LowGasSafeMath.sol";
import "./IAipSwapManager.sol";
import "./IERC20.sol";

// import "./Simulation.sol";

// import "./console.sol";

contract UniswapManager is IAipSwapManager, AipPayments {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    address public immutable swapFactory;
    uint16[3] private _FEES = [500, 3000, 10000];
    uint256 private constant _MAX_CALC_SQRT_PRICE = 3.4e29; // sqrt((2 ^ 256 - 1) / 1e18) = 3.4028E29
    uint160 private constant _MIN_SQRT_RATIO = 4295128739;
    uint160 private constant _MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    constructor(address _swapFactory, address _WETH9) AipPayments(_WETH9) {
        swapFactory = _swapFactory;
    }

    // modifier checkDeadline(uint256 deadline) {
    //     require(block.timestamp <= deadline, "Transaction too old");
    //     _;
    // }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _calculatePrice(uint160 _sqrtPriceX96)
        internal
        pure
        returns (uint256)
    {
        if (_sqrtPriceX96 > _MAX_CALC_SQRT_PRICE) {
            return
                (uint256(_sqrtPriceX96).mul(uint256(_sqrtPriceX96)) >> (96 * 2))
                    .mul(1e18);
        }
        return (uint256(_sqrtPriceX96).mul(uint256(_sqrtPriceX96)).mul(1e18) >>
            (96 * 2));
    }

    function bestLiquidityPool(address token0, address token1)
        external
        view
        override
        returns (address pool, uint256 price)
    {
        uint256 L;
        for (uint256 i = 0; i < 3; i++) {
            uint24 _fee = uint24(_FEES[i]);
            address poolAddress = UniswapPoolAddress.computeAddress(
                swapFactory,
                UniswapPoolAddress.getPoolKey(token0, token1, _fee)
            );

            if (_isContract(poolAddress)) {
                IUniswapV3Pool _pool = IUniswapV3Pool(poolAddress);
                uint128 _L = _pool.liquidity();
                if (_L > L) {
                    L = _L;
                    pool = poolAddress;
                    (uint160 _sqrtPriceX96, , , , , , ) = _pool.slot0();
                    price = _calculatePrice(_sqrtPriceX96);
                }
            }
        }
        if (token0 > token1 && price > 0) {
            price = (1e18 * 1e18) / price;
        }
    }

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) public view override returns (address pool) {
        pool = UniswapPoolAddress.computeAddress(
            swapFactory,
            UniswapPoolAddress.getPoolKey(token0, token1, fee)
        );
        require(_isContract(pool));
    }

    function poolPrice(
        address token0,
        address token1,
        uint24 fee
    ) external view override returns (uint256 price) {
        address poolAddress = getPool(token0, token1, fee);
        IUniswapV3Pool _pool = IUniswapV3Pool(poolAddress);
        (uint160 _sqrtPriceX96, , , , , , ) = _pool.slot0();
        price = _calculatePrice(_sqrtPriceX96);
        if (token0 > token1 && price > 0) {
            price = (1e18 * 1e18) / price;
        }
    }

    function swap(
        address token0,
        address token1,
        uint24 fee,
        address recipient,
        bool zeroForOne,
        uint256 amount
    ) external override returns (int256 amount0, int256 amount1) {
        if (token0 > token1) {
            // (token0, token1) = (token1, token0);
            zeroForOne = !zeroForOne;
        }
        address poolAddress = getPool(token0, token1, fee);
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        (amount0, amount1) = IUniswapV3Pool(pool).swap(
            recipient,
            zeroForOne,
            int256(amount),
            zeroForOne ? _MIN_SQRT_RATIO + 1 : _MAX_SQRT_RATIO - 1,
            abi.encode(
                msg.sender,
                zeroForOne ? amount : 0,
                zeroForOne ? 0 : amount
            )
        );

        if (token0 > token1) {
            (amount0, amount1) = (amount1, amount0);
        }
        // console.logInt(amount0);
        // console.logInt(amount1);
    }

    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external {
        (address sender, uint256 pay0, uint256 pay1) = abi.decode(
            data,
            (address, uint256, uint256)
        );
        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();
        uint24 fee = IUniswapV3Pool(msg.sender).fee();

        UniswapCallbackValidation.verifyCallback(
            swapFactory,
            token0,
            token1,
            fee
        );
        if (pay0 > 0) {
            pay(token0, sender, msg.sender, uint256(pay0));
        } else if (pay1 > 0) {
            pay(token1, sender, msg.sender, uint256(pay1));
        }
    }
}
