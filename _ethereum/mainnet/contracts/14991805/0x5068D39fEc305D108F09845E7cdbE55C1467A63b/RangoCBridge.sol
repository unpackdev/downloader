// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./MessageSenderApp.sol";
import "./MessageReceiverApp.sol";
import "./IUniswapV2.sol";
import "./IWETH.sol";
import "./IMessageBusSender.sol";
import "./RangoCBridgeModels.sol";
import "./IRangoCBridge.sol";
import "./BaseContract.sol";
import "./IRangoMessageReceiver.sol";

contract RangoCBridge is IRangoCBridge, MessageSenderApp, MessageReceiverApp, BaseContract {

    address cBridgeAddress;

    constructor(address _nativeWrappedAddress) {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        baseStorage.nativeWrappedAddress = _nativeWrappedAddress;
        cBridgeAddress = NULL_ADDRESS;
        messageBus = NULL_ADDRESS;
    }

    receive() external payable { }

    event CBridgeIMStatusUpdated(bytes32 id, address token, uint256 outputAmount, OperationStatus status, address _destination);
    event CBridgeSend(address _receiver, address _token, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSlippage);

    enum OperationStatus {
        Created,
        Succeeded,
        RefundInSource,
        RefundInDestination,
        SwapFailedInDestination
    }

    function updateCBridgeAddress(address _address) external onlyOwner {
        cBridgeAddress = _address;
    }

    function updateCBridgeMessageBusSenderAddress(address _address) external onlyOwner {
        setMessageBus(_address);
    }

    // Sender side
    function computeCBridgeSgnFee(RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage) external view returns(uint) {
        bytes memory msgBytes = abi.encode(imMessage);
        return IMessageBus(messageBus).calcFee(msgBytes);
    }

    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external override whenNotPaused nonReentrant {
        require(cBridgeAddress != NULL_ADDRESS, 'cBridge address not set');
        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        approve(_token, cBridgeAddress, _amount);
        IBridge(cBridgeAddress).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        emit CBridgeSend(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
    }

    function cBridgeIM(
        address _fromToken,
        uint _inputAmount,
        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage
    ) external override payable whenNotPaused nonReentrant {
        require(msg.value >= _sgnFee, 'sgnFee is bigger than the input');

        require(messageBus != NULL_ADDRESS, 'cBridge message-bus address not set');
        require(cBridgeAddress != NULL_ADDRESS, 'cBridge address not set');
        require(imMessage.dstChainId == _dstChainId, '_dstChainId and imMessage.dstChainId do not match');

        SafeERC20.safeTransferFrom(IERC20(_fromToken), msg.sender, address(this), _inputAmount);
        approve(_fromToken, cBridgeAddress, _inputAmount);

        bytes memory message = abi.encode(imMessage);

        sendMessageWithTransfer(
            _receiverContract,
            _fromToken,
            _inputAmount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            _sgnFee
        );

        bytes32 id = _computeSwapRequestId(imMessage.originalSender, uint64(block.chainid), _dstChainId, message);
        emit CBridgeIMStatusUpdated(id, _fromToken, _inputAmount, OperationStatus.Created, NULL_ADDRESS);
    }

    // Sender fallback
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        RangoCBridgeModels.RangoCBridgeInterChainMessage memory m = abi.decode((_message), (RangoCBridgeModels.RangoCBridgeInterChainMessage));
        if (m.bridgeNativeOut) {
            _sendToken(
                NULL_ADDRESS,
                _amount,
                m.originalSender,
                true,
                false,
                m.dAppMessage,
                m.dAppSourceContract,
                IRangoMessageReceiver.ProcessStatus.REFUND_IN_SOURCE
            );
        } else {
            _sendToken(
                _token,
                _amount,
                m.originalSender,
                false,
                false,
                m.dAppMessage,
                m.dAppSourceContract,
                IRangoMessageReceiver.ProcessStatus.REFUND_IN_SOURCE
            );
        }

        bytes32 id = _computeSwapRequestId(m.originalSender, uint64(block.chainid), m.dstChainId, _message);
        emit CBridgeIMStatusUpdated(id, _token, _amount, OperationStatus.RefundInSource, m.originalSender);

        return ExecutionStatus.Success;
    }

    // Receiver Side
    function executeMessageWithTransfer(
        address, // _sender
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus whenNotPaused nonReentrant returns (ExecutionStatus) {
        RangoCBridgeModels.RangoCBridgeInterChainMessage memory m = abi.decode((_message), (RangoCBridgeModels.RangoCBridgeInterChainMessage));
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        require(_token == m.path[0], "bridged token must be the same as the first token in destination swap path");
        require(_token == m.fromToken, "bridged token must be the same as the requested swap token");
        if (m.bridgeNativeOut) {
            require(_token == baseStorage.nativeWrappedAddress, "_token must be WETH address");
        }

        bytes32 id = _computeSwapRequestId(m.originalSender, _srcChainId, uint64(block.chainid), _message);
        uint256 dstAmount;
        OperationStatus status = OperationStatus.Succeeded;
        address receivedToken = _token;

        if (m.path.length > 1) {
            if (m.bridgeNativeOut) {
                IWETH(baseStorage.nativeWrappedAddress).deposit{value: _amount}();
            }
            bool ok = true;
            (ok, dstAmount) = _trySwap(m, _amount);
            if (ok) {
                _sendToken(
                    m.toToken,
                    dstAmount,
                    m.recipient,
                    m.nativeOut,
                    true,
                    m.dAppMessage,
                    m.dAppDestContract,
                    IRangoMessageReceiver.ProcessStatus.SUCCESS
                );

                status = OperationStatus.Succeeded;
                receivedToken = m.nativeOut ? NULL_ADDRESS : m.toToken;
            } else {
                // handle swap failure, send the received token directly to receiver
                _sendToken(
                    _token,
                    _amount,
                    m.recipient,
                    false,
                    false,
                    m.dAppMessage,
                    m.dAppDestContract,
                    IRangoMessageReceiver.ProcessStatus.REFUND_IN_DESTINATION
                );

                dstAmount = _amount;
                status = OperationStatus.SwapFailedInDestination;
                receivedToken = _token;
            }
        } else {
            // no need to swap, directly send the bridged token to user
            if (m.bridgeNativeOut) {
                require(m.nativeOut, "You should enable native out when m.bridgeNativeOut is true");
            }
            address sourceToken = m.bridgeNativeOut ? NULL_ADDRESS: _token;
            bool withdraw = m.bridgeNativeOut ? false : true;
            _sendToken(
                sourceToken,
                _amount,
                m.recipient,
                m.nativeOut,
                withdraw,
                m.dAppMessage,
                m.dAppDestContract,
                IRangoMessageReceiver.ProcessStatus.SUCCESS
            );
            dstAmount = _amount;
            status = OperationStatus.Succeeded;
            receivedToken = m.nativeOut ? NULL_ADDRESS : m.path[0];
        }
        emit CBridgeIMStatusUpdated(id, receivedToken, dstAmount, status, m.recipient);
        // always return success since swap failure is already handled in-place
        return ExecutionStatus.Success;
    }

    /**
     * @notice called by MessageBus when the executeMessageWithTransfer call fails. does nothing but emitting a "fail" event
     * @param _srcChainId source chain ID
     * @param _message SwapRequest message that defines the swap behavior on this destination chain
     */
    function executeMessageWithTransferFallback(
        address, // _sender
        address _token, // _token
        uint256 _amount, // _amount
        uint64 _srcChainId,
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus whenNotPaused nonReentrant returns (ExecutionStatus) {
        RangoCBridgeModels.RangoCBridgeInterChainMessage memory m = abi.decode((_message), (RangoCBridgeModels.RangoCBridgeInterChainMessage));
        bytes32 id = _computeSwapRequestId(m.originalSender, _srcChainId, uint64(block.chainid), _message);
        SafeERC20.safeTransfer(IERC20(_token), m.originalSender, _amount);

        emit CBridgeIMStatusUpdated(id, _token, _amount, OperationStatus.RefundInDestination, m.originalSender);
        return ExecutionStatus.Fail;
    }

    // Private utilities
    function _computeSwapRequestId(
        address _sender,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes memory _message
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _srcChainId, _dstChainId, _message));
    }

    function _trySwap(
        RangoCBridgeModels.RangoCBridgeInterChainMessage memory _swap,
        uint256 _amount
    ) private returns (bool ok, uint256 amountOut) {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        require(baseStorage.whitelistContracts[_swap.dexAddress] == true, "Dex address is not whitelisted");
        uint256 zero;
        approve(_swap.fromToken, _swap.dexAddress, _amount);

        try
            IUniswapV2(_swap.dexAddress).swapExactTokensForTokens(
                _amount,
                _swap.amountOutMin,
                _swap.path,
                address(this),
                _swap.deadline
            )
        returns (uint256[] memory amounts) {
            return (true, amounts[amounts.length - 1]);
        } catch {
            return (false, zero);
        }
    }
}