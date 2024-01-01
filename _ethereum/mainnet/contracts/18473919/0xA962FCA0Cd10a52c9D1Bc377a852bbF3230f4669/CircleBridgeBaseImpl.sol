// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Errors.sol";
import "./TransferHelper.sol";
import "./BridgeBase.sol";

interface ICircleRouter {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external;
}

contract CircleBridgeBaseImpl is BridgeBase, ReentrancyGuard {
    ICircleRouter public immutable circleRouter;

    constructor(
        ICircleRouter _circleRouter,
        address _router
    ) BridgeBase(_router) {
        circleRouter = _circleRouter;
    }

    event Bridge(
        uint256 amount,
        address fromToken,
        uint256 toChainId,
        address toAddress,
        address toToken,
        string channel,
        uint256 channelFee
    );

    struct CircleData {
        uint32 _destinationDomain;
        address _toTokenAddress;
        bytes32 _mintRecipient;
        address _gasAddress;
        uint256 _gasTokenAmount;
        string _channel;
        uint256 _channelFee;
    }

    receive() external payable {}

    function bridge(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        bytes memory _extraData,
        address _feeAddress
    ) external payable override onlyRouter nonReentrant {
        require(_fromToken != NATIVE_TOKEN_ADDRESS, Errors.TOKEN_NOT_SUPPORTED);
        CircleData memory _circleData = abi.decode(_extraData, (CircleData));

        TransferHelper.safeTransferFrom(
            _fromToken,
            _fromAddress,
            address(this),
            _amount
        );
        uint256 _channelFee = _circleData._channelFee;
        if (_channelFee != 0) {
            uint256 feeAmount = (_amount * _channelFee) / 1000000;
            TransferHelper.safeTransfer(_fromToken, _feeAddress, feeAmount);
            _amount = _amount - feeAmount;
        }
        TransferHelper.safeTransfer(
            _fromToken,
            _circleData._gasAddress,
            _circleData._gasTokenAmount
        );
        uint256 bridgeAmt = _amount - _circleData._gasTokenAmount;
        TransferHelper.safeApprove(_fromToken, address(circleRouter), bridgeAmt);
        circleRouter.depositForBurn(
            bridgeAmt,
            _circleData._destinationDomain,
            _circleData._mintRecipient,
            _fromToken
        );
        emit Bridge(
            _amount,
            _fromToken,
            _toChainId,
            _receiverAddress,
            _circleData._toTokenAddress,
            _circleData._channel,
            _channelFee
        );
    }
}
