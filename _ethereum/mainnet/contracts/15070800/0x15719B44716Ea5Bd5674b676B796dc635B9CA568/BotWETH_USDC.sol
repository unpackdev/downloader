//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./IERC721Receiver.sol";
import "./ISwapRouter.sol";
import "./INonfungiblePositionManager.sol";
import "./TransferHelper.sol";
import "./LiquidityManagement.sol";

contract BotWETH_USDC is IERC721Receiver {
    using SafeMath for uint256;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24 public constant POOL_FEE = 500;

    ISwapRouter public immutable swapRouter;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    struct AdjustPositionParams {
        uint256 swapForWethAmount;
        uint256 swapMaxAmountInUSDC;
        uint256 swapForUsdcAmount;
        uint256 swapMaxAmountInWETH;
        uint256 tokenIDToRemove;
        uint128 liquidityToRemove;
        uint256 liquidity0Min;
        uint256 liquidity1Min;
        uint256 newTokenID;
        uint256 wethAmount;
        uint256 usdcAmount;
        uint256 mint0min;
        uint256 mint1min;
        int24 lowerTick;
        int24 upperTick;
    }

    mapping(address => bool) public whitelists;
    mapping(address => bool) public bots;

    modifier onlyWL() {
        require(whitelists[msg.sender], "no-wl");
        _;
    }

    constructor(address wl, address bot) {
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        nonfungiblePositionManager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );

        approveAll();
        whitelists[wl] = true;
        bots[bot] = true;
    }

    function addWhitelist(address addr) public onlyWL {
        whitelists[addr] = true;
    }

    function removeWhitelist(address addr) public onlyWL {
        whitelists[addr] = false;
    }

    function addBot(address addr) public onlyWL {
        bots[addr] = true;
    }

    function removeBot(address addr) public onlyWL {
        bots[addr] = false;
    }

    function approveAll() public {
        TransferHelper.safeApprove(
            WETH,
            address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88),
            type(uint256).max
        );
        TransferHelper.safeApprove(
            USDC,
            address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88),
            type(uint256).max
        );

        TransferHelper.safeApprove(
            WETH,
            address(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            type(uint256).max
        );
        TransferHelper.safeApprove(
            USDC,
            address(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            type(uint256).max
        );
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function adjustPosition(AdjustPositionParams calldata params) public {
        require(bots[msg.sender], "bot!");
        {
            if (params.tokenIDToRemove > 0) {
                _decreaseLiquidity(
                    params.tokenIDToRemove,
                    params.liquidityToRemove,
                    params.liquidity0Min,
                    params.liquidity1Min
                );
            }
        }

        {
            if (params.swapForWethAmount > 0) {
                _swapExactOutputSingle(
                    USDC,
                    WETH,
                    params.swapForWethAmount,
                    params.swapMaxAmountInUSDC
                );
            }
        }

        {
            if (params.swapForUsdcAmount > 0) {
                _swapExactOutputSingle(
                    WETH,
                    USDC,
                    params.swapForUsdcAmount,
                    params.swapMaxAmountInWETH
                );
            }
        }

        if (params.newTokenID == 0) {
            _mintNewPosition(
                params.usdcAmount,
                params.wethAmount,
                params.lowerTick,
                params.upperTick,
                params.mint0min,
                params.mint1min
            );
        } else {
            _increaseLiquidityCurrentRange(
                params.newTokenID,
                params.usdcAmount,
                params.wethAmount
            );
        }
    }

    function _mintNewPosition(
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal {
        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: USDC,
                token1: WETH,
                fee: POOL_FEE,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                recipient: address(this),
                deadline: block.timestamp
            });
        nonfungiblePositionManager.mint(params);
    }

    function _increaseLiquidityCurrentRange(
        uint256 tokenId,
        uint256 amountAdd0,
        uint256 amountAdd1
    ) internal {
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: amountAdd0,
                    amount1Desired: amountAdd1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        nonfungiblePositionManager.increaseLiquidity(params);
    }

    function _decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0min,
        uint256 amount1min
    ) internal returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: amount0min,
                    amount1Min: amount1min,
                    deadline: block.timestamp
                });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            params
        );

        _collectAllFees(tokenId);
    }

    function _collectAllFees(uint256 tokenID)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenID,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function collectAllFees(uint256 tokenID) external onlyWL {
        (uint256 amount0, uint256 amount1) = _collectAllFees(tokenID);
        TransferHelper.safeTransfer(USDC, msg.sender, amount0);
        TransferHelper.safeTransfer(WETH, msg.sender, amount1);
    }

    function _swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum
    ) internal returns (uint256 amountIn) {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);
    }

    function withdrawAndRemoveLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0min,
        uint256 amount1min
    ) public onlyWL {
        _decreaseLiquidity(tokenId, liquidity, amount0min, amount1min);
        withdrawAll();
    }

    function removeLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0min,
        uint256 amount1min
    ) public onlyWL {
        _decreaseLiquidity(tokenId, liquidity, amount0min, amount1min);
    }

    function withdrawAll() public onlyWL {
        if (IERC20(WETH).balanceOf(address(this)) > 0) {
            TransferHelper.safeTransfer(
                WETH,
                msg.sender,
                IERC20(WETH).balanceOf(address(this))
            );
        }

        if (IERC20(USDC).balanceOf(address(this)) > 0) {
            TransferHelper.safeTransfer(
                USDC,
                msg.sender,
                IERC20(USDC).balanceOf(address(this))
            );
        }
    }

    function retrieveNFT(uint256 tokenId) external onlyWL {
        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function myTransfer(address tokenAddr, uint256 amount) external onlyWL {
        if (amount == 0) {
            amount = IERC20(tokenAddr).balanceOf(address(this));
        }
        require(amount > 0, "amount");
        TransferHelper.safeTransfer(tokenAddr, msg.sender, amount);
    }
}
