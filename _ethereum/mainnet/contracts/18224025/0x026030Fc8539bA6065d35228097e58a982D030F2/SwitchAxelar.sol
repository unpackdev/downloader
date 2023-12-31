// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./AxelarExecutable.sol";
import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";
import "./ICallDataExecutor.sol";
import "./Switch.sol";
import "./ISwapRouter.sol";

contract SwitchAxelar is Switch, AxelarExecutable {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    event CallDataExecutorSet(address callDataExecutor);
    event SwapRouterSet(address swapRouter);

    IAxelarGasService public immutable gasReceiver;
    address public callDataExecutor;
    ISwapRouter public swapRouter;

    // Used when swap required on dest chain
    struct SwapArgsAxelar {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        string bridgeTokenSymbol;
        address recipient;
        string callTo; // The address of the destination app contract.
        bool useNativeGas; // Indicate ETH or bridge token to pay axelar gas
        uint256 gasAmount; // Gas amount for axelar gmp
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        string dstChain;
        uint64 nonce;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] srcSplitSwapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
    }

    // Swap tokens and do cross chain call
    struct ContractCallWithTokenArgsAxelar {
        SwapArgsAxelar swapArgs;
        DataTypes.ContractCallInfo callInfo;
    }

    struct AxelarSwapRequest {
        bytes32 id;
        bytes32 bridge;
        address recipient;
        address bridgeToken;
        address dstToken;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData;
        uint256[] dstDistribution;
        uint256 bridgeDstAmount;
        uint256 estimatedDstTokenAmount;
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
        Switch(
            _sc._weth,
            _sc._otherToken,
            _pathCountAndSplit[0],
            _pathCountAndSplit[1],
            _factories,
            _switchViewAddress,
            _switchEventAddress,
            _paraswapProxy,
            _augustusSwapper,
            _feeCollector
        )
        AxelarExecutable(_gateway)
    {
        gasReceiver = IAxelarGasService(_gasReceiver);
        swapRouter = ISwapRouter(_swapRouter);
    }

    receive() external payable {}

    /**
     * set calldataExecutor address
     * @param _newCallDataExecutor new calldataExecutor address
     */
    // function setCallDataExecutor(address _newCallDataExecutor)
    //     external
    //     onlyOwner
    // {
    //     callDataExecutor = _newCallDataExecutor;
    //     emit CallDataExecutorSet(_newCallDataExecutor);
    // }

    /**
     * set swapRouter address
     * @param _swapRouter new swapRouter address
     */
    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = ISwapRouter(_swapRouter);
        emit SwapRouterSet(_swapRouter);
    }

    /**
     * cross chain swap function using axelar gateway
     * @param _swapArgs swap arguments
     */
    function swapByAxelar(SwapArgsAxelar calldata _swapArgs)
        external
        payable
        nonReentrant
        returns (bytes32 transferId)
    {
        (
            bytes32 _transferId,
            uint256 returnAmount
        ) = _contractCallWithTokenByAxelar(_swapArgs, "");

        transferId = _transferId;

        _emitCrossChainSwapRequest(
            _swapArgs,
            _transferId,
            returnAmount,
            msg.sender,
            DataTypes.SwapStatus.Succeeded
        );
    }

    // /**
    //  * cross chain contract call function using axelar gateway
    //  * The flow is similar with swapByAxelar function.
    //  * The difference is that there is contract call info argument additionally.
    //  * @param _contractCallArgs swap arguments
    //  */
    // function contractCallWithTokenByAxelar(
    //     ContractCallWithTokenArgsAxelar calldata _contractCallArgs
    // ) external payable nonReentrant returns (bytes32 transferId) {
    //     require(
    //         _contractCallArgs.swapArgs.estimatedDstTokenAmount != 0,
    //         "EDTA GTZ"
    //     );
    //     (
    //         bytes32 _transferId,
    //         uint256 returnAmount
    //     ) = _contractCallWithTokenByAxelar(
    //             _contractCallArgs.swapArgs,
    //             abi.encode(_contractCallArgs.callInfo)
    //         );
            
    //     _emitCrossChainContractCallWithTokenRequest(
    //         _contractCallArgs,
    //         _transferId,
    //         returnAmount,
    //         msg.sender,
    //         DataTypes.ContractCallStatus.Succeeded
    //     );
    // }

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

    function _emitCrosschainContractCallDone(
        AxelarSwapRequest memory swapRequest,
        DataTypes.ContractCallInfo memory callInfo,
        address bridgeToken,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.ContractCallStatus status
    ) internal {
        switchEvent.emitCrosschainContractCallDone(
            swapRequest.id,
            swapRequest.bridge,
            swapRequest.recipient,
            callInfo.toContractAddress,
            callInfo.toApprovalAddress,
            bridgeToken,
            swapRequest.dstToken,
            srcAmount,
            dstAmount,
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
     * Call contract function by calldataExecutor contract.
     * This function call be called by this address itself to handle try...catch
     * @param callInfo remote call info
     * @param amount the token amount use during contract call.
     * @param token the token address used during contract call.
     * @param recipient the address to receive receipt token.
     */
    function remoteContractCall(
        DataTypes.ContractCallInfo memory callInfo,
        uint256 amount,
        IERC20 token,
        address recipient
    ) external {
        require(
            msg.sender == address(this),
            "S1"
        );

        uint256 value;
        if (token.isETH()) {
            value = amount;
        } else {
            token.universalTransfer(callDataExecutor, amount);
        }

        // execute calldata for contract call
        ICallDataExecutor(callDataExecutor).execute{value: value}(
            IERC20(token),
            callInfo.toContractAddress,
            callInfo.toApprovalAddress,
            callInfo.contractOutputsToken,
            recipient,
            amount,
            callInfo.toContractGasLimit,
            callInfo.toContractCallData
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
        (
            AxelarSwapRequest memory swapRequest,
            bytes memory encodedCallInfo
        ) = abi.decode(payload, (AxelarSwapRequest, bytes));

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

        if (encodedCallInfo.length != 0) {
            DataTypes.ContractCallInfo memory callInfo = abi.decode(
                encodedCallInfo,
                (DataTypes.ContractCallInfo)
            );

            DataTypes.ContractCallStatus contractCallStatus = DataTypes
                .ContractCallStatus
                .Failed;

            if (
                returnAmount >= swapRequest.estimatedDstTokenAmount &&
                callDataExecutor != address(0)
            ) {
                // execute calldata for contract call
                try
                    this.remoteContractCall(
                        callInfo,
                        swapRequest.estimatedDstTokenAmount,
                        IERC20(swapRequest.dstToken),
                        swapRequest.recipient
                    )
                {
                    returnAmount -= swapRequest.estimatedDstTokenAmount;

                    contractCallStatus = DataTypes.ContractCallStatus.Succeeded;
                } catch {}
            }
            _emitCrosschainContractCallDone(
                swapRequest,
                callInfo,
                bridgeToken,
                amount,
                swapRequest.estimatedDstTokenAmount,
                contractCallStatus
            );
        }

        if (returnAmount != 0) {
            IERC20(swapRequest.dstToken).universalTransfer(
                swapRequest.recipient,
                returnAmount
            );
        }
    }

    function _contractCallWithTokenByAxelar(
        SwapArgsAxelar memory _swapArgs,
        bytes memory callInfo
    ) internal returns (bytes32 transferId, uint256 returnAmount) {
        SwapArgsAxelar memory swapArgs = _swapArgs;

        require(
            swapArgs.expectedReturn >= swapArgs.minReturn,
            "ER GT MR"
        );
        require(
            !IERC20(swapArgs.srcSwap.dstToken).isETH(),
            "SRC NOT ETH"
        );

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
        require(
            returnAmount >= swapArgs.expectedReturn,
            "RA1"
        );

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

        bytes memory payload = abi.encode(
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

    function _swap(
        ISwapRouter.SwapRequest memory swapRequest,
        bool checkUnspent
    ) internal returns (uint256 unspent, uint256 returnAmount) {
        if (address(swapRequest.srcToken) == address(swapRequest.dstToken)) {
            return (0, swapRequest.amountIn);
        } else {
            swapRequest.srcToken.universalApprove(
                address(swapRouter),
                swapRequest.amountIn
            );

            uint256 value = swapRequest.srcToken.isETH()
                ? swapRequest.amountIn
                : 0;
            (unspent, returnAmount) = swapRouter.swap{value: value}(
                ISwapRouter.SwapRequest({
                    srcToken: swapRequest.srcToken,
                    dstToken: swapRequest.dstToken,
                    amountIn: swapRequest.amountIn,
                    amountMinSpend: swapRequest.amountMinSpend,
                    amountOutMin: swapRequest.amountOutMin,
                    useParaswap: swapRequest.useParaswap,
                    paraswapData: swapRequest.paraswapData,
                    splitSwapData: swapRequest.splitSwapData,
                    distribution: swapRequest.distribution,
                    raiseError: swapRequest.raiseError
                })
            );

            require(unspent == 0 || !checkUnspent, "F1");
        }
    }
}
