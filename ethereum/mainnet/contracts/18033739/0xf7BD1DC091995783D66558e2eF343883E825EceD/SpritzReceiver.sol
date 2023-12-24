// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./ExactInputDelegateSwapModule.sol";

interface ISpritzPay {
    function payWithToken(address paymentTokenAddress, uint256 paymentTokenAmount, bytes32 paymentReference) external;
}

interface IReceiverFactory {
    function getDestinationAddresses() external view returns (address, address);
}

contract SpritzReceiver {
    error NotController();
    error InvalidDestination();
    error SwapFailure();
    error FailedSweep();

    bytes32 private immutable accountReference;
    address private immutable controller;
    address private immutable factory;

    modifier onlyController() {
        if (msg.sender != controller) revert NotController();
        _;
    }

    constructor(address _controller, bytes32 _accountReference) payable {
        controller = _controller;
        accountReference = _accountReference;
        factory = msg.sender;
    }

    function payWithToken(address token, uint256 amount) external onlyController {
        (address spritzPay, ) = getDestinationAddresses();
        _payWithToken(spritzPay, token, amount);
    }

    function payWithSwap(
        uint256 sourceTokenAmount,
        uint256 paymentTokenAmountMin,
        uint256 deadline,
        bytes calldata swapData
    ) external onlyController {
        (address spritzPay, address swapModule) = getDestinationAddresses();

        (address sourceToken, address paymentToken, address weth) = decodeSwapData(swapModule, swapData);
        string memory selector = sourceToken == weth ? "exactInputNativeSwap(bytes)" : "exactInputSwap(bytes)";

        ExactInputDelegateSwapModule.ExactInputParams memory swapParams = ExactInputDelegateSwapModule
            .ExactInputParams({
                inputTokenAmount: sourceTokenAmount,
                paymentTokenAmountMin: paymentTokenAmountMin,
                deadline: deadline,
                swapData: swapData
            });

        uint256 paymentTokenReceived = delegateSwap(swapModule, abi.encodeWithSignature(selector, swapParams));

        _payWithToken(spritzPay, paymentToken, paymentTokenReceived);
    }

    function _payWithToken(address spritzPay, address token, uint256 amount) internal {
        ensureSpritzPayAllowance(spritzPay, token);
        ISpritzPay(spritzPay).payWithToken(address(token), amount, accountReference);
    }

    function ensureSpritzPayAllowance(address spritzPay, address token) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spritzPay);
        if (allowance == 0) {
            IERC20(token).approve(spritzPay, type(uint256).max);
        }
    }

    function getDestinationAddresses() internal view returns (address spritzPay, address swapModule) {
        (spritzPay, swapModule) = IReceiverFactory(factory).getDestinationAddresses();
        if (spritzPay == address(0) || swapModule == address(0)) revert InvalidDestination();
    }

    function decodeSwapData(
        address swapModule,
        bytes calldata swapData
    ) internal view returns (address inputToken, address outputToken, address weth) {
        bytes memory data = abi.encodeWithSelector(ExactInputDelegateSwapModule.decodeSwapData.selector, swapData);

        (bool success, bytes memory result) = swapModule.staticcall(data);
        if (!success) revert SwapFailure();

        (inputToken, outputToken, weth) = abi.decode(result, (address, address, address));
    }

    function delegateSwap(address target, bytes memory data) internal returns (uint256 paymentTokenReceived) {
        (bool success, bytes memory result) = target.delegatecall(data);
        if (!success || result.length == 0) {
            if (result.length == 0) {
                revert SwapFailure();
            } else {
                assembly {
                    let resultSize := mload(result)
                    revert(add(32, result), resultSize)
                }
            }
        }

        (paymentTokenReceived) = abi.decode(result, (uint256));
    }

    /**
     * @dev Withdraw deposited tokens to the given address
     * @param token Token to withdraw
     * @param to Target address
     */
    function sweep(IERC20 token, address to) external onlyController {
        token.transfer(to, token.balanceOf(address(this)));
    }

    /**
     * @dev Withdraw ETH to the given address
     * @param to Target address
     */
    function nativeSweep(address to) external onlyController {
        (bool success, ) = to.call{ value: address(this).balance }("");
        if (!success) revert FailedSweep();
    }

    receive() external payable {}
}
