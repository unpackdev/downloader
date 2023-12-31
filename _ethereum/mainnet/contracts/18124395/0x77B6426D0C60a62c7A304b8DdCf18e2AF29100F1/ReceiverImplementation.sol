// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IAxelarGateway.sol";
import "./ISquidRouter.sol";
import "./ISquidMulticall.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ISquidDepositService.sol";

contract ReceiverImplementation {
    using SafeERC20 for IERC20;

    error ZeroAddressProvided();
    error InvalidSymbol();
    error NothingDeposited();

    address private constant nativeCoin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable router;
    address immutable gateway;

    constructor(address _router, address _gateway) {
        if (_router == address(0) || _gateway == address(0)) revert ZeroAddressProvided();

        router = _router;
        gateway = _gateway;
    }

    // Context: msg.sender == SquidDepositService, this == DepositReceiver
    function receiveAndBridgeCall(
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        address tokenAddress = IAxelarGateway(gateway).tokenAddresses(bridgedTokenSymbol);
        if (tokenAddress == address(0)) revert InvalidSymbol();
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(tokenAddress).approve(router, amount);
        ISquidRouter(router).bridgeCall{value: address(this).balance}(
            bridgedTokenSymbol,
            amount,
            destinationChain,
            destinationAddress,
            payload,
            refundRecipient,
            enableExpress
        );
    }

    // Context: msg.sender == SquidDepositService, this == DepositReceiver
    function receiveAndCallBridge(
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).callBridge{value: address(this).balance}(
            token,
            amount,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress
        );
    }

    function receiveAndCallBridgeCall(
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).callBridgeCall{value: address(this).balance}(
            token,
            amount,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress,
            payload,
            refundRecipient,
            enableExpress
        );
    }

    function receiveAndFundAndRunMulticall(
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();

        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).fundAndRunMulticall{value: address(this).balance}(token, amount, calls);
    }

    function _refund(address tokenToRefund, address refundRecipient) private {
        if (refundRecipient == address(0)) refundRecipient = msg.sender;

        if (tokenToRefund != nativeCoin) {
            uint256 contractBalance = IERC20(tokenToRefund).balanceOf(address(this));
            IERC20(tokenToRefund).safeTransfer(refundRecipient, contractBalance);
        }
    }
}
