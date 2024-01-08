// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";

import "./IPancakeRouter02.sol";
import "./IPangolinRouter02.sol";
import "./IPancakeRouter02BNB.sol";
import "./IWETH.sol";

import "./IOracle.sol";

import "./AssetLib.sol";

library AssetLib2 {
    function calculateBuyAmountOut(
        uint256 amount,
        address currencyIn,
        address[] memory tokensInAsset,
        address[3] memory wethAssetFactoryAndOracle,
        uint256[3] memory totalSupplyDecimalsAndInitialPrice,
        mapping(address => uint256) storage tokensDistribution,
        mapping(address => uint256) storage totalTokenAmount
    ) external view returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        address[] memory path = new address[](2);
        if (currencyIn == address(0)) {
            currencyIn = wethAssetFactoryAndOracle[0];
        }
        if (currencyIn != wethAssetFactoryAndOracle[0]) {
            path[0] = currencyIn;
            path[1] = wethAssetFactoryAndOracle[0];
            address dexRouter =
                AssetLib.getTokenDexRouter(wethAssetFactoryAndOracle[1], currencyIn);
            try IPancakeRouter02(dexRouter).getAmountsOut(amount, path) returns (
                uint256[] memory amounts
            ) {
                amount = amounts[1];
            } catch (bytes memory) {
                amount = 0;
            }
        }
        if (amount == 0) {
            return 0;
        }
        amount -= (amount * 50) / 1e4;
        uint256 restAmount = amount;
        uint256[][2] memory buyAmountsAndDistribution;
        buyAmountsAndDistribution[0] = new uint256[](tokensInAsset.length);
        buyAmountsAndDistribution[1] = new uint256[](tokensInAsset.length);
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 wethToThisToken;
            buyAmountsAndDistribution[1][i] = totalTokenAmount[tokensInAsset[i]];
            if (i < tokensInAsset.length - 1) {
                wethToThisToken = (amount * tokensDistribution[tokensInAsset[i]]) / 1e4;
            } else {
                wethToThisToken = restAmount;
            }
            restAmount -= wethToThisToken;

            if (tokensInAsset[i] != wethAssetFactoryAndOracle[0]) {
                path[0] = wethAssetFactoryAndOracle[0];
                path[1] = tokensInAsset[i];
                address dexRouter =
                    AssetLib.getTokenDexRouter(wethAssetFactoryAndOracle[1], tokensInAsset[i]);
                try IPancakeRouter02(dexRouter).getAmountsOut(wethToThisToken, path) returns (
                    uint256[] memory amounts
                ) {
                    buyAmountsAndDistribution[0][i] = amounts[1];
                } catch (bytes memory) {
                    buyAmountsAndDistribution[0][i] = 0;
                }
            } else {
                buyAmountsAndDistribution[0][i] = wethToThisToken;
            }
        }

        return
            AssetLib.getMintAmount(
                tokensInAsset,
                buyAmountsAndDistribution[0],
                buyAmountsAndDistribution[1],
                totalSupplyDecimalsAndInitialPrice[0],
                totalSupplyDecimalsAndInitialPrice[1],
                IOracle(wethAssetFactoryAndOracle[2]),
                totalSupplyDecimalsAndInitialPrice[2]
            );
    }

    function calculateSellAmountOut(
        uint256[2] memory amountAndTotalSupply,
        address currencyToPay,
        address[] memory tokensInAsset,
        address[2] memory wethAndAssetFactory,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage xVaultAmount
    ) external view returns (uint256) {
        if (amountAndTotalSupply[0] == 0 || amountAndTotalSupply[1] == 0) {
            return 0;
        }
        if (currencyToPay == address(0)) {
            currencyToPay = wethAndAssetFactory[0];
        }
        uint256[] memory feePercentages =
            AssetLib.getFeePercentagesRedeem(tokensInAsset, totalTokenAmount, xVaultAmount);

        address[] memory path = new address[](2);
        uint256 outputAmountTotal;
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 inputAmount =
                (totalTokenAmount[tokensInAsset[i]] * amountAndTotalSupply[0]) /
                    amountAndTotalSupply[1];

            if (inputAmount == 0) {
                continue;
            }

            uint256 outputAmount;
            if (tokensInAsset[i] != currencyToPay) {
                if (
                    currencyToPay == wethAndAssetFactory[0] ||
                    tokensInAsset[i] == wethAndAssetFactory[0]
                ) {
                    address dexRouter;
                    if (tokensInAsset[i] != wethAndAssetFactory[0]) {
                        dexRouter = AssetLib.getTokenDexRouter(
                            wethAndAssetFactory[1],
                            tokensInAsset[i]
                        );
                    } else {
                        dexRouter = AssetLib.getTokenDexRouter(
                            wethAndAssetFactory[1],
                            currencyToPay
                        );
                    }
                    path[0] = tokensInAsset[i];
                    path[1] = currencyToPay;
                    try IPancakeRouter02(dexRouter).getAmountsOut(inputAmount, path) returns (
                        uint256[] memory amounts
                    ) {
                        outputAmount = amounts[1];
                    } catch (bytes memory) {
                        outputAmount = 0;
                    }
                } else {
                    address dexRouter =
                        AssetLib.getTokenDexRouter(wethAndAssetFactory[1], tokensInAsset[i]);
                    path[0] = tokensInAsset[i];
                    path[1] = wethAndAssetFactory[0];
                    try IPancakeRouter02(dexRouter).getAmountsOut(inputAmount, path) returns (
                        uint256[] memory amounts
                    ) {
                        outputAmount = amounts[1];
                    } catch (bytes memory) {
                        outputAmount = 0;
                        continue;
                    }

                    dexRouter = AssetLib.getTokenDexRouter(wethAndAssetFactory[1], currencyToPay);
                    path[0] = wethAndAssetFactory[0];
                    path[1] = currencyToPay;
                    try IPancakeRouter02(dexRouter).getAmountsOut(outputAmount, path) returns (
                        uint256[] memory amounts
                    ) {
                        outputAmount = amounts[1];
                    } catch (bytes memory) {
                        outputAmount = 0;
                    }
                }
            } else {
                outputAmount = inputAmount;
            }

            uint256 fee = (outputAmount * feePercentages[i]) / 1e4;
            outputAmountTotal += outputAmount - fee;
        }

        return outputAmountTotal;
    }

    function xyDistributionAfterMint(
        address[] memory tokensInAsset,
        uint256[] memory buyAmounts,
        uint256[] memory oldDistribution,
        mapping(address => uint256) storage xVaultAmount,
        mapping(address => uint256) storage yVaultAmount
    ) external {
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 totalAmount = buyAmounts[i] + oldDistribution[i];
            uint256 maxAmountInX = (totalAmount * 2000) / 1e4;

            uint256 amountInXOld = xVaultAmount[tokensInAsset[i]];
            uint256 restAmountToDistribute = buyAmounts[i];
            if (amountInXOld < maxAmountInX) {
                amountInXOld += restAmountToDistribute;
                if (amountInXOld > maxAmountInX) {
                    uint256 delta = amountInXOld - maxAmountInX;
                    amountInXOld = maxAmountInX;
                    restAmountToDistribute = delta;
                } else {
                    restAmountToDistribute = 0;
                }
            }

            if (restAmountToDistribute > 0) {
                yVaultAmount[tokensInAsset[i]] += restAmountToDistribute;
            }

            xVaultAmount[tokensInAsset[i]] = amountInXOld;
        }
    }

    function xyDistributionAfterRedeem(
        mapping(address => uint256) storage totalTokenAmount,
        bool isAllowedAutoXYRebalace,
        mapping(address => uint256) storage xVaultAmount,
        mapping(address => uint256) storage yVaultAmount,
        address[] memory tokensInAsset,
        uint256[] memory sellAmounts
    ) public {
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 totalAmount = totalTokenAmount[tokensInAsset[i]];
            uint256 xStopAmount = (totalAmount * 500) / 1e4;
            uint256 xAmountMax = (totalAmount * 2000) / 1e4;

            uint256 xAmount = xVaultAmount[tokensInAsset[i]];
            if (isAllowedAutoXYRebalace == true) {
                uint256 yAmount = yVaultAmount[tokensInAsset[i]];
                require(
                    xAmount + yAmount >= sellAmounts[i] &&
                        xAmount + yAmount - sellAmounts[i] >= xStopAmount,
                    "Not enough XY"
                );
                if (xAmount >= sellAmounts[i] && xAmount - sellAmounts[i] >= xStopAmount) {
                    xAmount -= sellAmounts[i];
                } else {
                    xAmount += yAmount;
                    xAmount -= sellAmounts[i];
                    if (xAmount > xAmountMax) {
                        uint256 delta = xAmount - xAmountMax;
                        yAmount = delta;
                        xAmount = xAmountMax;

                        yVaultAmount[tokensInAsset[i]] = yAmount;
                    }
                }
            } else {
                require(
                    xAmount >= sellAmounts[i] && xAmount - sellAmounts[i] >= xStopAmount,
                    "Not enough X"
                );
                xAmount -= sellAmounts[i];
            }
            xVaultAmount[tokensInAsset[i]] = xAmount;
        }
    }

    function xyDistributionAfterRebase(
        address[] memory tokensInAssetNow,
        uint256[] memory tokensInAssetNowSellAmounts,
        address[] memory tokensToBuy,
        uint256[] memory tokenToBuyAmounts,
        mapping(address => uint256) storage xVaultAmount,
        mapping(address => uint256) storage yVaultAmount,
        mapping(address => uint256) storage totalTokenAmount
    ) external {
        for (uint256 i = 0; i < tokensInAssetNow.length; ++i) {
            uint256 xAmount = xVaultAmount[tokensInAssetNow[i]];
            uint256 yAmount = yVaultAmount[tokensInAssetNow[i]];

            require(
                xAmount + yAmount >= tokensInAssetNowSellAmounts[i],
                "Not enought value in asset"
            );
            if (tokensInAssetNowSellAmounts[i] > yAmount) {
                xAmount -= tokensInAssetNowSellAmounts[i] - yAmount;
                yAmount = 0;
                xVaultAmount[tokensInAssetNow[i]] = xAmount;
                yVaultAmount[tokensInAssetNow[i]] = yAmount;
            } else {
                yAmount -= tokensInAssetNowSellAmounts[i];
                yVaultAmount[tokensInAssetNow[i]] = yAmount;
            }
        }

        for (uint256 i = 0; i < tokensToBuy.length; ++i) {
            uint256 xAmount = xVaultAmount[tokensToBuy[i]];
            uint256 yAmount = yVaultAmount[tokensToBuy[i]];
            uint256 xMaxAmount = (totalTokenAmount[tokensToBuy[i]] * 2000) / 1e4;

            xAmount += tokenToBuyAmounts[i];
            if (xAmount > xMaxAmount) {
                yAmount += xAmount - xMaxAmount;
                xAmount = xMaxAmount;
                xVaultAmount[tokensToBuy[i]] = xAmount;
                yVaultAmount[tokensToBuy[i]] = yAmount;
            } else {
                xVaultAmount[tokensToBuy[i]] = xAmount;
            }
        }
    }

    function xyRebalance(
        uint256 xPercentage,
        address[] memory tokensInAsset,
        mapping(address => uint256) storage xVaultAmount,
        mapping(address => uint256) storage yVaultAmount,
        mapping(address => uint256) storage totalTokenAmount
    ) external {
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 totalAmount = totalTokenAmount[tokensInAsset[i]];
            uint256 xAmount = xVaultAmount[tokensInAsset[i]];
            uint256 yAmount = yVaultAmount[tokensInAsset[i]];
            uint256 xAmountDesired = (totalAmount * xPercentage) / 1e4;

            if (xAmount > xAmountDesired) {
                yAmount += xAmount - xAmountDesired;
                xAmount = xAmountDesired;
                xVaultAmount[tokensInAsset[i]] = xAmount;
                yVaultAmount[tokensInAsset[i]] = yAmount;
            } else if (xAmount < xAmountDesired) {
                uint256 delta = xAmountDesired - xAmount;
                require(yAmount >= delta, "Not enough value in Y");
                xAmount += delta;
                yAmount -= delta;
            } else {
                continue;
            }
            xVaultAmount[tokensInAsset[i]] = xAmount;
            yVaultAmount[tokensInAsset[i]] = yAmount;
        }
    }

    function swapTokensDex(
        address dexRouter,
        address[] memory path,
        uint256 amount
    ) external returns (uint256, bool) {
        try
            IPancakeRouter02(dexRouter).swapExactTokensForETH(
                amount,
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            return (amounts[1], true);
        } catch (bytes memory) {} // solhint-disable-line no-empty-blocks

        try
            IPangolinRouter02(dexRouter).swapExactTokensForAVAX(
                amount,
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            return (amounts[1], true);
        } catch (bytes memory) {} // solhint-disable-line no-empty-blocks

        try
            IPancakeRouter02BNB(dexRouter).swapExactTokensForBNB(
                amount,
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            return (amounts[1], true);
        } catch (bytes memory) {
            return (0, false);
        }
    }

    function addLiquidityETH(
        address dexRouter,
        address token,
        uint256 amount
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        AssetLib.checkAllowance(token, dexRouter, amount);
        try
            IPancakeRouter02(dexRouter).addLiquidityETH(
                token,
                amount,
                0,
                0,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
            return (amountToken, amountETH, liquidity);
        } catch (bytes memory) {} // solhint-disable-line no-empty-blocks

        try
            IPangolinRouter02(dexRouter).addLiquidityAVAX(
                token,
                amount,
                0,
                0,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
            return (amountToken, amountETH, liquidity);
        } catch (bytes memory) {} // solhint-disable-line no-empty-blocks

        try
            IPancakeRouter02BNB(dexRouter).addLiquidityBNB(
                token,
                amount,
                0,
                0,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
            return (amountToken, amountETH, liquidity);
        } catch Error(string memory reason) {
            revert(reason);
        }
        /* catch (bytes memory) {
            revert("Wriong dex router");
        } */
    }

    function removeLiquidityBNB(
        address dexRouter,
        address token,
        address goodToken,
        uint256 amount
    )
        external
        returns (
            uint256,
            uint256,
            bool
        )
    {
        AssetLib.checkAllowance(token, dexRouter, amount);
        try
            IPancakeRouter02(dexRouter).removeLiquidityETH(
                goodToken,
                amount,
                0,
                0,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256 amountToken, uint256 amountETH) {
            return (amountToken, amountETH, true);
        } catch Error(string memory reason) {
            if (compareStrings(reason, string("revert")) == 0) {
                return (0, 0, false);
            }
        }

        try
            IPangolinRouter02(dexRouter).removeLiquidityAVAX(
                goodToken,
                amount,
                0,
                0,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256 amountToken, uint256 amountETH) {
            return (amountToken, amountETH, true);
        } catch Error(string memory reason) {
            if (compareStrings(reason, string("revert")) == 0) {
                return (0, 0, false);
            }
        }

        try
            IPancakeRouter02BNB(dexRouter).removeLiquidityBNB(
                goodToken,
                amount,
                0,
                0,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )
        returns (uint256 amountToken, uint256 amountETH) {
            return (amountToken, amountETH, true);
        } catch (bytes memory) {
            return (0, 0, false);
        }
        /* catch (bytes memory) {
            revert("Wriong dex router");
        } */
    }

    function compareStrings(string memory _a, string memory _b) internal pure returns (int256) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    function fillInformationInSellAndBuyTokens(
        address[] memory tokensInAssetNow,
        uint256[][3] memory tokensInAssetNowInfo,
        address[] memory tokensToBuy,
        uint256[][5] memory tokenToBuyInfo,
        uint256[] memory tokensPrices
    )
        external
        pure
        returns (
            uint256[][3] memory,
            uint256[][5] memory,
            uint256[2] memory
        )
    {
        for (uint256 i = 0; i < tokensInAssetNow.length; ++i) {
            bool isFound = false;
            for (uint256 j = 0; j < tokensToBuy.length && isFound == false; ++j) {
                if (tokensInAssetNow[i] == tokensToBuy[j]) {
                    isFound = true;
                    // mark that we found that token in asset already
                    tokenToBuyInfo[4][j] = 1;

                    if (tokenToBuyInfo[0][j] >= tokensInAssetNowInfo[0][i]) {
                        // if need to buy more than asset already have

                        // amount to sell = 0 (already 0)
                        //tokensInAssetNowInfo[1][i] = 0;

                        // actual amount to buy = (total amount to buy) - (amount in asset already)
                        tokenToBuyInfo[1][j] = tokenToBuyInfo[0][j] - tokensInAssetNowInfo[0][i];
                    } else {
                        // if need to buy less than asset already have

                        // amount to sell = (amount in asset already) - (total amount to buy)
                        tokensInAssetNowInfo[1][i] =
                            tokensInAssetNowInfo[0][i] -
                            tokenToBuyInfo[0][j];

                        // actual amount to buy = 0 (already 0)
                        //tokenToBuyInfo[1][j] = 0;
                    }
                }
            }

            // if we don't find token in _tokensToBuy than we need to sell it all
            if (isFound == false) {
                tokensInAssetNowInfo[1][i] = tokensInAssetNowInfo[0][i];
            }
        }

        // tokenToBuyInfoGlobals info
        // 0 - total weight to buy
        // 1 - number of true tokens to buy
        uint256[2] memory tokenToBuyInfoGlobals;
        for (uint256 i = 0; i < tokensToBuy.length; ++i) {
            if (tokenToBuyInfo[4][i] == 0) {
                // if no found in asset yet

                // actual weight to buy = (amount to buy) * (token price) / decimals
                tokenToBuyInfo[2][i] =
                    (tokenToBuyInfo[0][i] * tokensPrices[i]) /
                    (10**tokenToBuyInfo[3][i]);
            } else if (tokenToBuyInfo[1][i] != 0) {
                // if found in asset and amount to buy != 0

                // actual weight to buy = (actual amount to buy) * (token price) / decimals
                tokenToBuyInfo[2][i] =
                    (tokenToBuyInfo[1][i] * tokensPrices[i]) /
                    (10**tokenToBuyInfo[3][i]);
            } else {
                // if found in asset and amount to buy = 0
                continue;
            }
            // increase total weight
            tokenToBuyInfoGlobals[0] += tokenToBuyInfo[2][i];
            // increase number of true tokens to buy
            ++tokenToBuyInfoGlobals[1];
        }

        return (tokensInAssetNowInfo, tokenToBuyInfo, tokenToBuyInfoGlobals);
    }
}
