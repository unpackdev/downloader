// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyalties {
    /*
     * bytes4(keccak256('getOrderinboxRoyalties(LibAsset.AssetType)')) == 0xc4926806
     * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0xbb3bafd6
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xc4926806; // 0xbb3bafd6
}
