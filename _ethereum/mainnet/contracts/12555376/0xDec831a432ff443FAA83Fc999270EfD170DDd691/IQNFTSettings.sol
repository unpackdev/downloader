// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQNFTSettings {
    function favCoinsCount() external view returns (uint256);

    function lockOptionsCount() external view returns (uint256);

    function characterCount() external view returns (uint256);

    function characterPrice(uint32 characterId) external view returns (uint256);

    function favCoinPrices(uint32 favCoinId) external view returns (uint256);

    function lockOptionLockDuration(uint32 lockOptionId)
        external
        view
        returns (uint32);

    function characterMaxSupply(uint32 characterId)
        external
        view
        returns (uint256);

    function calcMintPrice(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    )
        external
        view
        returns (
            uint256 totalPrice,
            uint256 tokenPrice,
            uint256 nonTokenPrice
        );

    function mintStarted() external view returns (bool);

    function mintPaused() external view returns (bool);

    function mintStartTime() external view returns (uint256);

    function mintEndTime() external view returns (uint256);

    function mintFinished() external view returns (bool);

    function onlyAirdropUsers() external view returns (bool);

    function transferAllowedAfterRedeem() external view returns (bool);

    function upgradePriceMultiplier() external view returns (uint256);
}
