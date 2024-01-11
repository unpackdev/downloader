// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./IDex.sol";

abstract contract BaseDex is IDex {
    function quote(address input, address output, uint256 amount) external view returns (uint256) {
        return _quote(input, output, amount);
    }
    function swapAll(SwapAllRequest calldata swapAllRequest) external override returns (uint256 actualOutputAmount) {
        require(address(swapAllRequest.outputToken) != address(0), "BD1");
        require(swapAllRequest.slippage > 0, "BD2");
        uint256 balance = swapAllRequest.inputToken.balanceOf(address(this));

        SwapRequest memory swapRequest = SwapRequest({
            inputToken: swapAllRequest.inputToken,
            outputToken: swapAllRequest.outputToken,
            inputAmount: balance,
            minOutputAmount: _quote(
                address(swapAllRequest.inputToken),
                address(swapAllRequest.outputToken),
                balance
            ) * (1e5 - swapAllRequest.slippage) / 1e5
        });
        actualOutputAmount = _swap(swapRequest);
        emit Swap(
            swapRequest.inputToken,
            swapRequest.outputToken,
            swapRequest.inputAmount,
            actualOutputAmount
        );
    }
    function swap(SwapRequest calldata swapRequest) external override returns (uint256 actualOutputAmount) {
        require(address(swapRequest.outputToken) != address(0), "BD3");
        require(swapRequest.inputAmount > 0, "BD4");
        require(swapRequest.minOutputAmount >= 0, "BD5");
        actualOutputAmount = _swap(swapRequest);
        emit Swap(
            swapRequest.inputToken,
            swapRequest.outputToken,
            swapRequest.inputAmount,
            actualOutputAmount
        );
    }
    function _swap(SwapRequest memory swapRequest) internal virtual returns (uint256) {}
    function _quote(address input, address output, uint256 amount) internal view virtual returns (uint256);
}
