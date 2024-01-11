// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IDex {
    struct SwapRequest {
        uint256 inputAmount;
        uint256 minOutputAmount;
        IERC20Metadata inputToken;
        IERC20Metadata outputToken;
    }
    struct SwapAllRequest {
        uint256 slippage;
        IERC20Metadata inputToken;
        IERC20Metadata outputToken;
    }
    event Swap(
        IERC20Metadata indexed inputToken,
        IERC20Metadata indexed outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    );

    function swapAll(SwapAllRequest memory swapAllRequest) external returns (uint256 actualOutputAmount);
    function swap(SwapRequest memory swapRequest) external returns (uint256 actualOutputAmount);
}
