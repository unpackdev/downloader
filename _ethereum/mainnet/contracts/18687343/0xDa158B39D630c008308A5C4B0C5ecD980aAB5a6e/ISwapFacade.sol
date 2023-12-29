// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ISwapExecutor.sol";

/**
 * @title ISwapFacade
 * @notice Interface for the Facade contract of the aggregator.
 */
interface ISwapFacade {
    struct MinReturnInfo {
        IERC20 token;
        uint256 amount;
        address recipient;
    }

    event Trade(
        address trader,
        address srcToken,
        address dstToken,
        uint256 srcTokenAmount,
        uint256 dstTokenAmount,
        uint256 fees
    );

    function swap(
        ISwapExecutor executor,
        uint256 amount,
        MinReturnInfo[] calldata minReturns,
        ISwapExecutor.TokenTransferInfo[] calldata targetTokenTransferInfos,
        uint256 deadline,
        ISwapExecutor.SwapDescription[] calldata swapDescriptions,
        bytes calldata permit
    ) external payable returns (uint256[] memory);
}
