// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ContractOnlyEthRecipient.sol";
import "./BalancerV2Executor.sol";
import "./BancorV3Executor.sol";
import "./CurveV1Executor.sol";
import "./CurveV2Executor.sol";
import "./DodoV1Executor.sol";
import "./DodoV2Executor.sol";
import "./HashflowExecutor.sol";
import "./MStableExecutor.sol";
import "./TokenExtension.sol";
import "./UniswapV2Executor.sol";
import "./UniswapV3Executor.sol";
import "./Constants.sol";
import "./RevertReasonParser.sol";
import "./ISwapExecutor.sol";
import "./TokenLibrary.sol";
import "./LowLevelHelper.sol";

contract SwapExecutor is
    BalancerV2Executor,
    BancorV3Executor,
    CurveV1Executor,
    CurveV2Executor,
    DodoV1Executor,
    DodoV2Executor,
    HashflowExecutor,
    MStableExecutor,
    UniswapV2Executor,
    UniswapV3Executor,
    ContractOnlyEthRecipient,
    TokenExtension,
    ISwapExecutor
{
    using TokenLibrary for IERC20;

    // solhint-disable-next-line no-empty-blocks
    constructor(IWETH wethArg) TokenExtension(wethArg) {
    }

    function executeSwap(SwapDescription[] calldata swapDescriptions) external payable {
        unchecked {
            for (uint256 i = 0; i < swapDescriptions.length; i++) {
                IERC20 sourceToken = swapDescriptions[i]
                    .sourceToken;
                uint256 balanceToSwap = sourceToken
                    .universalBalanceOf(address(this));
                if (balanceToSwap == 0) {
                    revert SwapTotalAmountCannotBeZero();
                }
                // keeping 1 wei on contract for cheaper swaps
                balanceToSwap--;
                bool asEth = sourceToken.isEth();
                TargetSwapDescription[] calldata swaps = swapDescriptions[i]
                    .swaps;
                for (uint256 j = 0; j < swaps.length; j++) {
                    TargetSwapDescription calldata swap = swaps[j];
                    uint256 poolSwapAmount = (balanceToSwap * swap.tokenRatio) / _ONE;
                    if (poolSwapAmount == 0) {
                        revert SwapAmountCannotBeZero();
                    }
                    uint256 value = asEth ? poolSwapAmount : 0;
                    // solhint-disable avoid-low-level-calls
                    (bool success, bytes memory result) = address(this).call{ value: value }(
                        LowLevelHelper.patchFirstUint(swap.data, poolSwapAmount)
                    );
                    if (!success) {
                        string memory reason = RevertReasonParser.parse(
                            result,
                            "SEEC: "
                        );
                        revert(reason);
                    }
                }
            }
        }
    }
}
