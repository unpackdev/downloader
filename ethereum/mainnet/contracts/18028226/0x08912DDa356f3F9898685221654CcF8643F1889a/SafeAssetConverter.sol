// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IAssetConverter.sol";
import "./IERC20.sol";

/// @author YLDR <admin@apyflow.com>
library SafeAssetConverter {
    function safeSwap(IAssetConverter assetConverter, address from, address to, uint256 amount)
        internal
        returns (uint256)
    {
        require(amount <= IERC20(from).balanceOf(address(this)), "SafeAssetConverter: Not enough funds for swap");
        if (from == to) return amount;
        if (amount == 0) return 0;
        return assetConverter.swap(from, to, amount);
    }

    function previewSafeSwap(IAssetConverter assetConverter, address from, address to, uint256 amount)
        internal
        returns (uint256)
    {
        if (from == to) return amount;
        if (amount == 0) return 0;
        return assetConverter.previewSwap(from, to, amount);
    }
}
