// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./SafeERC20.sol";

import "./ISwapRouter.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./INonfungiblePositionManager.sol";
import "./ISupportedByOracleToken.sol";

import "./CommonLibrary.sol";
import "./UniswapCalculations.sol";

import "./FullMath.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";
import "./PositionValue.sol";

import "./UniV3MEVProtection.sol";

import "./BaseToken.sol";

import "./UniV3TokenRegistry.sol";

contract UniV3Token is BaseToken, IERC721Receiver, ISupportedByOracleToken {
    using SafeERC20 for IERC20;
    error TokenAlreadyInitialized();
    error LimitUnderflow();
    error InvalidState();

    struct InitParams {
        uint256 positionId;
        string name;
        string symbol;
        address admin;
        address strategy;
        address oracle;
        bytes securityParams;
    }

    uint256 public constant MAX_FEES_SWAP_SLIPPAGE = 1 * 10 ** 7; // 1%
    uint256 public constant DENOMINATOR = 10 ** 9;
    uint256 public constant Q96 = 2 ** 96;

    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable factory;
    ISwapRouter public immutable router;
    UniV3TokenRegistry public immutable registry;
    UniV3MEVProtection public immutable mevProtection;
    bytes32 public immutable proxyContractBytecodeHash;

    bool public initialized;
    address public token0;
    address public token1;
    uint24 public fee;
    int24 public tickLower;
    int24 public tickUpper;

    uint160 public sqrtLowerPriceX96;
    uint160 public sqrtUpperPriceX96;

    IUniswapV3Pool public pool;
    uint256 public positionId;
    bytes public securityParams;

    address internal _oracle;

    // setup functions

    constructor(
        INonfungiblePositionManager positionManager_,
        ISwapRouter router_,
        UniV3TokenRegistry registry_,
        UniV3MEVProtection mevProtection_,
        bytes32 proxyContractBytecodeHash_
    ) {
        proxyContractBytecodeHash = proxyContractBytecodeHash_;
        positionManager = positionManager_;
        factory = IUniswapV3Factory(positionManager.factory());
        router = router_;
        registry = registry_;
        mevProtection = mevProtection_;
    }

    function initialize(InitParams memory params) external {
        if (initialized) revert TokenAlreadyInitialized();
        initialized = true;
        positionId = params.positionId;
        _name = params.name;
        _symbol = params.symbol;
        _admin = params.admin;
        _strategy = params.strategy;
        _oracle = params.oracle;
        securityParams = params.securityParams;

        if (params.admin != address(0)) {
            if (CommonLibrary.getContractBytecodeHash(params.admin) != proxyContractBytecodeHash) {
                revert InvalidState();
            }
        }

        (, , token0, token1, fee, tickLower, tickUpper, _totalSupply, , , , ) = positionManager.positions(
            params.positionId
        );

        IERC20(token0).safeApprove(address(positionManager), type(uint256).max);
        IERC20(token1).safeApprove(address(positionManager), type(uint256).max);
        IERC20(token0).safeApprove(address(router), type(uint256).max);
        IERC20(token1).safeApprove(address(router), type(uint256).max);

        if (totalSupply() == 0) {
            revert InvalidState();
        }

        pool = IUniswapV3Pool(factory.getPool(token0, token1, fee));

        sqrtLowerPriceX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtUpperPriceX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateSecurityParams(bytes memory newSecurityParams) external override onlyStrategy {
        securityParams = newSecurityParams;
    }

    // view functions

    function isSameKind(address token) external view override returns (bool) {
        uint256 tokenId = registry.idByToken(token);
        if (
            tokenId != 0 &&
            UniV3Token(token).token0() == token0 &&
            UniV3Token(token).token1() == token1 &&
            UniV3Token(token).fee() == fee &&
            UniV3Token(token).admin() == admin()
        ) {
            bytes memory tokenSecurityParams = securityParams;
            bytes memory newTokenSecurityParams = UniV3Token(token).securityParams();
            return keccak256(tokenSecurityParams) == keccak256(newTokenSecurityParams);
        }
        return false;
    }

    function tvl() public view override returns (uint256[] memory tokenAmounts) {
        IUniswapV3Pool pool_ = pool;
        (uint160 sqrtRatioX96, , , , , , ) = pool_.slot0();
        tokenAmounts = new uint256[](2);
        (tokenAmounts[0], tokenAmounts[1]) = PositionValue.total(positionManager, positionId, sqrtRatioX96, pool_);

        tokenAmounts[0] += IERC20(token0).balanceOf(address(this));
        tokenAmounts[1] += IERC20(token1).balanceOf(address(this));
    }

    function oracle() external view override returns (address) {
        return _oracle;
    }

    // deposit functions

    function deposit(uint256[] memory tokenAmounts, uint256 minLpAmount) external override returns (uint256 lpAmount) {
        return _deposit(msg.sender, tokenAmounts, minLpAmount);
    }

    function deposit(
        address sender,
        uint256[] memory tokenAmounts,
        uint256 minLpAmount
    ) external override returns (uint256 lpAmount) {
        return _deposit(sender, tokenAmounts, minLpAmount);
    }

    function _deposit(
        address sender,
        uint256[] memory tokenAmounts,
        uint256 minLpAmount
    ) private returns (uint256 lpAmount) {
        mevProtection.ensureNoMEV(address(pool), securityParams);
        uint256[] memory currentAmounts = tvl();

        uint256 totalSupply_ = totalSupply();

        uint256 amount0 = tokenAmounts[0];
        uint256 amount1 = tokenAmounts[1];

        uint256 lpAmount0 = type(uint256).max;
        uint256 lpAmount1 = type(uint256).max;
        if (currentAmounts[0] > 0) lpAmount0 = FullMath.mulDiv(amount0, totalSupply_, currentAmounts[0]);
        if (currentAmounts[1] > 0) lpAmount1 = FullMath.mulDiv(amount1, totalSupply_, currentAmounts[1]);

        lpAmount = lpAmount0;
        if (lpAmount1 < lpAmount) {
            lpAmount = lpAmount1;
        }

        if (minLpAmount > lpAmount) {
            revert LimitUnderflow();
        }

        if (lpAmount == 0) {
            return 0;
        }

        amount0 = FullMath.mulDiv(lpAmount, currentAmounts[0], totalSupply_);
        if ((lpAmount * currentAmounts[0]) % totalSupply_ != 0) {
            amount0++;
        }

        amount1 = FullMath.mulDiv(lpAmount, currentAmounts[1], totalSupply_);
        if ((lpAmount * currentAmounts[1]) % totalSupply_ != 0) {
            amount1++;
        }

        IERC20(token0).safeTransferFrom(sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(sender, address(this), amount1);

        positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: positionId,
                amount0Desired: IERC20(token0).balanceOf(address(this)),
                amount1Desired: IERC20(token1).balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 1
            })
        );

        _mint(sender, lpAmount);
    }

    // withdraw functions

    function withdraw(
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    ) external override returns (uint256[] memory tokenAmounts) {
        return _withdraw(msg.sender, lpAmount, minTokenAmounts);
    }

    function withdraw(
        address sender,
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    ) external override onlyAdmin returns (uint256[] memory tokenAmounts) {
        return _withdraw(sender, lpAmount, minTokenAmounts);
    }

    function _withdraw(
        address sender,
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    ) private returns (uint256[] memory tokenAmounts) {
        if (lpAmount == 0) return new uint256[](2);
        mevProtection.ensureNoMEV(address(pool), securityParams);
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        uint256[] memory currentAmounts = tvl();

        uint256 totalSupply_ = totalSupply();
        uint256 amount0 = FullMath.mulDiv(lpAmount, currentAmounts[0], totalSupply_);
        uint256 amount1 = FullMath.mulDiv(lpAmount, currentAmounts[1], totalSupply_);
        if (amount0 < minTokenAmounts[0] || amount1 < minTokenAmounts[1]) {
            revert LimitUnderflow();
        }

        _burn(sender, lpAmount);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (balance0 >= amount0 && balance1 >= amount1) {
            IERC20(token0).safeTransfer(sender, amount0);
            IERC20(token1).safeTransfer(sender, amount1);
            tokenAmounts = new uint256[](2);
            tokenAmounts[0] = amount0;
            tokenAmounts[1] = amount1;
            return tokenAmounts;
        }

        {
            (uint256 fees0, uint256 fees1) = PositionValue.fees(positionManager, positionId, pool);
            balance0 += fees0;
            balance1 += fees1;
        }

        if (balance0 >= amount0 && balance1 >= amount1) {
            positionManager.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: positionId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            IERC20(token0).safeTransfer(sender, amount0);
            IERC20(token1).safeTransfer(sender, amount1);
            tokenAmounts = new uint256[](2);
            tokenAmounts[0] = amount0;
            tokenAmounts[1] = amount1;
            return tokenAmounts;
        }

        {
            uint256 amount0ToPull = 0;
            uint256 amount1ToPull = 0;

            if (balance0 < amount0) amount0ToPull = amount0 - balance0;
            if (balance1 < amount1) amount1ToPull = amount1 - balance1;

            uint128 liquidityToPull = LiquidityAmounts.getMaxLiquidityForAmounts(
                sqrtRatioX96,
                sqrtLowerPriceX96,
                sqrtUpperPriceX96,
                amount0ToPull,
                amount1ToPull
            );

            (uint256 expectedAmount0, uint256 expectedAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                sqrtLowerPriceX96,
                sqrtUpperPriceX96,
                liquidityToPull
            );

            if (expectedAmount0 < amount0ToPull || expectedAmount1 < amount1ToPull) {
                ++liquidityToPull;
            }

            positionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: positionId,
                    liquidity: liquidityToPull,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 1
                })
            );
        }

        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: positionId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        balance0 = IERC20(token0).balanceOf(address(this));
        if (balance0 < amount0) amount0 = balance0;
        balance1 = IERC20(token1).balanceOf(address(this));
        if (balance1 < amount1) amount1 = balance1;

        if (amount0 < minTokenAmounts[0] || amount1 < minTokenAmounts[1]) {
            revert LimitUnderflow();
        }

        IERC20(token0).safeTransfer(sender, amount0);
        IERC20(token1).safeTransfer(sender, amount1);
        tokenAmounts = new uint256[](2);
        tokenAmounts[0] = amount0;
        tokenAmounts[1] = amount1;
        return tokenAmounts;
    }

    // harvest functions

    function _swapToTargetMEVUnsafe(uint160 sqrtPriceX96, uint256[2] memory currentAmounts) private {
        (uint256 tokenInIndex, uint256 amountIn) = UniswapCalculations.calculateAmountsForSwap(
            UniswapCalculations.PositionParams({
                sqrtLowerPriceX96: sqrtLowerPriceX96,
                sqrtUpperPriceX96: sqrtUpperPriceX96,
                sqrtPriceX96: sqrtPriceX96
            }),
            currentAmounts[0],
            currentAmounts[1],
            pool.fee()
        );

        address tokenIn = token0;
        address tokenOut = token1;
        if (tokenInIndex == 1) {
            (tokenIn, tokenOut) = (tokenOut, tokenIn);
        }

        try
            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp + 1,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            )
        returns (uint256) {} catch {}
    }

    function compound() external {
        mevProtection.ensureNoMEV(address(pool), securityParams);
        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: positionId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        uint256 fee0 = IERC20(token0).balanceOf(address(this));
        uint256 fee1 = IERC20(token1).balanceOf(address(this));

        if (fee0 + fee1 == 0) return;
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        _swapToTargetMEVUnsafe(sqrtPriceX96, [fee0, fee1]);

        try
            positionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: positionId,
                    amount0Desired: IERC20(token0).balanceOf(address(this)),
                    amount1Desired: IERC20(token1).balanceOf(address(this)),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 1
                })
            )
        returns (uint128, uint256, uint256) {} catch {}
    }
}
