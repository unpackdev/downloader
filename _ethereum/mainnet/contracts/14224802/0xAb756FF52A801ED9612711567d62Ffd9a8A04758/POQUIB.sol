pragma solidity 0.8.11;

import "./IERC20.sol";

contract POQUIB {
    struct SwapInfo {
        address party;
        IERC20 token;
        uint256 tokenAmount;
    }
    function initiateSwap(
        SwapInfo calldata sideA,
        SwapInfo calldata sideB
    )
        external
    {}
    function initiateSwapWithSig(
        SwapInfo calldata sideA,
        SwapInfo calldata sideB,
        bytes calldata partyASignature
    )
        external
    {}

    function completeSwap(
        SwapInfo calldata sideA
    )
        external
    {}

    function completeSwapBySig(
        SwapInfo calldata sideA,
        bytes calldata partyBSignature
    )
        external
    {}

    function cancelSwap(
        SwapInfo calldata sideA
    )
        external
    {}

    function getPendingSwap(
        SwapInfo memory sideA
    )
        public
        view
        returns (SwapInfo memory)
    {}
}
