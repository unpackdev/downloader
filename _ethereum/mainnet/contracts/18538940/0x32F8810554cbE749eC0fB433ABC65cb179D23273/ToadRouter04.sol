//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "./IToadRouter03.sol";
import "./IERC20.sol";
import "./ToadswapLibrary.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";
import "./Ownable.sol";

import "./Multicall.sol";
import "./IToadRouter04.sol";
import "./IPermitDai.sol";
import "./CallbackValidation.sol";
import "./Constants.sol";
import "./TickMath.sol";
import "./Path.sol";
import "./IvETH.sol";
import "./SafeCast.sol";
import "./ToadswapPermits.sol";
/**
 *
 * 
 * ToadRouter04
 * A re-implementation of the Uniswap v2 (and now v3) router with bot-driven meta-transactions and multi-router aggregation. 
 * Bot private keys are all stored on a hardware wallet.
 * ToadRouter03 implements ERC2612 (ERC20Permit) and auto-unwrap functions
 */
contract ToadRouter04 is IToadRouter04, Ownable, Multicall {
    using Path for bytes;
    using SafeCast for uint256;
    mapping(address => bool) allowedBots;


    address immutable PERMIT2;

    // Threshold for gas withdraw/payout to the runner
    uint256 public gasPayThreshold = 100000000000000000;
    
    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;


    // 0x90a2caf2
    error Unsupported();
    // 0x77efb076
    error Untrusted();
    // 0xaf7f02d5
    error NoAcceptETH();
    // 5397a1f9
    error NotEnoughOutput();
    error InvalidPath();
    error NotEnoughGas();
    error Expired();
    error NonceInvalid();

    modifier ensure(uint deadline) {
        if(deadline < block.timestamp) {
            revert Expired();
        }
        _;
    }

    modifier onlyBot() {
        if(!allowedBots[_msgSender()]) {
            revert Untrusted();
        }
        _;
    }

    constructor(
        address fac,
        address weth,
        address permit,
        address veth
    ) IToadRouter04(fac, weth, veth) {
        // Do any other stuff necessary
        // Add sender to allowedBots
        allowedBots[_msgSender()] = true;
        PERMIT2 = permit;
    }

    function addTrustedBot(address newBot) external onlyOwner {
        allowedBots[newBot] = true;
    }

    function removeTrustedBot(address bot) external onlyOwner {
        allowedBots[bot] = false;
    }

    receive() external payable {
        if (_msgSender() != WETH && _msgSender() != vETH) {
            revert NoAcceptETH();
        }
    }

    function performPermit2Single(
        address holder,
        IAllowanceTransfer.PermitSingle memory permitSingle,
        bytes calldata signature
    ) public virtual override onlyBot {
        IAllowanceTransfer permitCA = IAllowanceTransfer(PERMIT2);
        permitCA.permit(holder, permitSingle, signature);
    }

    function performPermit2Batch(
        address holder,
        IAllowanceTransfer.PermitBatch memory permitBatch,
        bytes calldata signature
    ) public virtual override onlyBot {
        IAllowanceTransfer permitCA = IAllowanceTransfer(PERMIT2);
        permitCA.permit(holder, permitBatch, signature);
    }

    function performPermit(
        address holder,
        address tok,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override ensure(deadline) onlyBot {
        ToadswapPermits.permit(PERMIT2, holder, tok, deadline, v, r, s);
    }

    function performPermitDai(address holder, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override onlyBot {
        ToadswapPermits.permitDai(PERMIT2, holder, tok, nonce, deadline, v, r, s);
    }

    function stfFirstHop(uint256 amountIn, ToadStructs.DexData memory dex1, address path0, address path1, address sender) internal {
        TransferHelper.safeTransferFrom(PERMIT2, path0, sender, ToadswapLibrary.pairFor(path0, path1, dex1), amountIn);
    }

    function useNonce(uint256 nonce, address account) external virtual override onlyBot {
        if(accountNonces[account] != nonce) {
            revert NonceInvalid();
        }

        accountNonces[account] = accountNonces[account] + 1;
    }


    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path1,
        ToadStructs.AggPath[] calldata path2,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        // This does two half-swaps, so we can extract the gas return

        // Swap the first half
        stfFirstHop(amountIn, ToadswapLibrary.getDexId(path1[0], dexes), path1[0].token, path1[1].token, to);
        
        uint256 wethBalanceBefore = IERC20(WETH).balanceOf(address(this));
        // Swap to us
        _swapSupportingFeeOnTransferTokens(path1, address(this), dexes);
        
        if (fees.fee > 0) {
            // Send the fee anyway
            TransferHelper.safeTransfer(WETH, fees.feeReceiver, fees.fee);
        }
        // Accmulate the gas return fee
        wethBalanceBefore = wethBalanceBefore + gasReturn;
        
        // Send the remaining WETH to the next hop - no STF as we are sender
        TransferHelper.safeTransfer(path2[0].token, ToadswapLibrary.pairFor(path2[0].token, path2[1].token, dexes[path1[1].dexId]), IERC20(WETH).balanceOf(address(this)) - wethBalanceBefore);
        // Process WETH remainder
        processWETH();
        // Grab the pre-balance
        uint256 balanceBefore = IERC20(path2[path2.length - 1].token).balanceOf(to);
        // Run the final half of swap to the end user
        _swapSupportingFeeOnTransferTokens(path2, to, dexes);
        // Do the output amount check
        outputAmount = IERC20(path2[path2.length - 1].token).balanceOf(to) - (balanceBefore);
        if(outputAmount < amountOutMin) {
            revert NotEnoughOutput();
        }
    }



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        uint256 ethFee,
        ToadStructs.AggPath[] calldata gasPath,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        // So ethFee is how much token to swap for the gas price
        {
            uint256 totalFees = ethFee + fees.fee;
            if (totalFees > 0) {
                uint256 gasReturnEth = fees.gasLimit * tx.gasprice;
            
                // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
                stfFirstHop(
                    totalFees,
                    ToadswapLibrary.getDexId(path[1], dexes),
                    gasPath[0].token,
                    gasPath[1].token,
                    to
                );
                uint256 wethBefore = IERC20(WETH).balanceOf(address(this));
                _swapSupportingFeeOnTransferTokens(gasPath, address(this), dexes);
                uint256 ethVal = IERC20(WETH).balanceOf(address(this)) - wethBefore;
                require(ethVal >= gasReturnEth, "Not enough paid for gas.");
                if (fees.fee > 0) {
                    // Send fee
                    uint256 feePortion = fees.fee*10000 / (totalFees);
                    TransferHelper.safeTransfer(WETH, fees.feeReceiver, ethVal*feePortion/10000);
                }
                processWETH();
            }
            amountIn = amountIn - totalFees;
        }
        // Swap remaining tokens to the path provided
        stfFirstHop(
            amountIn,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        uint balanceBefore = IERC20(path[path.length - 1].token).balanceOf(to);

        _swapSupportingFeeOnTransferTokens(path, to, dexes);
        outputAmount = IERC20(path[path.length - 1].token).balanceOf(to) - (balanceBefore);
        if(outputAmount < amountOutMin) {
            revert NotEnoughOutput();
        }
    }
    
    function processWETH() internal {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));
        if (wethBal > gasPayThreshold) {
            // Withdraw over threshold
            IWETH(WETH).withdraw(wethBal);
            // Send the gas payout
            TransferHelper.safeTransferETH(tx.origin, wethBal);
        }
    }

 

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] memory path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes
    )
        public 
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        // Grab gas limit first
        if(path[0].token != WETH && path[0].token != vETH) {
            revert InvalidPath();
        }
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        if (path[0].token == vETH) {
            // Virtual ETH
            address recipientPair = ToadswapLibrary.pairFor(WETH, path[1].token, ToadswapLibrary.getDexId(path[1], dexes));
            inputVETHHandle(to, gasReturn, amountIn, fees, recipientPair);
            path[0].token = WETH;
        } else {
            if (gasReturn + fees.fee > 0) {

                TransferHelper.safeTransferFrom(
                    PERMIT2,
                    WETH,
                    to,
                    address(this),
                    gasReturn + fees.fee
                );
                if(fees.fee > 0) {
                    TransferHelper.safeTransfer(WETH, fees.feeReceiver, fees.fee);
                }
                processWETH();
            }
            // Send to first pool
            stfFirstHop(
                amountIn - gasReturn - fees.fee,
                dexes[path[1].dexId],
                path[0].token,
                path[1].token,
                to
            );
        }
        // This code is the same
        uint256 balanceBefore = IERC20(path[path.length - 1].token).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, dexes);
        outputAmount =
            IERC20(path[path.length - 1].token).balanceOf(to) -
            (balanceBefore);
        if(outputAmount < amountOutMin) {
            revert NotEnoughOutput();
        }
    }

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes,
        bool unwrap
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        if(path[path.length - 1].token != WETH) {
            revert InvalidPath();
        }

        uint256 gasReturn = fees.gasLimit * tx.gasprice;

        stfFirstHop(
            amountIn,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );
        uint256 balBefore = IERC20(WETH).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this), dexes);
        uint amountOut = IERC20(WETH).balanceOf(address(this)) - balBefore;
        // Adjust output amount to be exclusive of the payout of gas
        outputAmount = amountOut - gasReturn - fees.fee;
        if(outputAmount < amountOutMin) {
            revert NotEnoughOutput();
        }

        outputWETHHandle(unwrap, to, gasReturn, amountOut, fees);

    }

    // Gasloan WETH unwrapper
    function unwrapWETH(
        address to,
        uint256 amount,
        ToadStructs.FeeStruct calldata fees
    ) external virtual override onlyBot {
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        TransferHelper.safeTransferFrom(PERMIT2, WETH, to, address(this), amount);
        // Unwrap occurring, so unwrap all our WETH
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        // Send fee
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        // Send amount that was withdrawn
        TransferHelper.safeTransferETH(to, amount - gasReturn - fees.fee);
        // Send remainder to the tx.origin
        TransferHelper.safeTransferETH(tx.origin, IERC20(WETH).balanceOf(address(this)));
    }

    // Pays eth to coinbase for 0 fee txns
    function sendETHToCoinbase() external payable override onlyBot {
        TransferHelper.safeTransferETH(block.coinbase, msg.value);
    }

    
    function unwrapVETH(
        address to,
        uint256 amount,
        ToadStructs.FeeStruct calldata fees
    ) external virtual override onlyBot {
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        IvETH vet = IvETH(vETH);
        vet.approvedWithdraw(to, amount, address(this));
        TransferHelper.safeTransferETH(tx.origin, gasReturn);
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        TransferHelper.safeTransferETH(to, amount - gasReturn - fees.fee);
    }
    function convertVETHtoWETH(
        address to,
        uint256 amount,
        ToadStructs.FeeStruct calldata fees
    ) external virtual override onlyBot {
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        IvETH vet = IvETH(vETH);
        vet.approvedConvertToWETH9(to, amount, address(this));
        IWETH(WETH).withdraw(fees.fee + gasReturn);
        
        //TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        // Send the remaining WETH back
        IWETH(WETH).transfer(to, amount - gasReturn - fees.fee);
    }

    function getPriceOut(
        uint256 amountIn,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) public view virtual override returns (uint256[] memory amounts) {
        return ToadswapLibrary.getPriceOut(amountIn, path, dexes);
    }

    function _swapSupportingFeeOnTransferTokens(
        ToadStructs.AggPath[] memory path,
        address _to,
        ToadStructs.DexData[] memory dexes
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (
                path[i].token,
                path[i + 1].token
            );
            (address token0, ) = ToadswapLibrary.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(
                ToadswapLibrary.pairFor(
                    input,
                    output,
                    dexes[path[i + 1].dexId]
                )
            );
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput =
                    IERC20(input).balanceOf(address(pair)) -
                    reserveInput;
                amountOutput = ToadswapLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOutput)
                : (amountOutput, uint(0));
            address to = i < path.length - 2
                ? ToadswapLibrary.pairFor(
                    output,
                    path[i + 2].token,
                    dexes[path[i + 2].dexId]
                )
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** LIBRARY FUNCTIONS ****
   
    function getAmountsOut(
        uint amountIn,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) external view virtual override returns (uint[] memory amounts) {
        return ToadswapLibrary.getAmountsOut(amountIn, path, dexes, vETH, WETH);
    }

    function getAmountsIn(
        uint amountOut,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) external view virtual override returns (uint[] memory amounts) {
        return ToadswapLibrary.getAmountsIn(amountOut, path, dexes, vETH, WETH);
    }

    // V3-compatible stuff here

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        ToadStructs.DexData memory dex
    ) private pure returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(dex.factory, dex.initcode, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        ToadStructs.SwapCallbackData memory data = abi.decode(_data, (ToadStructs.SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(tokenIn, tokenOut, fee, data.dex);

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay, data.isVeth);
        } else {
            revert Unsupported();
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value,
        bool isVeth
    ) internal {
        if (isVeth) {
            // Convert vETH to WETH and deposit it in the recipients wallet
            IvETH(vETH).approvedConvertToWETH9(payer, value, recipient);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment via permit2
            TransferHelper.safeTransferFrom(PERMIT2, token, payer, recipient, value);
        }
    }

     /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        ToadStructs.SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // find and replace recipient addresses
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) =
            getPool(tokenIn, tokenOut, fee, data.dex).swap(
                recipient,
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function exactInputGas(ToadStructs.FeeStruct memory fees, ToadStructs.GasRepayParams memory repay) internal {
        // No WETH in the hops, so we need to run a sell of our own first off
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        address payer = msg.sender;
        uint256 amtOutGas = 0;
        while (true) { 
            bool hasMultiplePools = repay.path.hasMultiplePools();
            repay.amountIn = exactInputInternal(
                repay.amountIn,
                address(this) , // Always pays out to the router, as this will end in WETH9 to be given as gas repay
                0,
                ToadStructs.SwapCallbackData({
                    path: repay.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer,
                    isVeth: false,
                    dex: repay.dex
                })
            );
            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                repay.path = repay.path.skipToken();
            } else {
                amtOutGas = repay.amountIn;
                break;
            }
        }
        if(amtOutGas < gasReturn + fees.fee) {
            revert NotEnoughGas();
        }
        
        if (fees.fee > 0) {
            // Send the WETH on its own
            TransferHelper.safeTransfer(WETH, fees.feeReceiver, fees.fee);
        }
        processWETH();
    }

    function exactInputSingle(ToadStructs.ExactInputSingleParams memory params, ToadStructs.FeeStruct memory fees, ToadStructs.GasRepayParams memory repay)
        external
        payable
        override
        onlyBot
        returns (uint256 amountOut)
    {
        exactInputGas(fees, repay);

        // Now, do the swap
        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            params.sqrtPriceLimitX96,
            ToadStructs.SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
                payer: msg.sender,
                isVeth: false,
                dex: params.dex
            })
        );
        if(amountOut < params.amountOutMinimum) {
            revert NotEnoughOutput();
        }
    }


    function exactInputSingleWETH(ToadStructs.ExactInputSingleParams memory params, ToadStructs.FeeStruct memory fees)
        external
        payable
        override
        onlyBot
        returns (uint256 amountOut)
    {
        if(params.tokenIn != WETH && params.tokenIn != vETH && params.tokenOut != WETH) {
            revert InvalidPath();
        }
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        // We don't support the swap entire contract balance
        bool isveth = false;
        if(params.tokenIn == WETH) {
            inputWETHHandle(params.holder, gasReturn, fees);
        } else if(params.tokenIn == vETH) {
            // vETH
            inputVETHHandle(params.holder, gasReturn, params.amountIn, fees, address(this));
            isveth = true;
            params.tokenIn == WETH;
        } 
        // Otherwise, output must be WETH
        if(params.tokenOut == WETH) {
            // Pay to us, so we can interdict and pay on
            amountOut = exactInputInternal(
                params.amountIn,
                address(this),
                params.sqrtPriceLimitX96,
                ToadStructs.SwapCallbackData({
                    path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
                    payer: msg.sender,
                    isVeth: isveth,
                    dex: params.dex
                })
            );
            if(amountOut < params.amountOutMinimum) {
            revert NotEnoughOutput();
            }
            outputWETHHandle(params.unwrap, params.recipient, gasReturn, amountOut, fees);

        } else {
            amountOut = exactInputInternal(
                params.amountIn,
                params.recipient,
                params.sqrtPriceLimitX96,
                ToadStructs.SwapCallbackData({
                    path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
                    payer: msg.sender,
                    isVeth: isveth,
                    dex: params.dex
                })
            );
            if(amountOut < params.amountOutMinimum) {
                revert NotEnoughOutput();
            }
           
        }


    }

    function exactInput(ToadStructs.ExactInputParams memory params, ToadStructs.FeeStruct memory fees, ToadStructs.GasRepayParams memory repay) external payable override onlyBot returns (uint256 amountOut) {
        
        address payer = msg.sender;
        exactInputGas(fees, repay);
        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();
            
            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                ToadStructs.SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer,
                    isVeth: false,
                    dex: params.dex
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }
        if(amountOut < params.amountOutMinimum) {
            revert NotEnoughOutput();
        }


    }

    function inputWETHHandle(address holder, uint256 amount, ToadStructs.FeeStruct memory fees) internal {
        // Is weth, so take the payment for gas and fee now
        TransferHelper.safeTransferFrom(PERMIT2, WETH, holder, address(this), amount + fees.fee);
        if (fees.fee > 0) {
            // Send the WETH on its own
            TransferHelper.safeTransfer(WETH, fees.feeReceiver, fees.fee);
        }
        processWETH();
    }

    function inputVETHHandle(address holder, uint256 gasReturn, uint256 amount, ToadStructs.FeeStruct memory fees, address onward) internal {
        IvETH vet = IvETH(vETH);
        // Pull all to us
        vet.approvedTransferFrom(holder, gasReturn + fees.fee, address(this));
        // Send the onward portion as WETH
        if(amount > 0) {
            vet.approvedConvertToWETH9(holder, amount - gasReturn - fees.fee, onward);
        }
        if (fees.fee > 0) {
            vet.transfer(fees.feeReceiver, fees.fee);
        }
        if(vet.balanceOf(address(this)) > gasPayThreshold) {
            vet.approvedWithdraw(address(this), vet.balanceOf(address(this)), tx.origin);
            
        } 
    }

    function outputWETHHandle(bool unwrap, address recipient, uint256 gasReturn, uint256 amountOut, ToadStructs.FeeStruct memory fees) internal {
        // Pay fee
        if (fees.fee > 0) {
            TransferHelper.safeTransfer(WETH, fees.feeReceiver, fees.fee);
        }
        if(unwrap) {
            // Unwrap it all, as we need to pay the user in ETH
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
            // Send user the ETH
            TransferHelper.safeTransferETH(recipient, amountOut - fees.fee - gasReturn);
            // send the rest to the tx origin 
            TransferHelper.safeTransferETH(tx.origin, address(this).balance);
        } else {
            TransferHelper.safeTransfer(WETH, recipient, amountOut - fees.fee - gasReturn);
            processWETH();
        }
    }

    function exactInputWETH(ToadStructs.ExactInputParams memory params, ToadStructs.FeeStruct memory fees) external payable override onlyBot returns (uint256 amountOut) {
        uint256 gasReturn = fees.gasLimit * tx.gasprice;
        address payer = msg.sender;
        bool hasPaid = false;
        bool isveth = false;
        (address tokenIn, ,) = params.path.decodeFirstPool();
        if(tokenIn == WETH) {
            inputWETHHandle(params.holder, gasReturn, fees);
        } else if (tokenIn == vETH) {

            inputVETHHandle(params.holder, gasReturn, params.amountIn, fees, address(this));
            isveth = true;
            params.path = params.path.replaceFirstPoolAddress(WETH);
        }
        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();
            (, address tokenOut,) = params.path.decodeFirstPool();
            
            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                ToadStructs.SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer,
                    isVeth: isveth,
                    dex: params.dex
                })
            );
            isveth = false;
            if (tokenOut == WETH) {
                // Subtract fees now
                params.amountIn = (params.amountIn - fees.fee - gasReturn);
                if (fees.fee > 0) {
                    TransferHelper.safeTransfer(WETH, fees.feeReceiver, fees.fee);
                }
                hasPaid = true;
            }
            

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }
        processWETH();
        if(amountOut < params.amountOutMinimum) {
            revert NotEnoughOutput();
        }
        if(!hasPaid) {
            revert NotEnoughGas();
        }
    }

}
