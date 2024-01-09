// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICandyShop {
    function burnBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;
}
