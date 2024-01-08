// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Governable.sol";
import "./IUniswapV2Router02.sol";
import "./ISafeBox.sol";
import "./ISafeBoxETH.sol";
import "./ICErc20.sol";
import "./ICyToken.sol";

/// @title Homora IBToken Swap
/// @author Sawit Trisirisatayawong (@tansawit)
contract HomoraIBSwap is Governable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public isIBToken;

    address public immutable IBETHV2;

    IUniswapV2Router02 public immutable router;

    address public immutable WETH;

    constructor(address _routerAddress, address _ibETHAddress) public {
        __Governable__init();
        router = IUniswapV2Router02(_routerAddress);
        IBETHV2 = _ibETHAddress;
        isIBToken[_ibETHAddress] = true;
        WETH = IUniswapV2Router02(_routerAddress).WETH();
    }

    /// @notice add a list of token addresses as supported ibToken
    /// @param tokens list of symbols to support
    function addIBTokens(address[] memory tokens) external onlyGov {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            require(
                !isIBToken[tokens[idx]] && tokens[idx] != IBETHV2,
                "token-is-ibeth-or-already-supported"
            );
            isIBToken[tokens[idx]] = true;

            SafeBox safebox = SafeBox(tokens[idx]);
            IERC20(safebox.uToken()).safeApprove(address(router), uint256(-1));
            IERC20(safebox.uToken()).safeApprove(address(safebox), uint256(-1));
        }
    }

    function getPath(address tokenIn, address tokenOut)
        internal
        view
        returns (address[] memory path)
    {
        address underlyingTokenIn;
        address underlyingTokenOut;

        if (tokenIn == IBETHV2) {
            underlyingTokenIn = router.WETH();
        } else {
            underlyingTokenIn = SafeBox(tokenIn).uToken();
        }

        if (tokenOut == IBETHV2) {
            underlyingTokenOut = router.WETH();
        } else {
            underlyingTokenOut = SafeBox(tokenOut).uToken();
        }

        if (
            underlyingTokenIn == router.WETH() ||
            underlyingTokenOut == router.WETH()
        ) {
            path = new address[](2);
            if (underlyingTokenIn == router.WETH()) {
                path[0] = router.WETH();
                path[1] = underlyingTokenOut;
            } else {
                path[0] = underlyingTokenIn;
                path[1] = router.WETH();
            }
        } else {
            path = new address[](3);
            path[0] = underlyingTokenIn;
            path[1] = router.WETH();
            path[2] = underlyingTokenOut;
        }
    }

    /// @notice get the estimated outpout amount of each consecutive
    /// swap along a path
    /// @param tokenIn the address of the input token
    /// @param tokenOut the address of the output token
    /// @param amountIn the inputted amount of tokenIn
    function getEstimatedAmountsOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256[] memory) {
        return router.getAmountsOut(amountIn, getPath(tokenIn, tokenOut));
    }

    /// @notice convert an amount of ibToken to that of the underlying token
    /// @param ibToken the ibToken to get the underlying token amount of
    /// @param ibTokenAmount the amount of ibToken to use for conversion
    function ibToToken(address ibToken, uint256 ibTokenAmount)
        external
        view
        returns (uint256)
    {
        CYToken cyToken = CYToken(SafeBox(ibToken).cToken());
        uint256 tokenAmount =
            ibTokenAmount.mul(cyToken.exchangeRateStored()).div(1e18);
        return tokenAmount;
    }

    /// @notice convert an amount of token to that of the associated ibToken
    /// @param ibToken the ibToken to get the token amount of
    /// @param tokenAmount the amount of token to use for conversion
    function tokenToIB(address ibToken, uint256 tokenAmount)
        external
        view
        returns (uint256)
    {
        CYToken cyToken = CYToken(SafeBox(ibToken).cToken());
        uint256 ibTokenAmount =
            tokenAmount.mul(1e18).div(cyToken.exchangeRateStored());
        return ibTokenAmount;
    }

    /// @notice swap an ibToken to another ibToken
    /// @param tokenIn the input ibToken
    /// @param tokenOut the desired output ibToken
    /// @param amountIn the amount of tokenIn to swap
    /// @param amountOutMin minimum amount of output tokens that must be received
    /// for the transaction not to revert
    /// @param deadline timestamp after which the transaction will revert
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256) {
        require(tokenIn != tokenOut, "token-in-out-identical");
        require(isIBToken[tokenIn], "token-in-not-supported");
        require(isIBToken[tokenOut], "token-out-not-supported");

        SafeBox safeboxIn = SafeBox(tokenIn);
        safeboxIn.transferFrom(msg.sender, address(this), amountIn);
        safeboxIn.withdraw(amountIn);

        uint256 underlyingBalance;
        address[] memory path = getPath(tokenIn, tokenOut);
        uint256 outputAmount;

        if (tokenIn != IBETHV2) {
            IERC20 underlying = IERC20(safeboxIn.uToken());
            underlyingBalance = underlying.balanceOf(address(this));
        } else {
            underlyingBalance = address(this).balance;
        }

        if (tokenIn != IBETHV2 && tokenOut != IBETHV2) {
            router.swapExactTokensForTokens(
                underlyingBalance,
                0,
                path,
                address(this),
                deadline
            );
        } else if (tokenIn == IBETHV2) {
            router.swapExactETHForTokens{value: underlyingBalance}(
                0,
                path,
                address(this),
                deadline
            );
        } else if (tokenOut == IBETHV2) {
            router.swapExactTokensForETH(
                underlyingBalance,
                0,
                path,
                address(this),
                deadline
            );
        }

        if (tokenOut == IBETHV2) {
            SafeBoxETH safeboxOut = SafeBoxETH(tokenOut);
            safeboxOut.deposit{value: address(this).balance}();
            outputAmount = safeboxOut.balanceOf(address(this));
            safeboxOut.transfer(msg.sender, outputAmount);
        } else {
            SafeBox safeboxOut = SafeBox(tokenOut);

            safeboxOut.deposit(
                IERC20(safeboxOut.uToken()).balanceOf(address(this))
            );
            outputAmount = safeboxOut.balanceOf(address(this));
            safeboxOut.transfer(msg.sender, outputAmount);
        }
        require(outputAmount >= amountOutMin, "insufficient-output-amount");
        return outputAmount;
    }

    receive() external payable {
        require(
            msg.sender == IBETHV2 || msg.sender == address(router),
            "unexpected-eth-sender"
        );
    }
}
