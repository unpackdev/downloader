pragma solidity ^0.8.0;

interface IVolumnSwap {
    struct CreateVolV2Params {
        address router;
        address[] path;
        uint256 amountIn;
        uint256 minFirstAmountOut;
        uint16 slippage;
        uint32 loopTimes;
        address to;
    }

    function createVolETHV2(CreateVolV2Params calldata params) external payable;

    struct CreateVolV2NoSlippageParams {
        address router;
        address[] path;
        uint256 amountIn;
        uint32 loopTimes;
        address to;
    }

    function createVolETHV2NoSlippage(
        CreateVolV2NoSlippageParams calldata params
    ) external payable;

    struct BuyVolV2Params {
        address router;
        address[] path;
        uint256 amountIn;
        uint256 minFirstAmountOut;
        uint16 slippage;
        address[] to;
    }

    function buyVolETHV2(BuyVolV2Params calldata params) external payable;

    struct CreateVolV3Params {
        address swapRouter;
        address[] path;
        uint24[] fee;
        uint256 amountIn;
        uint256 minFirstAmountOut;
        uint16 slippage;
        uint32 loopTimes;
        address to;
    }

    function createVolETHV3(CreateVolV3Params calldata params) external payable;
}
