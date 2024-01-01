// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./IHopBridge.sol";
import "./DataTypes.sol";
import "./Switch.sol";

contract SwitchHop is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public nativeWrap;

    event NativeWrapSet(address _nativeWrap);

    struct TransferArgsHop {
        address fromToken;
        address router;
        address destToken;
        address payable recipient;
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 estimatedDstTokenAmount;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        uint256 nativeFee;
        uint64 dstChainId;
        bytes32 id;
        bytes32 bridge;
    }

    struct SwapArgsHop {
        address fromToken;
        address bridgeToken;
        address destToken;
        address router;
        address payable recipient;
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 minSrcReturn; // min return from swap on src chain
        uint256 estimatedDstTokenAmount;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        uint256 nativeFee;
        uint64 dstChainId;
        bytes32 id;
        bytes32 bridge;
        uint256[] srcDistribution;
        bytes srcParaswapData;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
    }

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _feeCollector
    ) Switch(
        _weth,
        _otherToken,
        _pathCountAndSplit[0],
        _pathCountAndSplit[1],
        _factories,
        _switchViewAddress,
        _switchEventAddress,
        _paraswapProxy,
        _augustusSwapper,
        _feeCollector
    )
        public
    {
        nativeWrap = _weth;
    }

    function setNativeWrap(address _newNativeWrap) external onlyOwner {
        nativeWrap = _newNativeWrap;
        emit NativeWrapSet(nativeWrap);
    }

    function transferByHop(
        TransferArgsHop calldata transferArgs
    )
        external
        payable
        nonReentrant
    {
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(
            IERC20(transferArgs.fromToken),
            transferArgs.amount,
            transferArgs.partner,
            transferArgs.partnerFeeRate
        );
        bool isNative = IERC20(transferArgs.fromToken).isETH();
        uint256 value = isNative ? amountAfterFee + transferArgs.nativeFee : transferArgs.nativeFee;
        if (!isNative) {
            // Give hop bridge approval
            IERC20(transferArgs.fromToken).safeApprove(transferArgs.router, 0);
            IERC20(transferArgs.fromToken).safeApprove(transferArgs.router, amountAfterFee);
        }

        if (block.chainid == 1) {
            // Ethereum L1 -> L2
            IHopBridge(transferArgs.router).sendToL2{ value: value }(
                transferArgs.dstChainId,
                transferArgs.recipient,
                amountAfterFee,
                transferArgs.destinationAmountOutMin,
                transferArgs.destinationDeadline,
                address(0),
                0
            );
        } else {
            // L2 -> L2, L2 -> L1
            require(amountAfterFee >= transferArgs.bonderFee, "Bonder fee cannot exceed amount");
            IHopBridge(transferArgs.router).swapAndSend{ value: value }(
                transferArgs.dstChainId,
                transferArgs.recipient,
                amountAfterFee,
                transferArgs.bonderFee,
                transferArgs.amountOutMin,
                transferArgs.deadline,
                transferArgs.destinationAmountOutMin,
                transferArgs.destinationDeadline
            );
        }

        _emitCrossChainTransferRequest(
            transferArgs,
            bytes32(0),
            amountAfterFee,
            msg.sender,
            DataTypes.SwapStatus.Succeeded
        );
    }

    function swapByHop(
        SwapArgsHop calldata swapArgs
    )
        external
        payable
        nonReentrant
    {
        require(swapArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != swapArgs.dstChainId, "Cannot bridge to same network");

        IERC20(swapArgs.fromToken).universalTransferFrom(msg.sender, address(this), swapArgs.amount);
        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(
            IERC20(swapArgs.fromToken),
            swapArgs.amount,
            swapArgs.partner,
            swapArgs.partnerFeeRate
        );

        address bridgeToken = swapArgs.bridgeToken;
        bool isNativeFromToken = false;
        if (swapArgs.fromToken == swapArgs.bridgeToken) {
            returnAmount = amountAfterFee;
            if (IERC20(swapArgs.fromToken).isETH()) {
                isNativeFromToken = true;
            }
        } else {
            if (swapArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) {
                returnAmount = _swapFromParaswap(swapArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeHop(swapArgs, amountAfterFee);
            }

            require(returnAmount >= swapArgs.minSrcReturn, 'The amount too small');
        }

        require(returnAmount > swapArgs.minSrcReturn, 'The amount too small');
        uint256 value = isNativeFromToken ? returnAmount + swapArgs.nativeFee : swapArgs.nativeFee;
        if (IERC20(swapArgs.bridgeToken).isETH()) {
            bridgeToken = nativeWrap;
        }
        if (!isNativeFromToken) {
            // Give hop bridge approval
            IERC20(swapArgs.bridgeToken).universalApprove(swapArgs.router, amountAfterFee);
        }

        if (block.chainid == 1) {
            // Ethereum L1 -> L2
            IHopBridge(swapArgs.router).sendToL2{ value: value }(
                swapArgs.dstChainId,
                swapArgs.recipient,
                returnAmount,
                swapArgs.destinationAmountOutMin,
                swapArgs.destinationDeadline,
                address(0),
                0
            );
        } else {
            // L2 -> L2, L2 -> L1
            require(returnAmount >= swapArgs.bonderFee, "Bonder fee cannot exceed amount");
            IHopBridge(swapArgs.router).swapAndSend{ value: value }(
                swapArgs.dstChainId,
                swapArgs.recipient,
                returnAmount,
                swapArgs.bonderFee,
                swapArgs.amountOutMin,
                swapArgs.deadline,
                swapArgs.destinationAmountOutMin,
                swapArgs.destinationDeadline
            );
        }

        _emitCrossChainSwapRequest(
            swapArgs,
            bytes32(0),
            amountAfterFee,
            msg.sender,
            DataTypes.SwapStatus.Succeeded
        );
    }

    function _swapBeforeHop(
        SwapArgsHop calldata swapArgs,
        uint256 amount
    )
        private
        returns
    (
        uint256 returnAmount,
        uint256 parts
    )
    {
        parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < swapArgs.srcDistribution.length; i++) {
            if (swapArgs.srcDistribution[i] > 0) {
                parts += swapArgs.srcDistribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");

        // break function to avoid stack too deep error
        returnAmount = _swapInternalForSingleSwap(
            swapArgs.srcDistribution,
            amount,
            parts,
            lastNonZeroIndex,
            IERC20(swapArgs.fromToken),
            IERC20(swapArgs.bridgeToken)
        );
        require(returnAmount > 0, "Swap failed from dex");

        switchEvent.emitSwapped(
            msg.sender,
            address(this),
            IERC20(swapArgs.fromToken),
            IERC20(swapArgs.bridgeToken),
            amount,
            returnAmount,
            0
        );
    }

    function _swapFromParaswap(
        SwapArgsHop calldata swapArgs,
        uint256 amount
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(
            IERC20(swapArgs.fromToken),
            IERC20(swapArgs.bridgeToken),
            amount,
            swapArgs.srcParaswapData
        );
    }

    function _emitCrossChainTransferRequest(
        TransferArgsHop calldata transferArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.SwapStatus status
    )
        internal
    {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.fromToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            status
        );
    }

    function _emitCrossChainSwapRequest(
        SwapArgsHop calldata swapArgs,
        bytes32 transferId,
        uint256 returnAmount,
        address sender,
        DataTypes.SwapStatus status
    )
        internal
    {
        switchEvent.emitCrosschainSwapRequest(
            swapArgs.id,
            transferId,
            swapArgs.bridge,
            sender,
            swapArgs.fromToken,
            swapArgs.bridgeToken,
            swapArgs.destToken,
            swapArgs.amount,
            returnAmount,
            swapArgs.estimatedDstTokenAmount,
            status
        );
    }
}
