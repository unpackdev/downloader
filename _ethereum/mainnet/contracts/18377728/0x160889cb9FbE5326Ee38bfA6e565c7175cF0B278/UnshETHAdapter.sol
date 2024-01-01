// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IERC20.sol";

import "./ErrorMessages.sol";
import "./MutexLock.sol";

import "./SafeERC20.sol";

import "./ITokenAdapter.sol";
import "./IWETH9.sol";
import "./IStableSwap2Pool.sol";
import "./IunshETHZap.sol";
import "./ILSDVault.sol";
import "./IWstETH.sol";
import "./IStakedFraxEth.sol";
import "./IRETH.sol";
import "./ISwapRouter.sol";
import "./ISwapRouter.sol";
import "./IPool.sol";

struct InitializationParams {
    address zeroliquid;
    address token;
    address underlyingToken;
    address lsdVault;
    address unshEthZap;
    // stETH
    address stETHCurvePool;
    uint256 ethIndexStETHCurvePool;
    uint256 stETHIndexCurvePool;
    // frxETH
    address frxETHCurvePool;
    uint256 ethIndexFrxETHCurvePool;
    uint256 frxETHIndexCurvePool;
    // cbETH
    address cbETHCurvePool;
    uint256 ethIndexCbETHCurvePool;
    uint256 cbETHIndexCurvePool;
    // ankrETH
    address ankrETHCurvePool;
    uint256 ethIndexAnkrETHCurvePool;
    uint256 ankrETHIndexCurvePool;
    // swETH
    address swETHMaverickPool;
    address maverickRouter;
}

contract UnshETHAdapter is ITokenAdapter, MutexLock {
    string public override version = "1.0.0";

    address constant uniswapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant frxETH = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant sfrxETH = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public constant cbETH = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant ankrETH = 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb;
    address public constant swETH = 0xf951E335afb289353dc249e82926178EaC7DEd78;

    address public immutable override token;
    address public immutable override underlyingToken;
    address public immutable zeroliquid;
    address public immutable lsdVault;
    address public immutable unshEthZap;
    address public immutable stETHCurvePool;
    uint256 public immutable ethIndexStETHCurvePool;
    uint256 public immutable stETHIndexCurvePool;

    address public immutable frxETHCurvePool;
    uint256 public immutable ethIndexFrxETHCurvePool;
    uint256 public immutable frxETHIndexCurvePool;

    address public immutable cbETHCurvePool;
    uint256 public immutable ethIndexCbETHCurvePool;
    uint256 public immutable cbETHIndexCurvePool;

    address public immutable ankrETHCurvePool;
    uint256 public immutable ethIndexAnkrETHCurvePool;
    uint256 public immutable ankrETHIndexCurvePool;

    address public immutable swETHMaverickPool;
    address public immutable maverickRouter;

    constructor(InitializationParams memory params) {
        zeroliquid = params.zeroliquid;
        token = params.token;
        underlyingToken = params.underlyingToken;
        lsdVault = params.lsdVault;
        unshEthZap = params.unshEthZap;

        stETHCurvePool = params.stETHCurvePool;
        ethIndexStETHCurvePool = params.ethIndexStETHCurvePool;
        stETHIndexCurvePool = params.stETHIndexCurvePool;
        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (
            IStableSwap2Pool(params.stETHCurvePool).coins(params.ethIndexStETHCurvePool)
                != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }
        // Verify and make sure that the provided stETH matches the curve pool stETH.
        if (IStableSwap2Pool(params.stETHCurvePool).coins(params.stETHIndexCurvePool) != stETH) {
            revert IllegalArgument("Curve pool stETH token mismatch");
        }

        frxETHCurvePool = params.frxETHCurvePool;
        ethIndexFrxETHCurvePool = params.ethIndexFrxETHCurvePool;
        frxETHIndexCurvePool = params.frxETHIndexCurvePool;
        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (
            IStableSwap2Pool(params.frxETHCurvePool).coins(params.ethIndexFrxETHCurvePool)
                != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }
        // Verify and make sure that the provided frxETH matches the curve pool frxETH.
        if (IStableSwap2Pool(params.frxETHCurvePool).coins(params.frxETHIndexCurvePool) != frxETH) {
            revert IllegalArgument("Curve pool frxETH token mismatch");
        }

        cbETHCurvePool = params.cbETHCurvePool;
        ethIndexCbETHCurvePool = params.ethIndexCbETHCurvePool;
        cbETHIndexCurvePool = params.cbETHIndexCurvePool;
        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (IStableSwap2Pool(params.cbETHCurvePool).coins(params.ethIndexCbETHCurvePool) != underlyingToken) {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }
        // Verify and make sure that the provided cbETH matches the curve pool cbETH.
        if (IStableSwap2Pool(params.cbETHCurvePool).coins(params.cbETHIndexCurvePool) != cbETH) {
            revert IllegalArgument("Curve pool cbETH token mismatch");
        }

        ankrETHCurvePool = params.ankrETHCurvePool;
        ethIndexAnkrETHCurvePool = params.ethIndexAnkrETHCurvePool;
        ankrETHIndexCurvePool = params.ankrETHIndexCurvePool;
        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (
            IStableSwap2Pool(params.ankrETHCurvePool).coins(params.ethIndexAnkrETHCurvePool)
                != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }
        // Verify and make sure that the provided ankrETH matches the curve pool ankrETH.
        if (IStableSwap2Pool(params.ankrETHCurvePool).coins(params.ankrETHIndexCurvePool) != ankrETH) {
            revert IllegalArgument("Curve pool ankrETH token mismatch");
        }

        swETHMaverickPool = params.swETHMaverickPool;
        maverickRouter = params.maverickRouter;
    }

    /// @dev Checks that the message sender is the zeroliquid that the adapter is bound to.
    modifier onlyZeroLiquid() {
        if (msg.sender != zeroliquid) {
            revert Unauthorized("Not zeroliquid");
        }
        _;
    }

    receive() external payable {
        if (
            msg.sender != underlyingToken && msg.sender != rETH && msg.sender != stETHCurvePool
                && msg.sender != frxETHCurvePool && msg.sender != cbETHCurvePool && msg.sender != ankrETHCurvePool
        ) {
            revert Unauthorized("Payments only permitted from WETH, rETH or Curve Pools");
        }
    }

    /// @inheritdoc ITokenAdapter
    function price() external view returns (uint256) {
        return ILSDVault(lsdVault).stakedETHperunshETH();
    }

    /// @inheritdoc ITokenAdapter
    function wrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        amount;
        recipient; // Silence, compiler!

        revert UnsupportedOperation("Wrapping is not supported");
    }

    // @inheritdoc ITokenAdapter
    function unwrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        uint256 startingWETHBalance = IERC20(underlyingToken).balanceOf(address(this));
        uint256 startingWstETHBalance = IERC20(wstETH).balanceOf(address(this));
        uint256 startingRETHBalance = IERC20(rETH).balanceOf(address(this));
        uint256 startingSfrxETHBalance = IERC20(sfrxETH).balanceOf(address(this));
        uint256 startingCbETHBalance = IERC20(cbETH).balanceOf(address(this));
        uint256 startingAnkrETHBalance = IERC20(ankrETH).balanceOf(address(this));
        uint256 startingSwETHBalance = IERC20(swETH).balanceOf(address(this));

        SafeERC20.safeApprove(token, lsdVault, amount);
        ILSDVault(lsdVault).exit(amount);

        uint256 wethBalance = 0;

        uint256 receivedWETH = IERC20(underlyingToken).balanceOf(address(this)) - startingWETHBalance;
        wethBalance += receivedWETH;
        wethBalance += _convertWstETHToUnderlying(startingWstETHBalance);
        wethBalance += _convertRETHToUnderlying(startingRETHBalance);
        wethBalance += _convertSfrxETHToUnderlying(startingSfrxETHBalance);
        wethBalance += _convertCbETHToUnderlying(startingCbETHBalance);
        wethBalance += _convertAnkrETHToUnderlying(startingAnkrETHBalance);
        wethBalance += _convertSwETHToUnderlying(startingSwETHBalance);

        // Transfer the tokens to the recipient.
        SafeERC20.safeTransfer(underlyingToken, recipient, wethBalance);

        return wethBalance;
    }

    function _convertWstETHToUnderlying(uint256 startingWstETHBalance) internal returns (uint256) {
        uint256 receivedWstETH = IERC20(wstETH).balanceOf(address(this)) - startingWstETHBalance;

        if (receivedWstETH > 0) {
            uint256 startingStETHBalance = IERC20(stETH).balanceOf(address(this));
            IWstETH(wstETH).unwrap(receivedWstETH);
            uint256 receivedStETH = IERC20(stETH).balanceOf(address(this)) - startingStETHBalance;

            SafeERC20.safeApprove(stETH, stETHCurvePool, receivedStETH);

            uint256 receivedETHFromStETH = IStableSwap2Pool(stETHCurvePool).exchange(
                int128(uint128(stETHIndexCurvePool)), // stETH Pool index
                int128(uint128(ethIndexStETHCurvePool)), // ETH pool index
                receivedStETH,
                0 // <- Slippage is handled upstream
            );

            IWETH9(underlyingToken).deposit{ value: receivedETHFromStETH }();

            return receivedETHFromStETH;
        } else {
            return 0;
        }
    }

    function _convertRETHToUnderlying(uint256 startingRETHBalance) internal returns (uint256) {
        uint256 receivedRETH = IERC20(rETH).balanceOf(address(this)) - startingRETHBalance;

        if (receivedRETH > 0) {
            uint256 receivedETHFromRETH = 0;
            uint256 ethUnderlyingRETH = IRETH(rETH).getEthValue(receivedRETH);

            if (IRETH(rETH).getTotalCollateral() >= ethUnderlyingRETH) {
                // Burn the rETH to receive ETH.
                uint256 startingETHBalance = address(this).balance;
                IRETH(rETH).burn(receivedRETH);
                receivedETHFromRETH = address(this).balance - startingETHBalance;

                // Wrap the ETH that we received from the burn.
                IWETH9(underlyingToken).deposit{ value: receivedETHFromRETH }();
            } else {
                SafeERC20.safeApprove(rETH, uniswapRouterV3, receivedRETH);

                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: rETH,
                    tokenOut: underlyingToken,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: receivedRETH,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                receivedETHFromRETH = ISwapRouter(uniswapRouterV3).exactInputSingle(params);
            }

            return receivedETHFromRETH;
        } else {
            return 0;
        }
    }

    function _convertSfrxETHToUnderlying(uint256 startingSfrxETHBalance) internal returns (uint256) {
        uint256 receivedSfrxETH = IERC20(sfrxETH).balanceOf(address(this)) - startingSfrxETHBalance;

        if (receivedSfrxETH > 0) {
            uint256 startingFraxETHBalance = IERC20(frxETH).balanceOf(address(this));
            IStakedFraxEth(sfrxETH).withdraw(
                receivedSfrxETH * IStakedFraxEth(sfrxETH).convertToAssets(1e18)
                    / 10 ** SafeERC20.expectDecimals(sfrxETH),
                address(this),
                address(this)
            );
            uint256 receivedFraxETH = IERC20(frxETH).balanceOf(address(this)) - startingFraxETHBalance;

            SafeERC20.safeApprove(frxETH, frxETHCurvePool, receivedFraxETH);

            uint256 receivedETHFromFrxETH = IStableSwap2Pool(frxETHCurvePool).exchange(
                int128(uint128(frxETHIndexCurvePool)), // frxETH Pool index
                int128(uint128(ethIndexFrxETHCurvePool)), // ETH pool index
                receivedFraxETH,
                0 // <- Slippage is handled upstream
            );

            IWETH9(underlyingToken).deposit{ value: receivedETHFromFrxETH }();

            return receivedETHFromFrxETH;
        } else {
            return 0;
        }
    }

    function _convertCbETHToUnderlying(uint256 startingCbETHBalance) internal returns (uint256) {
        uint256 receivedCbETH = IERC20(cbETH).balanceOf(address(this)) - startingCbETHBalance;

        if (receivedCbETH > 0) {
            SafeERC20.safeApprove(cbETH, cbETHCurvePool, receivedCbETH);

            uint256 receivedETHFromCbETH = IStableSwap2Pool(cbETHCurvePool).exchange_underlying{ value: 0 }(
                int128(uint128(cbETHIndexCurvePool)), // cbETH Pool index
                int128(uint128(ethIndexCbETHCurvePool)), // ETH pool index
                receivedCbETH,
                0 // <- Slippage is handled upstream
            );

            IWETH9(underlyingToken).deposit{ value: receivedETHFromCbETH }();

            return receivedETHFromCbETH;
        } else {
            return 0;
        }
    }

    function _convertAnkrETHToUnderlying(uint256 startingAnkrETHBalance) internal returns (uint256) {
        uint256 receivedAnkrETH = IERC20(ankrETH).balanceOf(address(this)) - startingAnkrETHBalance;

        if (receivedAnkrETH > 0) {
            SafeERC20.safeApprove(ankrETH, ankrETHCurvePool, receivedAnkrETH);

            uint256 receivedETHFromAnkrETH = IStableSwap2Pool(ankrETHCurvePool).exchange(
                int128(uint128(ankrETHIndexCurvePool)), // ankrETH Pool index
                int128(uint128(ethIndexAnkrETHCurvePool)), // ETH pool index
                receivedAnkrETH,
                0 // <- Slippage is handled upstream
            );

            IWETH9(underlyingToken).deposit{ value: receivedETHFromAnkrETH }();

            return receivedETHFromAnkrETH;
        } else {
            return 0;
        }
    }

    function _convertSwETHToUnderlying(uint256 startingSwETHBalance) internal returns (uint256) {
        uint256 receivedSwETH = IERC20(swETH).balanceOf(address(this)) - startingSwETHBalance;

        if (receivedSwETH > 0) {
            SafeERC20.safeApprove(swETH, maverickRouter, receivedSwETH);

            IMaverickSwapRouter.ExactInputSingleParams memory params = IMaverickSwapRouter.ExactInputSingleParams({
                tokenIn: swETH,
                tokenOut: underlyingToken,
                pool: IMaverickPool(swETHMaverickPool),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: receivedSwETH,
                amountOutMinimum: 0,
                sqrtPriceLimitD18: 0
            });

            uint256 receivedWETHFromSwETH = IMaverickSwapRouter(maverickRouter).exactInputSingle(params);

            return receivedWETHFromSwETH;
        } else {
            return 0;
        }
    }
}
