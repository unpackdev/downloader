// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";
import "./SwitchAxelarAbstract.sol";

contract SwitchContractCallAxelarSender is SwitchAxelarAbstract {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    IAxelarGasService public immutable gasReceiver;
    IAxelarGateway public immutable gateway;

    // Swap tokens and do cross chain call
    struct ContractCallWithTokenArgsAxelar {
        SwapArgsAxelar swapArgs;
        DataTypes.ContractCallInfo callInfo;
    }

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
    {
        gasReceiver = IAxelarGasService(_gasReceiver);
        gateway = IAxelarGateway(_gateway);
        swapRouter = ISwapRouter(_swapRouter);
    }

    /**
     * cross chain contract call function using axelar gateway
     * The flow is similar with swapByAxelar function.
     * The difference is that there is contract call info argument additionally.
     * @param _contractCallArgs swap arguments
     */
    function contractCallWithTokenByAxelar(
        ContractCallWithTokenArgsAxelar calldata _contractCallArgs
    ) external payable nonReentrant returns (bytes32 transferId) {
        require(
            _contractCallArgs.swapArgs.estimatedDstTokenAmount != 0,
            "EDTA GTZ"
        );
        (
            bytes32 _transferId,
            uint256 returnAmount
        ) = _contractCallWithTokenByAxelar(
                _contractCallArgs.swapArgs,
                abi.encode(_contractCallArgs.callInfo)
            );

        transferId = _transferId;
        _emitCrossChainContractCallWithTokenRequest(
            _contractCallArgs,
            _transferId,
            returnAmount,
            msg.sender,
            DataTypes.ContractCallStatus.Succeeded
        );
    }

    function _emitCrossChainContractCallWithTokenRequest(
        ContractCallWithTokenArgsAxelar memory contractCallArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.ContractCallStatus status
    ) internal {
        switchEvent.emitCrosschainContractCallRequest(
            contractCallArgs.swapArgs.id,
            transferId,
            contractCallArgs.swapArgs.bridge,
            sender,
            contractCallArgs.callInfo.toContractAddress,
            contractCallArgs.callInfo.toApprovalAddress,
            contractCallArgs.swapArgs.srcSwap.srcToken,
            contractCallArgs.swapArgs.dstSwap.dstToken,
            returnAmount,
            contractCallArgs.swapArgs.estimatedDstTokenAmount,
            status
        );
    }

    function _contractCallWithTokenByAxelar(
        SwapArgsAxelar memory _swapArgs,
        bytes memory callInfo
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
                }),
                callInfo
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
            returnAmount
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
