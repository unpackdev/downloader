// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./ISwapRouter.sol";
import "./IUniswapV3Pool.sol";
import "./IFactory.sol";
import "./IStrategy.sol";


contract SingleIntervalStrategy is IStrategy, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Config {
        address uniswapLp;
        int24 tickSpacing;
        int24 boundaryThreshold;
        int24 reBalanceThreshold;
        uint8 direction; // 0-upOnly 1-downOnly 2-up&down
        uint8 protocolFee;
        bool isSwap; // false-use 500 pool    true-use same pool
    }
    mapping(address => Config) public configs;

    struct Position {
        bool isInit;
        int24 lowerTick;
        int24 upperTick;
    }
    mapping(address => Position) public positions;

    ISwapRouter router;
    IFactory factory;
    address dev;

    mapping(address => bool) whiteLists;
    mapping(address => bool) occupyStatus;

    constructor(address _router, address _factory, address _dev) {
        router = ISwapRouter(_router);
        factory = IFactory(_factory);
        dev = _dev;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyWhiteList {
        require(whiteLists[msg.sender], "onlyWhiteList Vault");
        _;
    }

    /* ========== ONLY ========== */

    function setVault(address vault, bool status) external onlyOwner {
        whiteLists[vault] = status;
    }

    function setDev(address _dev) external onlyOwner {
        require(_dev != address(0), 'zero Address!');
        dev = _dev;
    }

    function addConfig(bytes calldata data) external override onlyWhiteList {
        // Check status
        Config storage config = configs[msg.sender];
        require(config.uniswapLp == address(0), "already have configuration!");
        // decode
        (address poolAddress, int24 boundaryThreshold, int24 reBalanceThreshold, uint8 direction, uint8 protocolFee, bool isSwap) =
        abi.decode(data, (address, int24, int24, uint8, uint8, bool));
        // check occupy status
        require(!occupyStatus[poolAddress], "Already Occupied!");
        occupyStatus[poolAddress] = true;
        // approve router
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        IERC20(pool.token0()).safeApprove(address(router), uint256(0));
        IERC20(pool.token0()).safeApprove(address(router), uint256(-1));
        IERC20(pool.token1()).safeApprove(address(router), uint256(0));
        IERC20(pool.token1()).safeApprove(address(router), uint256(-1));
        // save config
        config.uniswapLp = poolAddress;
        config.tickSpacing = pool.tickSpacing();
        boundaryThreshold = _floor(boundaryThreshold, config.tickSpacing);
        config.boundaryThreshold = boundaryThreshold;
        config.reBalanceThreshold = reBalanceThreshold;
        config.direction = direction;
        config.protocolFee = protocolFee;
        config.isSwap = isSwap;
    }

    function changeConfig(bytes calldata data) external override onlyWhiteList {
        // Check status
        Config storage config = configs[msg.sender];
        require(config.uniswapLp != address(0), "add config first!");
        // decode
        (int24 boundaryThreshold, int24 reBalanceThreshold, uint8 direction, uint8 protocolFee, bool isSwap) =
        abi.decode(data, (int24, int24, uint8, uint8, bool));
        // save config
        boundaryThreshold = _floor(boundaryThreshold, config.tickSpacing);
        config.boundaryThreshold = boundaryThreshold;
        config.reBalanceThreshold = reBalanceThreshold;
        config.direction = direction;
        config.protocolFee = protocolFee;
        config.isSwap = isSwap;
    }

    function changeDirection(uint8 direction) external override onlyWhiteList {
        // Check status
        Config storage config = configs[msg.sender];
        require(config.uniswapLp != address(0), "have no config!");
        config.direction = direction;
    }

    /* ========== PURE ========== */

    function _toUint128(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    function _floor(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    /* ========== VIEW ========== */

    function _getAmountOut(
        IUniswapV3Pool pool,
        uint256 amount0,
        uint256 amount1,
        uint256 reserve0,
        uint256 reserve1
    ) internal view returns(uint256 amt, address token) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        uint256 priceX96 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);
        if (amount0.mul(reserve1) >= amount1.mul(reserve0)) {
            uint256 dividend = amount0.mul(reserve1) - amount1.mul(reserve0);
            uint256 divisor = FullMath.mulDiv(priceX96, reserve0, FixedPoint96.Q96).add(reserve1);
            amt = dividend.div(divisor);
            token = pool.token0();
        } else {
            uint256 dividend = amount1.mul(reserve0) - amount0.mul(reserve1);
            uint256 divisor = FullMath.mulDiv(reserve1, FixedPoint96.Q96, priceX96).add(reserve0);
            amt = dividend.div(divisor);
            token = pool.token1();
        }
    }

    function _positionInfo(
        IUniswapV3Pool pool,
        Position memory position
    ) internal view returns (uint128, uint256, uint256) {
        // check status
        if (!position.isInit) {return (0, 0, 0);}
        // query liquidity
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), position.lowerTick, position.upperTick));
        (uint128 liquidity, , , uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(positionKey);
        // get amount0 amount1
        (uint256 amount0, uint256 amount1) = _amountsForLiquidity(pool, position.lowerTick, position.upperTick, liquidity);
        amount0 = amount0.add(tokensOwed0);
        amount1 = amount1.add(tokensOwed1);
        return (liquidity, amount0, amount1);
    }

    function _amountsForLiquidity(
        IUniswapV3Pool pool,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
        LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(lowerTick),
            TickMath.getSqrtRatioAtTick(upperTick),
            liquidity
        );
    }

    function _liquidityForAmounts(
        IUniswapV3Pool pool,
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
        LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(lowerTick),
            TickMath.getSqrtRatioAtTick(upperTick),
            amount0,
            amount1
        );
    }

    function _getReBalanceTicks(
        IUniswapV3Pool pool,
        Config memory config
    ) internal view returns (bool, int24, int24) {
        // calculate bias
        (uint160 sqrtPrice, , , , , , ) = pool.slot0();
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPrice);
        // get Position info
        Position memory position = positions[msg.sender];
        int24 lowerTick = position.lowerTick;
        int24 upperTick = position.upperTick;
        int24 middleTick = (lowerTick + upperTick) / 2;
        // get status
        bool status;
        if (!position.isInit) {
            status = true;
        } else if (config.direction == 0) {
            if (tick - middleTick >= config.reBalanceThreshold) {
                status = true;
            }
        } else if (config.direction == 1) {
            if (middleTick - tick >= config.reBalanceThreshold) {
                status = true;
            }
        } else {
            if (middleTick - tick >= config.reBalanceThreshold || tick - middleTick >= config.reBalanceThreshold) {
                status = true;
            }
        }
        // get new ticks
        if (status) {
            middleTick = _floor(tick, config.tickSpacing);
            lowerTick = middleTick - config.boundaryThreshold;
            upperTick = middleTick + config.boundaryThreshold;
        }
        return (status, lowerTick, upperTick);
    }

    function checkReBalanceStatus() external view override returns (bool) {
        // Check status
        Config memory config = configs[msg.sender];
        // get Pool
        IUniswapV3Pool pool = IUniswapV3Pool(config.uniswapLp);
        // get status
        (bool status, , ) = _getReBalanceTicks(pool, config);
        return status;
    }

    function getTotalAmounts() public view override returns (uint128, uint256, uint256) {
        // get Config info
        Config memory config = configs[msg.sender];
        // get Position info
        Position memory position = positions[msg.sender];
        // get Pool
        IUniswapV3Pool pool = IUniswapV3Pool(config.uniswapLp);
        // get position info
        return _positionInfo(pool, position);
    }

    /* ========== INTERNAL ========== */

    function _collectProtocolFee(IUniswapV3Pool pool, uint256 feesFromPool0, uint256 feesFromPool1, uint8 protocolFee) internal {
        if (protocolFee == 0) {return;}
        if (feesFromPool0 > 0) {
            IERC20 token0 = IERC20(pool.token0());
            uint256 feesToProtocol0 = feesFromPool0.div(uint256(protocolFee));
            token0.safeTransfer(dev, feesToProtocol0);
        }
        if (feesFromPool1 > 0) {
            IERC20 token1 = IERC20(pool.token1());
            uint256 feesToProtocol1 = feesFromPool1.div(uint256(protocolFee));
            token1.safeTransfer(dev, feesToProtocol1);
        }
    }

    function _positionInit(IUniswapV3Pool pool, Config memory config) internal {
        // get position info
        Position storage position = positions[msg.sender];
        if (position.isInit) {return;}
        // get New Ticks
        (uint160 sqrtPrice, , , , , , ) = pool.slot0();
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPrice);
        tick = _floor(tick, config.tickSpacing);
        // update position
        position.lowerTick = tick - config.boundaryThreshold;
        position.upperTick = tick + config.boundaryThreshold;
        position.isInit = true;
    }

    function _addLiquidity(IUniswapV3Pool pool, int24 lowerTick, int24 upperTick) internal {
        // get balance0 & balance1
        uint256 balance0 = IERC20(pool.token0()).balanceOf(address(this));
        uint256 balance1 = IERC20(pool.token1()).balanceOf(address(this));
        // add Liquidity on Uniswap
        uint128 liquidity = _liquidityForAmounts(pool, lowerTick, upperTick, balance0, balance1);
        if (liquidity > 0) {
            pool.mint(
                address(this),
                lowerTick,
                upperTick,
                liquidity,
                abi.encode(pool.token0(), pool.token1(), pool.fee())
            );
        }
    }

    function _burnLiquidity(IUniswapV3Pool pool, uint128 liquidity, address to) internal returns (uint256, uint256) {
        // get position info
        Position memory position = positions[msg.sender];
        // Burn
        (uint256 amount0, uint256 amount1) = pool.burn(position.lowerTick, position.upperTick, liquidity);
        // Collect
        if (amount0 > 0 || amount1 > 0) {
            (amount0, amount1) = pool.collect(
                to,
                position.lowerTick,
                position.upperTick,
                _toUint128(amount0),
                _toUint128(amount1)
            );
        }
        return (amount0, amount1);
    }

    function _swap(address tokenIn, address tokenOut, uint256 amountIn, uint24 swapPoolFee) internal {
        // swap params
        ISwapRouter.ExactInputSingleParams memory param;
        param.tokenIn = tokenIn;
        param.tokenOut = tokenOut;
        param.fee = swapPoolFee;
        param.recipient = address(this);
        param.deadline = block.timestamp;
        param.amountIn = amountIn;
        // swap using router
        uint256 amountOut = router.exactInputSingle(param);
        // event
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function _trim(IUniswapV3Pool pool, bool isSwap, int24 lowerTick, int24 upperTick) internal {
        // get balance
        uint256 balance0 = IERC20(pool.token0()).balanceOf(address(this));
        uint256 balance1 = IERC20(pool.token1()).balanceOf(address(this));
        if (balance0 == 0 && balance1 == 0) {return;}
        // calculate token0/token1
        (uint160 sqrtPrice, , , , , , ) = pool.slot0();
        uint160 sqrtPriceA = TickMath.getSqrtRatioAtTick(lowerTick);
        uint160 sqrtPriceB = TickMath.getSqrtRatioAtTick(upperTick);
        (uint256 balanceBal0, uint256 balanceBal1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPrice, sqrtPriceA, sqrtPriceB, 1E20);
        require(balanceBal0 != 0 && balanceBal1 != 0, "out of band!");
        // cal swap amount
        (uint256 amt, address tokenIn) = _getAmountOut(pool, balance0, balance1, balanceBal0, balanceBal1);
        address tokenOut;
        if (tokenIn == pool.token0()) {
            tokenOut = pool.token1();
        } else {
            tokenOut = pool.token0();
        }
        // swap
        uint24 swapFee = pool.fee();
        if (!isSwap) {swapFee = 500;}
        _swap(tokenIn, tokenOut, amt, swapFee);
    }

    function _burnAll(IUniswapV3Pool pool, Position memory position) internal returns (uint256, uint256) {
        // Burn ALL
        uint256 owed0;
        uint256 owed1;
        (uint128 liquidity, , ) = _positionInfo(pool, position);
        if (liquidity > 0) {
            (owed0, owed1) = pool.burn(position.lowerTick, position.upperTick, liquidity);
        }
        // Collect All
        (uint256 collect0, uint256 collect1) = pool.collect(
            address(this),
            position.lowerTick,
            position.upperTick,
            type(uint128).max,
            type(uint128).max
        );
        return (collect0.sub(owed0), collect1.sub(owed1));
    }

    /* ========== PUBLIC ========== */

    function updateCommission(IUniswapV3Pool pool) public override {
        // get Position info
        Position memory position = positions[msg.sender];
        // burn 0
        (uint128 liquidity, , ) = _positionInfo(pool, position);
        if (liquidity > 0) {
            pool.burn(position.lowerTick, position.upperTick, 0);
        }
    }

    /* ========== EXTERNAL ========== */

    function mining() external override onlyWhiteList {
        // check config
        Config memory config = configs[msg.sender];
        // get Pool
        IUniswapV3Pool pool = IUniswapV3Pool(config.uniswapLp);
        // INIT Position if need
        _positionInit(pool, config);
        // get position info
        Position memory position = positions[msg.sender];
        // trim token0 token1
        _trim(pool, config.isSwap, position.lowerTick, position.upperTick);
        // add Liquidity
        _addLiquidity(pool, position.lowerTick, position.upperTick);
        // send change back
        IERC20 token0 = IERC20(pool.token0());
        IERC20 token1 = IERC20(pool.token1());
        if (token0.balanceOf(address(this)) > 0) {
            token0.safeTransfer(msg.sender, token0.balanceOf(address(this)));
        }
        if (token1.balanceOf(address(this)) > 0) {
            token1.safeTransfer(msg.sender, token1.balanceOf(address(this)));
        }
    }

    function stopMining(uint128 liq, address to) external override returns(uint256, uint256) {
        // check config
        Config memory config = configs[msg.sender];
        // get Pool
        IUniswapV3Pool pool = IUniswapV3Pool(config.uniswapLp);
        // Burn liquidity
        return _burnLiquidity(pool, liq, to);
    }

    function reBalance() external override returns (bool, uint256, uint256, int24, int24) {
        // Check status
        Config storage config = configs[msg.sender];
        // get Pool
        IUniswapV3Pool pool = IUniswapV3Pool(config.uniswapLp);
        // get New Ticks
        (bool status , int24 lowerTick, int24 upperTick) = _getReBalanceTicks(pool, config);
        if (!status) {return (status, 0, 0, lowerTick, upperTick);}
        // get Position info
        Position storage position = positions[msg.sender];
        // Burn All
        (uint256 feesFromPool0, uint256 feesFromPool1) = _burnAll(pool, position);
        // collect Fee
        _collectProtocolFee(pool, feesFromPool0, feesFromPool1, config.protocolFee);
        // update position
        position.lowerTick = lowerTick;
        position.upperTick = upperTick;
        return (status, feesFromPool0, feesFromPool1, lowerTick, upperTick);
    }

    function collectCommission(
        IUniswapV3Pool pool,
        address to
    ) external override returns (uint256 collect0, uint256 collect1) {
        if (to == address(0)) {
            to = address(this);
        }
        // get Config info
        Config memory config = configs[msg.sender];
        // get Position info
        Position memory position = positions[msg.sender];
        // collect to vault
        if (position.isInit) {
            (collect0, collect1) = pool.collect(
                to,
                position.lowerTick,
                position.upperTick,
                type(uint128).max,
                type(uint128).max
            );
            if (to == address(this)) {_collectProtocolFee(pool, collect0, collect1, config.protocolFee);}
        }
    }

    /* ========== CALLBACK ========== */

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // decode
        (address token0, address token1, uint24 fee) = abi.decode(data, (address, address, uint24));
        // check
        require(msg.sender == factory.getPool(token0, token1, fee), "wrong address");
        // transfer
        if (amount0 > 0) {IERC20(token0).safeTransfer(msg.sender, amount0);}
        if (amount1 > 0) {IERC20(token1).safeTransfer(msg.sender, amount1);}
    }

    /* ========== EVENT ========== */

    event Swap(
        address indexed vault,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

}
