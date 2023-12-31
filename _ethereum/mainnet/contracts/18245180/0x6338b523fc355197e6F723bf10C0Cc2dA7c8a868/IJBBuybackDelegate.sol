// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IJBPayDelegate3_1_1.sol";
import {IJBFundingCycleDataSource3_1_1} from
    "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource3_1_1.sol";
import "./IJBDirectory.sol";
import "./IJBController3_1.sol";
import "./IJBProjects.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3SwapCallback.sol";

import "./IWETH9.sol";

interface IJBBuybackDelegate is IJBPayDelegate3_1_1, IJBFundingCycleDataSource3_1_1, IUniswapV3SwapCallback {
    /////////////////////////////////////////////////////////////////////
    //                             Errors                              //
    /////////////////////////////////////////////////////////////////////

    error JuiceBuyback_MaximumSlippage();
    error JuiceBuyback_InsufficientPayAmount();
    error JuiceBuyback_NotEnoughTokensReceived();
    error JuiceBuyback_NewSecondsAgoTooLow();
    error JuiceBuyback_NoProjectToken();
    error JuiceBuyback_PoolAlreadySet();
    error JuiceBuyback_TransferFailed();
    error JuiceBuyback_InvalidTwapSlippageTolerance();
    error JuiceBuyback_InvalidTwapWindow();
    error JuiceBuyback_Unauthorized();

    /////////////////////////////////////////////////////////////////////
    //                             Events                              //
    /////////////////////////////////////////////////////////////////////

    event BuybackDelegate_Swap(uint256 indexed projectId, uint256 amountIn, IUniswapV3Pool pool, uint256 amountOut, address caller);
    event BuybackDelegate_Mint(uint256 indexed projectId, uint256 amountIn, uint256 tokenCount, address caller);
    event BuybackDelegate_TwapWindowChanged(uint256 indexed projectId, uint256 oldSecondsAgo, uint256 newSecondsAgo, address caller);
    event BuybackDelegate_TwapSlippageToleranceChanged(uint256 indexed projectId, uint256 oldTwapDelta, uint256 newTwapDelta, address caller);
    event BuybackDelegate_PoolAdded(uint256 indexed projectId, address indexed terminalToken, address newPool, address caller);

    /////////////////////////////////////////////////////////////////////
    //                             Getters                             //
    /////////////////////////////////////////////////////////////////////

    function SLIPPAGE_DENOMINATOR() external view returns (uint256);
    function MIN_TWAP_SLIPPAGE_TOLERANCE() external view returns (uint256);
    function MAX_TWAP_SLIPPAGE_TOLERANCE() external view returns (uint256);
    function MIN_TWAP_WINDOW() external view returns (uint256);
    function MAX_TWAP_WINDOW() external view returns (uint256);
    function UNISWAP_V3_FACTORY() external view returns (address);
    function DIRECTORY() external view returns (IJBDirectory);
    function CONTROLLER() external view returns (IJBController3_1);
    function PROJECTS() external view returns (IJBProjects);
    function WETH() external view returns (IWETH9);
    function DELEGATE_ID() external view returns (bytes4);
    function poolOf(uint256 projectId, address terminalToken) external view returns (IUniswapV3Pool pool);
    function twapWindowOf(uint256 projectId) external view returns (uint32 window);
    function twapSlippageToleranceOf(uint256 projectId) external view returns (uint256 slippageTolerance);
    function projectTokenOf(uint256 projectId) external view returns (address projectTokenOf);

    /////////////////////////////////////////////////////////////////////
    //                    State-changing functions                     //
    /////////////////////////////////////////////////////////////////////

    function setPoolFor(uint256 projectId, uint24 fee, uint32 twapWindow, uint256 twapSlippageTolerance, address terminalToken)
        external
        returns (IUniswapV3Pool newPool);

    function setTwapWindowOf(uint256 projectId, uint32 newWindow) external;

    function setTwapSlippageToleranceOf(uint256 projectId, uint256 newSlippageTolerance) external;
}
