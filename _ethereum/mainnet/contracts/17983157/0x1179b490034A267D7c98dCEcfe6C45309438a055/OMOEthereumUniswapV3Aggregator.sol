// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IBridge.sol";
import "./IWETH.sol";
import "./IUniswapV3SwapRouter.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract OMOEthereumUniswapV3Aggregator is Ownable {
    using SafeERC20 for IERC20;

    event LOG_AGG_SWAP (
        address caller,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut,
        address receiver,
        uint256 fee
    );

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public bridge = 0xa39628ee6Ca80eb2D93f21Def75A7B4D03b82e1E;
    address public feeCollector;

    constructor (address _feeCollector) {
        require(_feeCollector != address(0), "feeCollector address cannot be zero");
        feeCollector = _feeCollector;
    }

    receive() external payable { }

    function exactInputSingle(
        IUniswapV3SwapRouter.ExactInputSingleParams memory params,
        bool unwrapETH
    ) external payable {
        if (params.amountIn == 0) {
            require(msg.sender == IBridge(bridge).callProxy(), "invalid caller");
            params.amountIn = IERC20(params.tokenIn).allowance(msg.sender, address(this));
        }

        _pull(params.tokenIn, params.amountIn, 0);

        (uint amountOut, uint feeAmount, address receiver) = _swap(params, msg.value > 0, unwrapETH, params.recipient);

        if (unwrapETH) {
            require(params.tokenOut == WETH, 'OMOAggregator: INVALID_TOKEN_OUT');

            IWETH(WETH).withdraw(amountOut);

            _sendETH(receiver, amountOut - feeAmount);
            _sendETH(feeCollector, feeAmount);
        } else {
            IERC20(params.tokenOut).safeTransfer(receiver, amountOut - feeAmount);
            IERC20(params.tokenOut).safeTransfer(feeCollector, feeAmount);
        }
    }

    function exactInputSingleCrossChain(
        IUniswapV3SwapRouter.ExactInputSingleParams memory params,
        uint netFee, uint32 destinationDomain, bytes32 recipient, bytes memory callData // args for bridge
    ) external payable {
        _pull(params.tokenIn, params.amountIn, netFee);

        (uint amountOut, uint feeAmount, ) = _swap(params, msg.value > netFee, false, msg.sender);
        IERC20(params.tokenOut).safeTransfer(feeCollector, feeAmount);
        uint bridgeAmount = amountOut - feeAmount;

        IERC20(params.tokenOut).safeApprove(bridge, bridgeAmount);

        IBridge(bridge).bridgeOut{value: netFee}(
            params.tokenOut,
            bridgeAmount,
            destinationDomain,
            recipient,
            callData
        );
    }

    function _pull(address token, uint amount, uint netFee) internal {
        require(msg.value >= netFee, "OMOAggregator: invalid netFee");

        if (msg.value > netFee) {
            require(token == WETH, 'OMOAggregator: INVALID_TOKEN_IN');
            IWETH(WETH).deposit{value: msg.value - netFee}();
        } else {
            require(amount > 0, 'OMOAggregator: INSUFFICIENT_INPUT_AMOUNT');
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function _swap(
        IUniswapV3SwapRouter.ExactInputSingleParams memory params,
        bool nativeIn, bool nativeOut, address logReceiver
    ) internal returns (uint, uint, address) {
        require(params.recipient != address(0), 'OMOAggregator: INVALID_RECIPIENT');
        address receiver = params.recipient;
        params.recipient = address(this);

        IERC20(params.tokenIn).safeApprove(router, params.amountIn);

        uint balanceBefore = IERC20(params.tokenOut).balanceOf(address(this));
        IUniswapV3SwapRouter(router).exactInputSingle(params);
        uint amountOut = IERC20(params.tokenOut).balanceOf(address(this)) - balanceBefore;
        uint feeAmount = amountOut * params.fee / 1000000;

        address tokenIn = params.tokenIn;
        if (nativeIn) tokenIn = address(0);
        address tokenOut = params.tokenOut;
        if (nativeOut) tokenOut = address(0);

        emit LOG_AGG_SWAP(
            msg.sender,
            params.amountIn,
            tokenIn,
            amountOut,
            tokenOut,
            logReceiver,
            feeAmount
        );

        return (amountOut, feeAmount, receiver);
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value:amount}(new bytes(0));
        require(success, 'OMOAggregator: ETH_TRANSFER_FAILED');
    }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "router address cannot be zero");
        router = _router;
    }

    function setBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "bridge address cannot be zero");
        bridge = _bridge;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function rescueFund(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (tokenAddress == WETH && address(this).balance > 0) {
            _sendETH(msg.sender, address(this).balance);
        }
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}
