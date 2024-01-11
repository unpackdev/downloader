pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

interface ILambDuhMinter {
    enum TokenName {
        BAMBOO,
        PIXL,
        ROOLAH,
        SEED,
        STAR,
        LAMEX,
        SPIT,
        ETH
    }

    function mintPresale(
        bytes32[] memory _proof,
        bytes2 _maxAmountKey,
        uint256 _mintAmount,
        TokenName _tokenName
    ) external payable;
}