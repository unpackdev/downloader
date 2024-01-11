// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./TransferSwapV2.sol";
import "./TransferSwapV3.sol";
import "./TransferSwapInch.sol";
import "./BridgeSwap.sol";
import "./ReentrancyGuard.sol";

contract RubicRouterV2 is TransferSwapV2, TransferSwapV3, TransferSwapInch, BridgeSwap, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event SwapRequestDone(bytes32 id, uint256 dstAmount, SwapStatus status);

    constructor(
        address _messageBus,
        address[] memory _supportedDEXes,
        address _nativeWrap
    ) public {
        messageBus = _messageBus;
        for (uint256 i = 0; i < _supportedDEXes.length; i++) {
            supportedDEXes.add(_supportedDEXes[i]);
        }
        nativeWrap = _nativeWrap;
        feeRubic = 3000;

        _setupRole(DEFAULT_ADMIN_ROLE, 0x105A3BA3637A29D36F61c7F03f55Da44B4591Cd1);
        _setupRole(MANAGER, 0x105A3BA3637A29D36F61c7F03f55Da44B4591Cd1);
        _setupRole(MANAGER, msg.sender);
        _setupRole(EXECUTOR, 0xfe99d38697e107FDAc6e4bFEf876564f70041594);
    }

    /**
     * @notice called by MessageBus when the tokens are checked to be arrived at this contract's address.
               sends the amount received to the receiver. swaps beforehand if swap behavior is defined in message
     * NOTE: if the swap fails, it sends the tokens received directly to the receiver as fallback behavior
     * @param _token the address of the token sent through the bridge
     * @param _amount the amount of tokens received at this contract through the cross-chain bridge
     * @param _srcChainId source chain ID
     * @param _message SwapRequestV2 message that defines the swap behavior on this destination chain
     */
    function executeMessageWithTransfer(
        address,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    )
        external
        payable
        override
        onlyMessageBus
        nonReentrant
        whenNotPaused
        onlyExecutor(_executor)
        returns (ExecutionStatus)
    {
        SwapRequestDest memory m = abi.decode((_message), (SwapRequestDest));
        bytes32 id = _computeSwapRequestId(m.receiver, _srcChainId, uint64(block.chainid), _message);

        _amount = _calculatePlatformFee(m.swap.integrator, _token, _amount);

        if (m.swap.version == SwapVersion.v3) {
            _executeDstSwapV3(_token, _amount, id, m);
        } else if (m.swap.version == SwapVersion.bridge) {
            _executeDstBridge(_token, _amount, id, m);
        } else {
            _executeDstSwapV2(_token, _amount, id, m);
        }

        // always return true since swap failure is already handled in-place
        return ExecutionStatus.Success;
    }

    /**
     * @notice called by MessageBus when the executeMessageWithTransfer call fails. does nothing but emitting a "fail" event
     * @param _srcChainId source chain ID
     * @param _message SwapRequest message that defines the swap behavior on this destination chain
     * execution on dst chain
     */
    function executeMessageWithTransferFallback(
        address, // _sender
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    )
        external
        payable
        override
        onlyMessageBus
        nonReentrant
        whenNotPaused
        onlyExecutor(_executor)
        returns (ExecutionStatus)
    {
        SwapRequestDest memory m = abi.decode((_message), (SwapRequestDest));

        bytes32 id = _computeSwapRequestId(m.receiver, _srcChainId, uint64(block.chainid), _message);

        _sendToken(_token, _amount, m.receiver);

        SwapStatus status = SwapStatus.Fallback;
        txStatusById[id] = status;
        emit SwapRequestDone(id, _amount, status);
        // always return Fail to mark this transfer as failed since if this function is called then there nothing more
        // we can do in this app as the swap failures are already handled in executeMessageWithTransfer
        return ExecutionStatus.Fail;
    }

    // called on source chain for handling of bridge failures (bad liquidity, bad slippage, etc...)
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    )
        external
        payable
        override
        onlyMessageBus
        nonReentrant
        whenNotPaused
        onlyExecutor(_executor)
        returns (ExecutionStatus)
    {
        SwapRequestDest memory m = abi.decode((_message), (SwapRequestDest));

        bytes32 id = _computeSwapRequestId(m.receiver, uint64(block.chainid), m.dstChainId, _message);

        _sendToken(_token, _amount, m.receiver);

        SwapStatus status = SwapStatus.Failed;
        txStatusById[id] = status;
        emit SwapRequestDone(id, _amount, status);

        return ExecutionStatus.Success;
    }

    // no need to swap, directly send the bridged token to user
    function _executeDstBridge(
        address _token,
        uint256 _amount,
        bytes32 _id,
        SwapRequestDest memory _msgDst
    ) private {
        require(
            _token == _msgDst.swap.path[0],
            'bridged token must be the same as the first token in destination swap path'
        );
        require(_msgDst.swap.path.length == 1, 'dst bridge expected');
        _sendToken(_msgDst.swap.path[0], _amount, _msgDst.receiver);

        SwapStatus status;
        txStatusById[_id] = status;
        emit SwapRequestDone(_id, _amount, status);
    }

    function _executeDstSwapV2(
        address _token,
        uint256 _amount,
        bytes32 _id,
        SwapRequestDest memory _msgDst
    ) private {
        require(
            _token == _msgDst.swap.path[0],
            'bridged token must be the same as the first token in destination swap path'
        );
        require(_msgDst.swap.path.length > 1, 'dst swap expected');

        uint256 dstAmount;
        SwapStatus status;

        SwapInfoV2 memory _dstSwap = SwapInfoV2({
            dex: _msgDst.swap.dex,
            path: _msgDst.swap.path,
            deadline: _msgDst.swap.deadline,
            amountOutMinimum: _msgDst.swap.amountOutMinimum
        });

        bool success;
        (success, dstAmount) = _trySwapV2(_dstSwap, _amount);
        if (success) {
            _sendToken(_dstSwap.path[_dstSwap.path.length - 1], dstAmount, _msgDst.receiver);
            status = SwapStatus.Succeeded;
            txStatusById[_id] = status;
        } else {
            // handle swap failure, send the received token directly to receiver
            _sendToken(_token, _amount, _msgDst.receiver);
            dstAmount = _amount;
            status = SwapStatus.Fallback;
            txStatusById[_id] = status;
        }

        emit SwapRequestDone(_id, dstAmount, status);
    }

    function _executeDstSwapV3(
        address _token,
        uint256 _amount,
        bytes32 _id,
        SwapRequestDest memory _msgDst
    ) private {
        require(
            _token == address(_getFirstBytes20(_msgDst.swap.pathV3)),
            'bridged token must be the same as the first token in destination swap path'
        );
        require(_msgDst.swap.pathV3.length > 20, 'dst swap expected');

        uint256 dstAmount;
        SwapStatus status;

        SwapInfoV3 memory _dstSwap = SwapInfoV3({
            dex: _msgDst.swap.dex,
            path: _msgDst.swap.pathV3,
            deadline: _msgDst.swap.deadline,
            amountOutMinimum: _msgDst.swap.amountOutMinimum
        });

        bool success;
        (success, dstAmount) = _trySwapV3(_dstSwap, _amount);
        if (success) {
            _sendToken(address(_getLastBytes20(_dstSwap.path)), dstAmount, _msgDst.receiver);
            status = SwapStatus.Succeeded;
            txStatusById[_id] = status;
        } else {
            // handle swap failure, send the received token directly to receiver
            _sendToken(_token, _amount, _msgDst.receiver);
            dstAmount = _amount;
            status = SwapStatus.Fallback;
            txStatusById[_id] = status;
        }

        emit SwapRequestDone(_id, dstAmount, status);
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver
    ) private {
        if (_token == nativeWrap) {
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}('');
            require(sent, 'failed to send native');
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function setRubicFee(uint256 _feeRubic) external onlyManager {
        require(_feeRubic <= 1000000, 'incorrect fee amount');
        feeRubic = _feeRubic;
    }

    function setRubicShare(address _integrator, uint256 _percent) external onlyManager {
        require(_percent <= 1000000, 'incorrect fee amount');
        require(_integrator != address(0));
        platformShare[_integrator] = _percent;
    }

    // set to 0 to remove integrator
    function setIntegrator(address _integrator, uint256 _percent) external onlyManager {
        require(_percent <= 1000000, 'incorrect fee amount');
        require(_integrator != address(0));
        integratorFee[_integrator] = _percent;
    }

    function pauseRubic() external onlyManager {
        _pause();
    }

    function unPauseRubic() external onlyManager {
        _unpause();
    }

    function setCryptoFee(uint64 _networkID, uint256 _amount) external onlyManager {
        dstCryptoFee[_networkID] = _amount;
    }

    function addSupportedDex(address[] memory _dexes) external onlyManager {
        for (uint256 i = 0; i < _dexes.length; i++) {
            supportedDEXes.add(_dexes[i]);
        }
    }

    function removeSupportedDex(address[] memory _dexes) external onlyManager {
        for (uint256 i = 0; i < _dexes.length; i++) {
            supportedDEXes.remove(_dexes[i]);
        }
    }

    function getSupportedDEXes() public view returns (address[] memory dexes) {
        return supportedDEXes.values();
    }

    function sweepTokens(address _token, uint256 _amount) external onlyManager {
        _sendToken(_token, _amount, msg.sender);
    }

    function integratorCollectFee(address _token, uint256 _amount) external nonReentrant {
        require(integratorFee[msg.sender] > 0, 'not an integrator');
        require(integratorCollectedFee[msg.sender][_token] >= _amount, 'not enough fees');
        _sendToken(_token, _amount, msg.sender);
        integratorCollectedFee[msg.sender][_token] -= _amount;
    }

    function rubicCollectPlatformFee(address _token, uint256 _amount) external onlyManager {
        require(collectedFee[_token] >= _amount, 'amount too big');
        _sendToken(_token, _amount, msg.sender);
        collectedFee[_token] -= _amount;
    }

    function rubicCollectCryptoFee(uint256 _amount) external onlyManager {
        (bool sent, ) = msg.sender.call{value: _amount, gas: 50000}('');
        require(sent, 'failed to send native');
    }

    function setNativeWrap(address _nativeWrap) external onlyManager {
        nativeWrap = _nativeWrap;
    }

    function setMinSwapAmount(address _token, uint256 _amount) external onlyManager {
        minSwapAmount[_token] = _amount;
    }

    function setMaxSwapAmount(address _token, uint256 _amount) external onlyManager {
        maxSwapAmount[_token] = _amount;
    }

    function setMessageBus(address _messageBus) public onlyManager {
        messageBus = _messageBus;
        emit MessageBusUpdated(messageBus);
    }
}
