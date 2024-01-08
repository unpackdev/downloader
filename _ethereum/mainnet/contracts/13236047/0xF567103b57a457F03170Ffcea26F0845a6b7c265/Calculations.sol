// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LessLibrary.sol";

library Calculations {
    function swapNativeToEth(
        address presale,
        address _library,
        address nativeToken,
        uint256 liqPoolEthAmount
    ) external returns (uint256) {
        LessLibrary safeLibrary = LessLibrary(_library);
        IUniswapV2Router02 uniswap = IUniswapV2Router02(
            safeLibrary.getUniswapRouter()
        );
        address[] memory path = new address[](2);
        path[0] = nativeToken;
        path[1] = uniswap.WETH();
        uint256[] memory amount = uniswap.getAmountsOut(liqPoolEthAmount, path);
        amount = uniswap.swapTokensForExactETH(
            amount[1],
            liqPoolEthAmount,
            path,
            presale,
            block.timestamp + 15 minutes
        );
        return amount[1];
    }

    function usdtToEthFee(address _library)
        external
        view
        returns (uint256 feeEth)
    {
        LessLibrary safeLibrary = LessLibrary(_library);
        IUniswapV2Router02 uniswap = IUniswapV2Router02(
            safeLibrary.getUniswapRouter()
        );
        (uint256 feeFromLib, address tether) = safeLibrary.getUsdFee();
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tether;

        uint256[] memory amounts = uniswap.getAmountsIn(feeFromLib, path);
        return amounts[0];
    }

    function countAmountOfTokens(
        uint256 _hardCap,
        uint256 _tokenPrice,
        uint256 _liqPrice,
        uint256 _liqPerc,
        uint8 _decimals
    ) external pure returns (uint256[] memory) {
        uint256[] memory tokenAmounts = new uint256[](3);
        if (_liqPrice != 0 && _liqPerc != 0) {
            tokenAmounts[0] = ((_hardCap *
                _liqPerc *
                (uint256(10)**uint256(_decimals))) / (_liqPrice * 100));
            require(tokenAmounts[0] > 0, "Wrokng");
        }

        tokenAmounts[1] =
            (_hardCap  * (uint256(10)**uint256(_decimals))) / _tokenPrice;
        tokenAmounts[2] = tokenAmounts[0] + tokenAmounts[1];
        require(tokenAmounts[1] > 0, "Wrong parameters");
        return tokenAmounts;
    }

}