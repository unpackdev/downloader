pragma solidity 0.8.17;
import "./IERC20.sol";

struct SynapseData {
    SwapQuery originQuery;
    SwapQuery destQuery;
}

struct SwapQuery {
    address swapAdapter;
    address tokenOut;
    uint256 minAmountOut;
    uint256 deadline;
    bytes rawParams;
}

interface ISynapse {
    function bridge(
        address to,
        uint256 chainId,
        address token,
        uint256 amount,
        SwapQuery memory originQuery, // using api call
        SwapQuery memory destQuery // using api call
    ) external payable;

    function calculateBridgeFee(address token, uint256 amount) external view returns (uint256 feeAmount);

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (SwapQuery memory);
}
