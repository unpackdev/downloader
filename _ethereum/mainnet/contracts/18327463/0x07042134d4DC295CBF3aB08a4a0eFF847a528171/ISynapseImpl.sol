pragma solidity ^0.8.13;

interface ISynapseImpl {
    struct SwapQuery {
        address swapAdapter;
        address tokenOut;
        uint256 minAmountOut;
        uint256 deadline;
        bytes rawParams;
    }

    struct T2BRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
    }

    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        SwapQuery calldata originQuery,
        SwapQuery calldata destinationQuery
    ) external view returns (T2BRequest memory);

    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        SwapQuery calldata originQuery,
        SwapQuery calldata destinationQuery
    ) external view returns (T2BRequest memory);
}
