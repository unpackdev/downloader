// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./AxelarExecutable.sol";
import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";
import "./SwitchAxelarAbstract.sol";

contract SwitchAxelar is SwitchAxelarAbstract, AxelarExecutable {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    IAxelarGasService public immutable gasReceiver;

    struct Sc {
        address _weth;
        address _otherToken;
    }

    constructor(
        Sc memory _sc,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _gateway,
        address _gasReceiver,
        address _swapRouter,
        address _feeCollector
    )
        SwitchAxelarAbstract(
            _sc._weth,
            _sc._otherToken,
            _pathCountAndSplit,
            _factories,
            _switchViewAddress,
            _switchEventAddress,
            _paraswapProxy,
            _augustusSwapper,
            _swapRouter,
            _feeCollector
        )
        AxelarExecutable(_gateway)
    {
        gasReceiver = IAxelarGasService(_gasReceiver);
        swapRouter = ISwapRouter(_swapRouter);
    }

    /**
     * cross chain swap function using axelar gateway
     * @param _swapArgs swap arguments
     */
    function swapByAxelar(
        SwapArgsAxelar calldata _swapArgs
    ) external payable nonReentrant returns (bytes32 transferId) {
        (bytes32 _transferId, uint256 returnAmount) = _swapByAxelar(_swapArgs);

        transferId = _transferId;

        _emitCrossChainSwapRequest(
            _swapArgs,
            _transferId,
            returnAmount,
            msg.sender,
            DataTypes.SwapStatus.Succeeded
        );
    }

    function _emitCrossChainSwapRequest(
        SwapArgsAxelar memory swapArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.SwapStatus status
    ) internal {
        switchEvent.emitCrosschainSwapRequest(
            swapArgs.id,
            transferId,
            swapArgs.bridge,
            sender,
            swapArgs.srcSwap.srcToken,
            swapArgs.srcSwap.dstToken,
            swapArgs.dstSwap.dstToken,
            swapArgs.amount,
            returnAmount,
            swapArgs.estimatedDstTokenAmount,
            status
        );
    }

    function _emitCrosschainSwapDone(
        AxelarSwapRequest memory swapRequest,
        address bridgeToken,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.SwapStatus status
    ) internal {
        switchEvent.emitCrosschainSwapDone(
            swapRequest.id,
            swapRequest.bridge,
            swapRequest.recipient,
            bridgeToken,
            swapRequest.dstToken,
            srcAmount,
            dstAmount,
            status
        );
    }

    /**
     * Internal function to handle axelar gmp execution on destination chain
     * @param payload axelar payload received from src chain
     * @param tokenSymbol symbol of the token received from src chain
     * @param amount token amount received from src chain
     */
    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal override {
        address bridgeToken = gateway.tokenAddresses(tokenSymbol);
        AxelarSwapRequest memory swapRequest = abi.decode(
            payload,
            (AxelarSwapRequest)
        );

        if (bridgeToken == address(0)) bridgeToken = swapRequest.bridgeToken;

        bool useParaswap = swapRequest.paraswapUsageStatus ==
            DataTypes.ParaswapUsageStatus.Both ||
            swapRequest.paraswapUsageStatus ==
            DataTypes.ParaswapUsageStatus.OnDestChain;

        uint256 returnAmount;

        DataTypes.SwapStatus status;

        if (bridgeToken == swapRequest.dstToken) {
            returnAmount = amount;
        } else {
            uint256 unspent;
            (unspent, returnAmount) = _swap(
                ISwapRouter.SwapRequest({
                    srcToken: IERC20(bridgeToken),
                    dstToken: IERC20(swapRequest.dstToken),
                    amountIn: amount,
                    amountMinSpend: swapRequest.bridgeDstAmount,
                    amountOutMin: 0,
                    useParaswap: useParaswap,
                    paraswapData: swapRequest.dstParaswapData,
                    splitSwapData: swapRequest.dstSplitSwapData,
                    distribution: swapRequest.dstDistribution,
                    raiseError: false
                }),
                false
            );

            if (unspent > 0) {
                // Transfer rest bridge token to user
                IERC20(bridgeToken).universalTransfer(
                    swapRequest.recipient,
                    unspent
                );
            }
        }

        _emitCrosschainSwapDone(
            swapRequest,
            bridgeToken,
            amount,
            returnAmount,
            status
        );

        if (returnAmount != 0) {
            IERC20(swapRequest.dstToken).universalTransfer(
                swapRequest.recipient,
                returnAmount
            );
        }
    }

    function _swapByAxelar(
        SwapArgsAxelar memory _swapArgs
    ) internal returns (bytes32 transferId, uint256 returnAmount) {
        SwapArgsAxelar memory swapArgs = _swapArgs;

        require(swapArgs.expectedReturn >= swapArgs.minReturn, "ER GT MR");
        require(!IERC20(swapArgs.srcSwap.dstToken).isETH(), "SRC NOT ETH");

        if (IERC20(swapArgs.srcSwap.srcToken).isETH()) {
            if (swapArgs.useNativeGas) {
                require(
                    msg.value == swapArgs.gasAmount + swapArgs.amount,
                    "IV1"
                );
            } else {
                require(msg.value == swapArgs.amount, "IV1");
            }
        } else if (swapArgs.useNativeGas) {
            require(msg.value == swapArgs.gasAmount, "IV1");
        }

        IERC20(swapArgs.srcSwap.srcToken).universalTransferFrom(
            msg.sender,
            address(this),
            swapArgs.amount
        );

        uint256 amountAfterFee = _getAmountAfterFee(
            IERC20(swapArgs.srcSwap.srcToken),
            swapArgs.amount,
            swapArgs.partner,
            swapArgs.partnerFeeRate
        );

        returnAmount = amountAfterFee;

        if (
            IERC20(swapArgs.srcSwap.srcToken).isETH() &&
            swapArgs.srcSwap.dstToken == address(weth)
        ) {
            weth.deposit{value: amountAfterFee}();
        } else {
            bool useParaswap = swapArgs.paraswapUsageStatus ==
                DataTypes.ParaswapUsageStatus.Both ||
                swapArgs.paraswapUsageStatus ==
                DataTypes.ParaswapUsageStatus.OnSrcChain;

            (, returnAmount) = _swap(
                ISwapRouter.SwapRequest({
                    srcToken: IERC20(swapArgs.srcSwap.srcToken),
                    dstToken: IERC20(swapArgs.srcSwap.dstToken),
                    amountIn: amountAfterFee,
                    amountMinSpend: amountAfterFee,
                    amountOutMin: swapArgs.expectedReturn,
                    useParaswap: useParaswap,
                    paraswapData: swapArgs.srcParaswapData,
                    splitSwapData: swapArgs.srcSplitSwapData,
                    distribution: swapArgs.srcDistribution,
                    raiseError: true
                }),
                true
            );
        }

        if (!swapArgs.useNativeGas) {
            returnAmount -= swapArgs.gasAmount;
        }

        require(returnAmount > 0, "TS1");
        require(returnAmount >= swapArgs.expectedReturn, "RA1");

        transferId = keccak256(
            abi.encodePacked(
                address(this),
                swapArgs.recipient,
                swapArgs.srcSwap.srcToken,
                returnAmount,
                swapArgs.dstChain,
                swapArgs.nonce,
                uint64(block.chainid)
            )
        );

        bytes memory payload;

        if (swapArgs.payload.length == 0) {
            payload = abi.encode(
                AxelarSwapRequest({
                    id: swapArgs.id,
                    bridge: swapArgs.bridge,
                    recipient: swapArgs.recipient,
                    bridgeToken: swapArgs.dstSwap.srcToken,
                    dstToken: swapArgs.dstSwap.dstToken,
                    paraswapUsageStatus: swapArgs.paraswapUsageStatus,
                    dstParaswapData: swapArgs.dstParaswapData,
                    dstSplitSwapData: swapArgs.dstSplitSwapData,
                    dstDistribution: swapArgs.dstDistribution,
                    bridgeDstAmount: swapArgs.bridgeDstAmount,
                    estimatedDstTokenAmount: swapArgs.estimatedDstTokenAmount
                })
            );
        } else {
            payload = swapArgs.payload;
        }

        if (swapArgs.useNativeGas) {
            gasReceiver.payNativeGasForContractCallWithToken{
                value: swapArgs.gasAmount
            }(
                address(this),
                swapArgs.dstChain,
                swapArgs.callTo,
                payload,
                swapArgs.bridgeTokenSymbol,
                amountAfterFee,
                msg.sender
            );
        } else {
            IERC20(swapArgs.srcSwap.dstToken).universalApprove(
                address(gasReceiver),
                swapArgs.gasAmount
            );

            gasReceiver.payGasForContractCallWithToken(
                address(this),
                swapArgs.dstChain,
                swapArgs.callTo,
                payload,
                swapArgs.bridgeTokenSymbol,
                returnAmount,
                swapArgs.srcSwap.dstToken,
                swapArgs.gasAmount,
                msg.sender
            );
        }

        IERC20(swapArgs.srcSwap.dstToken).universalApprove(
            address(gateway),
            amountAfterFee
        );

        gateway.callContractWithToken(
            swapArgs.dstChain,
            swapArgs.callTo,
            payload,
            swapArgs.bridgeTokenSymbol,
            returnAmount
        );
    }
}
