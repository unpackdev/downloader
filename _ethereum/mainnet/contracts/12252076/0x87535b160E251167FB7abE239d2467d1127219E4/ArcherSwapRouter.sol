//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt (chris@archerdao.io).
*/

import "./IUniRouter.sol";
import "./ITipJar.sol";
import "./IERC20Extended.sol";
import "./SafeERC20.sol";

/**
 * @title ArcherSwapRouter
 * @dev Allows Uniswap V2 Router-compliant trades to be paid via % tips instead of gas
 */
contract ArcherSwapRouter {
    using SafeERC20 for IERC20Extended;

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /// @notice TipJar proxy
    ITipJar public immutable tipJar;

    /// @notice Trade details
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address payable to;
        uint256 deadline;
    }

    /// @notice Add Liquidity details
    struct AddLiquidity {
        address tokenA;
        address tokenB;
        uint amountADesired;
        uint amountBDesired;
        uint amountAMin;
        uint amountBMin;
        address to;
        uint deadline;
    }

    /// @notice Remove Liquidity details
    struct RemoveLiquidity {
        IERC20Extended lpToken;
        address tokenA;
        address tokenB;
        uint liquidity;
        uint amountAMin;
        uint amountBMin;
        address to;
        uint deadline;
    }

    /// @notice Permit details
    struct Permit {
        IERC20Extended token;
        uint256 amount;
        uint deadline;
        uint8 v;
        bytes32 r; 
        bytes32 s;
    }

    /**
     * @notice Contructs a new ArcherSwap Router
     * @param _tipJar Address of TipJar contract
     */
    constructor(address _tipJar) {
        tipJar = ITipJar(_tipJar);
    }

    /**
     * @notice Add liquidity to token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     */
    function addLiquidityAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _addLiquidity(
            router,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Add liquidity to pair, using permit for approvals
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param permitA Permit details for token A
     * @param permitB Permit details for token B
     */
    function addLiquidityWithPermitAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity,
        Permit calldata permitA,
        Permit calldata permitB
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        if(permitA.amount > 0) {
            _permit(permitA.token, permitA.amount, permitA.deadline, permitA.v, permitA.r, permitA.s);
        }
        if(permitB.amount > 0) {
            _permit(permitB.token, permitB.amount, permitB.deadline, permitB.v, permitB.r, permitB.s);
        }
        _tipAmountETH(msg.value);
        _addLiquidity(
            router,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin, 
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Add liquidity to ETH>Token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param tipAmount tip amount
     */
    function addLiquidityETHAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= liquidity.amountBDesired + tipAmount, "must send ETH to cover tip + liquidity");
        _tipAmountETH(tipAmount);
        _addLiquidityETH(
            router,
            liquidity.tokenA,
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Add liquidity to ETH>Token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param tipAmount tip amount
     */
    function addLiquidityETHWithPermitAndTipAmount(
        IUniRouter router,
        AddLiquidity calldata liquidity,
        Permit calldata permit,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= liquidity.amountBDesired + tipAmount, "must send ETH to cover tip + liquidity");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _tipAmountETH(tipAmount);
        _addLiquidityETH(
            router,
            liquidity.tokenA,
            liquidity.amountADesired, 
            liquidity.amountBDesired, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from token>token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     */
    function removeLiquidityAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _removeLiquidity(
            router,
            liquidity.lpToken,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.liquidity,
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from ETH>token pair
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     */
    function removeLiquidityETHAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _removeLiquidityETH(
            router,
            liquidity.lpToken,
            liquidity.tokenA,
            liquidity.liquidity, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from token>token pair, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param permit Permit details
     */
    function removeLiquidityWithPermitAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _removeLiquidity(
            router,
            liquidity.lpToken,
            liquidity.tokenA, 
            liquidity.tokenB, 
            liquidity.liquidity,
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Remove liquidity from ETH>token pair, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param liquidity Liquidity details
     * @param permit Permit details
     */
    function removeLiquidityETHWithPermitAndTipAmount(
        IUniRouter router,
        RemoveLiquidity calldata liquidity,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _removeLiquidityETH(
            router,
            liquidity.lpToken,
            liquidity.tokenA,
            liquidity.liquidity, 
            liquidity.amountAMin,
            liquidity.amountBMin,
            liquidity.to,
            liquidity.deadline
        );
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapExactTokensForETHAndTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapExactTokensForETHWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _tipAmountETH(msg.value);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapExactTokensForETHAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapExactTokensForETHWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapTokensForExactETHAndTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapTokensForExactETHWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapTokensForExactETHAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap tokens for ETH and pay % of ETH as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param tipPct % of resulting ETH to pay as tip
     */
    function swapTokensForExactETHWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        _tipPctETH(tipPct);
        _transferContractETHBalance(trade.to);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapExactETHForTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= tipAmount, "must send ETH to cover tip");
        _tipAmountETH(tipAmount);
        _swapExactETHForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of ETH to pay as tip
     */
    function swapExactETHForTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        require(msg.value > 0, "must send ETH to cover tip");
        uint256 tipAmount = (msg.value * tipPct) / 1000000;
        _tipAmountETH(tipAmount);
        _swapExactETHForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay amount of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapETHForExactTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= tipAmount, "must send ETH to cover tip");
        _tipAmountETH(tipAmount);
        _swapETHForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay % of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipPct % of ETH to pay as tip
     */
    function swapETHForExactTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        require(msg.value > 0, "must send ETH to cover tip");
        uint256 tipAmount = (msg.value * tipPct) / 1000000;
        _tipAmountETH(tipAmount);
        _swapETHForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapExactTokensForTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapExactTokensForTokensWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapExactTokensForTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapExactTokensForTokensWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapTokensForExactTokensWithTipAmount(
        IUniRouter router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     */
    function swapTokensForExactTokensWithPermitAndTipAmount(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tipAmountETH(msg.value);
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapTokensForExactTokensWithTipPct(
        IUniRouter router,
        Trade calldata trade,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    /**
     * @notice Swap tokens for tokens and pay % of tokens as tip, using permit for approval
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param permit Permit details
     * @param pathToEth Path to ETH for tip
     * @param minEth ETH minimum for tip conversion
     * @param tipPct % of resulting tokens to pay as tip
     */
    function swapTokensForExactTokensWithPermitAndTipPct(
        IUniRouter router,
        Trade calldata trade,
        Permit calldata permit,
        address[] calldata pathToEth,
        uint256 minEth,
        uint32 tipPct
    ) external payable {
        require(tipPct > 0, "tipPct must be > 0");
        _permit(permit.token, permit.amount, permit.deadline, permit.v, permit.r, permit.s);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, address(this), trade.deadline);
        IERC20Extended toToken = IERC20Extended(pathToEth[0]);
        uint256 contractTokenBalance = toToken.balanceOf(address(this));
        uint256 tipAmount = (contractTokenBalance * tipPct) / 1000000;
        _tipWithTokens(router, tipAmount, pathToEth, trade.deadline, minEth);
        _transferContractTokenBalance(toToken, trade.to);
    }

    function _addLiquidity(
        IUniRouter router,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(tokenA);
        IERC20Extended toToken = IERC20Extended(tokenB);
        fromToken.safeTransferFrom(msg.sender, address(this), amountADesired);
        fromToken.safeIncreaseAllowance(address(router), amountADesired);
        toToken.safeTransferFrom(msg.sender, address(this), amountBDesired);
        toToken.safeIncreaseAllowance(address(router), amountBDesired);
        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        if(amountADesired > amountA) {
            fromToken.safeTransfer(msg.sender, fromToken.balanceOf(address(this)));
        }
        if(amountBDesired > amountB) {
            toToken.safeTransfer(msg.sender, toToken.balanceOf(address(this)));
        }
    }

    function _addLiquidityETH(
        IUniRouter router,
        address token,
        uint amountTokenDesired,
        uint amountETHDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(token);
        fromToken.safeTransferFrom(msg.sender, address(this), amountTokenDesired);
        fromToken.safeIncreaseAllowance(address(router), amountTokenDesired);
        (uint256 amountToken, uint256 amountETH, ) = router.addLiquidityETH{value: amountETHDesired}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        if(amountTokenDesired > amountToken) {
            fromToken.safeTransfer(msg.sender, amountTokenDesired - amountToken);
        }
        if(amountETHDesired > amountETH) {
            (bool success, ) = msg.sender.call{value: amountETHDesired - amountETH}("");
            require(success);
        }
    }

    function _removeLiquidity(
        IUniRouter router,
        IERC20Extended lpToken,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal {
        lpToken.safeTransferFrom(msg.sender, address(this), liquidity);
        lpToken.safeIncreaseAllowance(address(router), liquidity);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
        IERC20Extended fromToken = IERC20Extended(tokenA);
        IERC20Extended toToken = IERC20Extended(tokenB);
        fromToken.safeTransfer(msg.sender, amountA);
        toToken.safeTransfer(msg.sender, amountB);
    }

    function _removeLiquidityETH(
        IUniRouter router,
        IERC20Extended lpToken,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) internal {
        lpToken.safeTransferFrom(msg.sender, address(this), liquidity);
        lpToken.safeIncreaseAllowance(address(router), liquidity);
        (uint256 amountToken, uint256 amountETH) = router.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
        IERC20Extended fromToken = IERC20Extended(token);
        fromToken.safeTransfer(msg.sender, amountToken);
        (bool success, ) = msg.sender.call{value: amountETH}("");
        require(success);
    }

    /**
     * @notice Internal implementation of swap ETH for tokens
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactETHForTokens(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap ETH for tokens
     * @param amountOut Amount of ETH out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive ETH
     * @param deadline Block timestamp deadline for trade
     */
    function _swapETHForExactTokens(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        router.swapETHForExactTokens{value: amountInMax}(amountOut, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for ETH
     * @param amountOut Amount of ETH out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive ETH
     * @param deadline Block timestamp deadline for trade
     */
    function _swapTokensForExactETH(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        router.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for ETH
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactTokensForETH(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactTokensForTokens(
        IUniRouter router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param amountOut Amount of tokens out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive tokens
     * @param deadline Block timestamp deadline for trade
     */
    function _swapTokensForExactTokens(
        IUniRouter router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20Extended fromToken = IERC20Extended(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    /**
     * @notice Tip % of ETH contract balance
     * @param tipPct % to tip
     */
    function _tipPctETH(uint32 tipPct) internal {
        uint256 contractBalance = address(this).balance;
        uint256 tipAmount = (contractBalance * tipPct) / 1000000;
        tipJar.tip{value: tipAmount}();
    }

    /**
     * @notice Tip specific amount of ETH
     * @param tipAmount Amount to tip
     */
    function _tipAmountETH(uint256 tipAmount) internal {
        tipJar.tip{value: tipAmount}();
    }

    /**
     * @notice Transfer contract ETH balance to specified user
     * @param to User to receive transfer
     */
    function _transferContractETHBalance(address payable to) internal {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @notice Transfer contract token balance to specified user
     * @param token Token to transfer
     * @param to User to receive transfer
     */
    function _transferContractTokenBalance(IERC20Extended token, address payable to) internal {
        token.safeTransfer(to, token.balanceOf(address(this)));
    }

    /**
     * @notice Convert a token balance into ETH and then tip
     * @param amountIn Amount to swap
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _tipWithTokens(
        IUniRouter router,
        uint amountIn,
        address[] memory path,
        uint256 deadline,
        uint256 minEth
    ) internal {
        IERC20Extended(path[0]).safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, minEth, path, address(this), deadline);
        tipJar.tip{value: address(this).balance}();
    }

    /**
     * @notice Permit contract to spend user's balance
     * @param token Token to permit
     * @param amount Amount to permit
     * @param deadline Block timestamp deadline for permit
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _permit(
        IERC20Extended token, 
        uint amount,
        uint deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) internal {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }
}