// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./AxelarExecutable.sol";
import "./ICallDataExecutor.sol";
import "./SwitchAxelarAbstract.sol";

contract SwitchContractCallAxelarReceiver is
    SwitchAxelarAbstract,
    AxelarExecutable
{
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    event CallDataExecutorSet(address callDataExecutor);

    address public callDataExecutor;

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
        swapRouter = ISwapRouter(_swapRouter);
    }

    /**
     * set calldataExecutor address
     * @param _newCallDataExecutor new calldataExecutor address
     */
    function setCallDataExecutor(
        address _newCallDataExecutor
    ) external onlyOwner {
        callDataExecutor = _newCallDataExecutor;
        emit CallDataExecutorSet(_newCallDataExecutor);
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
        require(msg.sender == address(this), "S1");

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
}
