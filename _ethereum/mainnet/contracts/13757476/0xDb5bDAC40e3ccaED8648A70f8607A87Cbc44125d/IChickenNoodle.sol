// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChickenNoodle {
    // struct to store each token's traits
    struct ChickenNoodleTraits {
        bool minted;
        bool isChicken;
        uint8 backgrounds;
        uint8 snakeBodies;
        uint8 mouthAccessories;
        uint8 pupils;
        uint8 bodyAccessories;
        uint8 hats;
        uint8 tier;
    }

    function MAX_TOKENS() external view returns (uint256);

    function PAID_TOKENS() external view returns (uint256);

    function tokenTraits(uint256 tokenId)
        external
        view
        returns (ChickenNoodleTraits memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to, uint16 tokenId) external;

    function finalize(
        uint16 tokenId,
        ChickenNoodleTraits memory traits,
        address thief
    ) external;
}
