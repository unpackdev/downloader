//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IREMXCollection {
    function redeem(
        address account,
        uint256 tokenId,
        uint256 amount,
        uint256 expiryBlock,
        bytes calldata signature
    ) external payable;
}
