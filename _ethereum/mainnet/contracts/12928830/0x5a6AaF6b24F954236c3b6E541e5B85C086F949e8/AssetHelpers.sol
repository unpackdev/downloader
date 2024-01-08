// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./EIP20Interface.sol";

contract AssetHelpers {
    /**
     * @dev return asset decimals mantissa. Returns 1e18 if ETH
     */
    function getAssetDecimalsMantissa(address assetAddress) public view returns (uint256){
        uint assetDecimals = 1e18;
        if (assetAddress != address(0)) {
            EIP20Interface token = EIP20Interface(assetAddress);
            assetDecimals = 10 ** uint256(token.decimals());
        }
        return assetDecimals;
    }
}
