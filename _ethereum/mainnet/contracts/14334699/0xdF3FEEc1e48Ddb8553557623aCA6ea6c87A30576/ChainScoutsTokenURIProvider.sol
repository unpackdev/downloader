//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTokenURIProvider.sol";
import "./Enums.sol";
import "./IRenderer.sol";
import "./OpenSeaMetadata.sol";
import "./Strings.sol";
import "./ChainScoutMetadata.sol";
import "./Sprites.sol";
import "./StringBuffer.sol";

contract ChainScoutsTokenURIProvider is BaseTokenURIProvider {
    using StringBufferLibrary for StringBuffer;
    using Enums for *;

    IRenderer public renderer;

    constructor(IRenderer _renderer) BaseTokenURIProvider("Chain Scout", "6888 Chain Scouts stored 100% on the Ethereum Blockchain\\n\\nChain Scouts is an on-chain project of that aims to implement P2E game theory mechanics, cross-project utility, and metaverse integrations with the goal of developing a robust token ecosystem and diverse community.") {
        renderer = _renderer;
    }

    function extensionKey() public override pure returns (string memory) {
        return "tokenUri";
    }

    function adminSetRenderer(IRenderer _renderer) external onlyAdmin {
        renderer = _renderer;
    }

    function tokenBgColor(uint) internal pure override returns (uint24) {
        return 0xFFFFFF;
    }

    function tokenSvg(uint tokenId) public view override returns (string memory) {
        ChainScoutMetadata memory sm = chainScouts.getChainScoutMetadata(tokenId);

        bytes[] memory sprites = new bytes[](8);
        sprites[0] = BackgroundSprites.getSprite(sm.background);
        sprites[1] = FurSprites.getSprite(sm.fur);
        sprites[2] = ClothingSprites.getSprite(sm.clothing);
        sprites[3] = BackAccessorySprites.getSprite(sm.backaccessory);
        sprites[4] = AccessorySprites.getSprite(sm.accessory);
        sprites[5] = EyesSprites.getSprite(sm.eyes);
        sprites[6] = MouthSprites.getSprite(sm.mouth);
        sprites[7] = HeadSprites.getSprite(sm.head);

        return renderer.render(sprites);
    }

    function scaleStat(uint24 stat, uint16 level) internal pure returns (uint24) {
        uint intermediate = stat;
        for (uint i = 1; i < level; ++i) {
            intermediate = intermediate * 11 / 10;
        }
        return uint24(intermediate);
    }

    function tokenAttributes(uint tokenId) internal view override returns (Attribute[] memory ret) {
        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(tokenId);

        ret = new Attribute[](15);
        ret[0] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Accessory",
            md.accessory.toString()
        );
        ret[1] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Class",
            md.backaccessory.toString()
        );
        ret[2] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Background",
            md.background.toString()
        );
        ret[3] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Clothing",
            md.clothing.toString()
        );
        ret[4] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Eyes",
            md.eyes.toString()
        );
        ret[5] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Fur",
            md.fur.toString()
        );
        ret[6] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Head",
            md.head.toString()
        );
        ret[7] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Mouth",
            md.mouth.toString()
        );
        ret[8] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Attack",
            scaleStat(md.attack, md.level),
            0,
            3
        );
        ret[9] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Defense",
            scaleStat(md.defense, md.level),
            0,
            3
        );
        ret[10] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Luck",
            scaleStat(md.luck, md.level),
            0,
            3
        );
        ret[11] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Speed",
            scaleStat(md.speed, md.level),
            0,
            3
        );
        ret[12] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Strength",
            scaleStat(md.strength, md.level),
            0,
            3
        );
        ret[13] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Intelligence",
            scaleStat(md.intelligence, md.level),
            0,
            3
        );
        ret[14] = OpenSeaMetadataLibrary.makeUintAttribute(
            NumericAttributeType.NUMBER,
            "Level",
            md.level,
            6
        );
    }
}
