// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IAvatarVolumeAndFrequency {
    error CallerIsNotSanswap();
    error InvalidTokenId();

    enum Faction {
        UNUSED,
        Chi,
        Umi,
        Sora,
        Mecha,
        Nomad
    }

    event AvatarLevelUp (
        uint256 indexed tokenId,
        uint256 level
    );

    function levelUp(
        uint256 _tokenId,
        uint256 _levelIncreases
    ) external;

    function levelUpBatch(
        uint256[] calldata _tokenIds,
        uint256[] calldata _levelIncreases
    ) external;

    function getVolumeAndFrequency(
        uint256 _tokenId
    ) external view returns (uint128 volume_, uint128 frequency_);

    function tokenFaction(
        uint256 _tokenId
    ) external view returns (Faction);
}
