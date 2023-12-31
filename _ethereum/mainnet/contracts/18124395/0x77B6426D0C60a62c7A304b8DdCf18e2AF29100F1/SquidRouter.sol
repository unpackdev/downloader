// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ISquidRouter.sol";
import "./ISquidMulticall.sol";
import "./AxelarExpressExecutable.sol";
import "./IAxelarGasService.sol";
import "./IAxelarGateway.sol";
import "./IERC20.sol";
import "./SafeTransfer.sol";
import "./Upgradable.sol";
import "./RoledPausable.sol";

contract SquidRouter is ISquidRouter, AxelarExpressExecutable, Upgradable, RoledPausable {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenTransfer for IERC20;

    IAxelarGasService private immutable gasService;
    ISquidMulticall private immutable squidMulticall;

    constructor(
        address _gateway,
        address _gasService,
        address _multicall
    ) AxelarExpressExecutable(_gateway) {
        if (
            _gateway == address(0) ||
            _gasService == address(0) ||
            _multicall == address(0)
        ) revert ZeroAddressProvided();

        gasService = IAxelarGasService(_gasService);
        squidMulticall = ISquidMulticall(_multicall);
    }

    function bridgeCall(
        string calldata bridgedTokenSymbol,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable whenNotPaused {
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        IERC20(bridgedTokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        _bridgeCall(
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }

    function callBridge(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 bridgedTokenAmount = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenAmount);
        gateway.sendToken(destinationChain, destinationAddress, bridgedTokenSymbol, bridgedTokenAmount);
    }

    function callBridgeCall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        _bridgeCall(
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }

    function contractId() external pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }

    function fundAndRunMulticall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] memory calls
    ) public payable whenNotPaused {
        uint256 valueToSend;

        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            valueToSend = amount;
        } else {
            _transferTokenToMulticall(token, amount);
        }

        squidMulticall.run{value: valueToSend}(calls);
    }

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata bridgedTokenSymbol,
        uint256
    ) internal override {
        (ISquidMulticall.Call[] memory calls, address refundRecipient) = abi.decode(
            payload,
            (ISquidMulticall.Call[], address)
        );

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 contractBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(squidMulticall), contractBalance);

        try squidMulticall.run(calls) {
            emit CrossMulticallExecuted(keccak256(payload));
        } catch (bytes memory reason) {
            // Refund tokens to refund recipient if swap fails
            IERC20(bridgedTokenAddress).safeTransfer(refundRecipient, contractBalance);
            emit CrossMulticallFailed(keccak256(payload), reason, refundRecipient);
        }
    }

    function _bridgeCall(
        string calldata bridgedTokenSymbol,
        address bridgedTokenAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) private {
        uint256 bridgedTokenBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        if (address(this).balance > 0) {
            if (enableExpress) {
                gasService.payNativeGasForExpressCallWithToken{value: address(this).balance}(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    bridgedTokenSymbol,
                    bridgedTokenBalance,
                    gasRefundRecipient
                );
            } else {
                gasService.payNativeGasForContractCallWithToken{value: address(this).balance}(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    bridgedTokenSymbol,
                    bridgedTokenBalance,
                    gasRefundRecipient
                );
            }
        }

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenBalance);
        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            bridgedTokenSymbol,
            bridgedTokenBalance
        );
    }

    function _approve(address token, address spender, uint256 amount) private {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            if (allowance > 0) {
                _approveCall(token, spender, 0);
            }
            _approveCall(token, spender, type(uint256).max);
        }
    }

    function _approveCall(address token, address spender, uint256 amount) private {
        // Unlimited approval is not security issue since the contract doesn't store tokens
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, amount));
        if (!success) revert ApprovalFailed();
    }

    function _transferTokenToMulticall(address token, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, address(squidMulticall), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TokenTransferFailed();
    }

    function _setup(bytes calldata data) internal override {
        address _pauser = abi.decode(data, (address));
        if (_pauser == address(0)) revert ZeroAddressProvided();
        _setPauser(_pauser);
    }
}
