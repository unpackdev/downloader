// SPDX-License-Identifier: UNLICENSED
// Zaap.exchange Contracts (Swapper.sol)
pragma solidity ^0.8.19;

import "./IWETH9.sol";
import "./ISwapRouter02.sol";
import "./IV3SwapRouter.sol";

import "./TransferHelper.sol";

abstract contract Swapper {
    ISwapRouter02 public immutable swapRouter02;

    enum RouterVersion {
        v2,
        v3
    }

    struct PathPart {
        address tokenAddress;
        uint24 poolFee;
    }

    struct SwapParams {
        RouterVersion routerVersion;
        uint256 amountIn;
        PathPart[] pathParts;
        uint256 amountOutMin;
    }

    constructor(address swapRouter02Address_) {
        swapRouter02 = ISwapRouter02(swapRouter02Address_);
    }

    function _swapExact(
        uint256 totalAmountIn,
        SwapParams[] memory swapsParams,
        address fromTokenAddress,
        address toTokenAddress,
        bool revertOnError
    ) internal returns (uint256 totalAmountOut, bool errored) {
        totalAmountOut = 0;
        errored = false;

        TransferHelper.safeApprove(fromTokenAddress, address(swapRouter02), totalAmountIn);

        // Ensuring proportional distribution
        uint256 expectedTotalAmountIn = 0;
        for (uint8 swapParamIndex = 0; swapParamIndex < swapsParams.length; ) {
            SwapParams memory swapParams = swapsParams[swapParamIndex];
            expectedTotalAmountIn += swapParams.amountIn;

            unchecked {
                swapParamIndex++;
            }
        }
        uint256 proportionFactor = (totalAmountIn * 1e18) / expectedTotalAmountIn;

        for (uint8 swapParamIndex = 0; swapParamIndex < swapsParams.length; ) {
            SwapParams memory swapParams = swapsParams[swapParamIndex];
            PathPart[] memory pathParts = swapParams.pathParts;

            PathPart memory firstPathPart = pathParts[0];
            if (firstPathPart.tokenAddress != fromTokenAddress) {
                if (revertOnError) {
                    revert("Swapper: `firstPathPart.tokenAddress` != `fromTokenAddress`");
                } else {
                    errored = true;
                    break;
                }
            }

            PathPart memory lastPathPart = pathParts[pathParts.length - 1];
            if (lastPathPart.tokenAddress != toTokenAddress) {
                if (revertOnError) {
                    revert("Swapper: `lastPathPart.tokenAddress` != `toTokenAddress`");
                } else {
                    errored = true;
                    break;
                }
            }

            uint256 amountIn = (swapParams.amountIn * proportionFactor) / 1e18;
            uint256 amountOutMin = (swapParams.amountOutMin * proportionFactor) / 1e18;

            if (swapParams.routerVersion == RouterVersion.v3) {
                bytes memory pathParam;
                for (uint8 pathPartIndex = 0; pathPartIndex < swapParams.pathParts.length; ) {
                    PathPart memory pathPart = swapParams.pathParts[pathPartIndex];
                    if (pathPart.poolFee == uint24(0)) {
                        pathParam = abi.encodePacked(pathParam, pathPart.tokenAddress);
                    } else {
                        pathParam = abi.encodePacked(pathParam, pathPart.poolFee, pathPart.tokenAddress);
                    }

                    unchecked {
                        pathPartIndex++;
                    }
                }

                IV3SwapRouter.ExactInputParams memory inputParams = IV3SwapRouter.ExactInputParams({
                    path: pathParam,
                    recipient: address(this),
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin
                });

                try swapRouter02.exactInput(inputParams) returns (uint256 amountOut) {
                    totalAmountOut += amountOut;
                } catch Error(string memory reason) {
                    if (revertOnError) {
                        revert(reason);
                    } else {
                        errored = true;
                        break;
                    }
                }
            } else if (swapParams.routerVersion == RouterVersion.v2) {
                address[] memory pathParam = new address[](swapParams.pathParts.length);
                for (uint8 pathPartIndex = 0; pathPartIndex < swapParams.pathParts.length; ) {
                    PathPart memory pathPart = swapParams.pathParts[pathPartIndex];
                    pathParam[pathPartIndex] = pathPart.tokenAddress;

                    unchecked {
                        pathPartIndex++;
                    }
                }

                try swapRouter02.swapExactTokensForTokens(amountIn, amountOutMin, pathParam, address(this)) returns (uint256 amountOut) {
                    totalAmountOut += amountOut;
                } catch Error(string memory reason) {
                    if (revertOnError) {
                        revert(reason);
                    } else {
                        errored = true;
                        break;
                    }
                }
            } else {
                revert("Swapper: `swapParams.routerVersion` must be either 0 or 1");
            }

            unchecked {
                swapParamIndex++;
            }
        }
        if (revertOnError) require(totalAmountOut > 0, "Swapper: `totalAmountOut` must be > 0");
    }
}
