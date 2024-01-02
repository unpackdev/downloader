// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Switch.sol";
import "./ISwapRouter.sol";

abstract contract SwitchAxelarAbstract is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    event SwapRouterSet(address swapRouter);

    ISwapRouter public swapRouter;

    // Used when swap required on dest chain
    struct SwapArgsAxelar {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        string bridgeTokenSymbol;
        address recipient;
        string callTo; // The address of the destination app contract.
        bool useNativeGas; // Indicate ETH or bridge token to pay axelar gas
        uint256 gasAmount; // Gas amount for axelar gmp
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        string dstChain;
        uint64 nonce;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] srcSplitSwapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData; // Can be empty if dst chain is cosmos
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes payload; // Used to send json payload to cosmos chains
    }

    struct AxelarSwapRequest {
        bytes32 id;
        bytes32 bridge;
        address recipient;
        address bridgeToken;
        address dstToken;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData;
        uint256[] dstDistribution;
        uint256 bridgeDstAmount;
        uint256 estimatedDstTokenAmount;
    }

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _swapRouter,
        address _feeCollector
    )
        Switch(
            _weth,
            _otherToken,
            _pathCountAndSplit[0],
            _pathCountAndSplit[1],
            _factories,
            _switchViewAddress,
            _switchEventAddress,
            _paraswapProxy,
            _augustusSwapper,
            _feeCollector
        )
    {
        swapRouter = ISwapRouter(_swapRouter);
    }

    receive() external payable {}

    /**
     * set swapRouter address
     * @param _swapRouter new swapRouter address
     */
    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = ISwapRouter(_swapRouter);
        emit SwapRouterSet(_swapRouter);
    }

    function _swap(
        ISwapRouter.SwapRequest memory swapRequest,
        bool checkUnspent
    ) internal returns (uint256 unspent, uint256 returnAmount) {
        if (address(swapRequest.srcToken) == address(swapRequest.dstToken)) {
            return (0, swapRequest.amountIn);
        } else {
            swapRequest.srcToken.universalApprove(
                address(swapRouter),
                swapRequest.amountIn
            );

            uint256 value = swapRequest.srcToken.isETH()
                ? swapRequest.amountIn
                : 0;
            (unspent, returnAmount) = swapRouter.swap{value: value}(
                ISwapRouter.SwapRequest({
                    srcToken: swapRequest.srcToken,
                    dstToken: swapRequest.dstToken,
                    amountIn: swapRequest.amountIn,
                    amountMinSpend: swapRequest.amountMinSpend,
                    amountOutMin: swapRequest.amountOutMin,
                    useParaswap: swapRequest.useParaswap,
                    paraswapData: swapRequest.paraswapData,
                    splitSwapData: swapRequest.splitSwapData,
                    distribution: swapRequest.distribution,
                    raiseError: swapRequest.raiseError
                })
            );

            require(unspent == 0 || !checkUnspent, "F1");
        }
    }
}
