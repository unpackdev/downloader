// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOrderRegistry {

    function registerLimitOrder(
        address exchangeAddress,
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    ) external;
}