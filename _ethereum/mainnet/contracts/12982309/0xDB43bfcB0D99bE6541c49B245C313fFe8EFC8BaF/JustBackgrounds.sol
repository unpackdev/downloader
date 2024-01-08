// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @title JustBackgrounds
/// @author jpegmint.xyz

import "./Ownable.sol";
import "./ERC721PresetCollectible.sol";

/////////////////////////////////////////////////////////////////////////////////
//       __         __    ___           __                              __     //
//   __ / /_ _____ / /_  / _ )___ _____/ /_____ ________  __ _____  ___/ /__   //
//  / // / // (_-</ __/ / _  / _ `/ __/  '_/ _ `/ __/ _ \/ // / _ \/ _  (_-<   //
//  \___/\_,_/___/\__/ /____/\_,_/\__/_/\_\\_, /_/  \___/\_,_/_//_/\_,_/___/   //
//                                        /___/                                //
/////////////////////////////////////////////////////////////////////////////////

contract JustBackgrounds is ERC721PresetCollectible, Ownable {
    using Strings for uint256;

    /// Structs ///
    struct ColorTraits {
        string tokenId;
        string hexCode;
        string name;
        string displayName;
        string family;
        string source;
        string brightness;
        string special;
    }
    
    /// Constants ///
    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";
    bytes private constant _COLOR_NAMES = bytes("AcaciaAccedeAccessAceticAcidicAddictAdobesAffectAlice BlueAmberAmethystAntique WhiteAquaAquamarineAshAssessAssetsAssistAttestAtticsAzureBabiesBaffedBasicsBeadedBeastsBeddedBeefedBeigeBidetsBirchBisqueBlackBlanched AlmondBlueBlue VioletBoastsBobbedBobcatBodiesBoobieBossesBrassBronzeBrownBurly WoodCaddieCadet BlueCeasedCedarChartreuseCherryChocolateCicadaCoffeeCootieCopperCoralCornflower BlueCornsilkCrimsonCyanDabbedDaffedDark BlueDark CyanDark GoldenrodDark GrayDark GreenDark KhakiDark MagentaDark Olive GreenDark OrangeDark OrchidDark RedDark SalmonDark Sea GreenDark Slate BlueDark Slate GrayDark TurquoiseDark VioletDebaseDecadeDecideDeededDeep PinkDeep Sky BlueDefaceDefeatDefectDetectDetestDiamondDibbedDim GrayDiodesDissedDodger BlueDoodadDottedEddiesEffaceEffectEmeraldEstateFacadeFacetsFasciaFastedFibbedFiestaFirFire BrickFittedFloral WhiteFootedForest GreenFuchsiaGainsboroGhost WhiteGoldGoldenrodGrayGreenGreen YellowHoney DewHot PinkIndian RedIndigoIvoryJadeKhakiLavenderLavender BlushLawn GreenLemon ChiffonLight BlueLight CoralLight CyanLight Goldenrod YellowLight GrayLight GreenLight PinkLight SalmonLight Sea GreenLight Sky BlueLight Slate GrayLight Steel BlueLight YellowLimeLime GreenLinenMagentaMahoganyMapleMaroonMedium AquamarineMedium BlueMedium OrchidMedium PurpleMedium Sea GreenMedium Slate BlueMedium Spring GreenMedium TurquoiseMedium Violet RedMidnight BlueMint CreamMisty RoseMoccasinNavajo WhiteNavyOakOdessaOfficeOld LaceOliveOlive DrabOrangeOrange RedOrchidPale GoldenrodPale GreenPale TurquoisePale Violet RedPalladiumPapaya WhipPatinaPeach PuffPearlPeruPinePinkPlatinumPlumPowder BluePurplePyriteQuartzRebecca PurpleRedRedwoodRose GoldRose QuartzRosewoodRosy BrownRoyal BlueRubySaddle BrownSadistSafestSalmonSandy BrownSapphireSassedScoffsSea GreenSea ShellSeabedSecedeSeededSiennaSiestaSilverSky BlueSlate BlueSlate GraySnowSobbedSpring GreenStaticSteel BlueTabbedTacticTanTeakTealTeasedTeasesTestedThistleTictacTidbitToastsToffeeTomatoTootedTransparentTransparent?TurquoiseVioletWalnutWheatWhiteWhite SmokeYellowYellow Green");
    
    /// Variables ///
    bool private _initialized;
    bytes8[] private _colorMetadata;

    /// Mappings ///
    mapping(uint256 => bytes8) private _tokenToColorIndex;

    //================================================================================
    // Constructor & Initialization
    //================================================================================

    /**
     * @dev Constructor. Collectible preset handles most setup.
     */
    constructor()
    ERC721PresetCollectible("JustBackgrounds", "GRNDS", 256, 0.01 ether, 5, 10) {}

    /**
     * @dev Stores metadata for each token and marks as initialized.
     */
    function initializeMetadata(bytes8[] memory colorMetadata) external {
        require(!_initialized, "GRNDS: Metadata already initialized");
        require(colorMetadata.length == _tokenMaxSupply, "GRNDS: Not enough metadata provided");
        _colorMetadata = colorMetadata;
        _initialized = true;
    }
    
    //================================================================================
    // Access Control Wrappers
    //================================================================================

    function startSale() external override onlyOwner {
        require(_initialized, "GRNDS: Metadata not initialized");
        _unpause();
    }

    function pauseSale() external override onlyOwner {
        _pause();
    }
    
    function reserveCollectibles() external onlyOwner {
        require(_initialized, "GRNDS: Metadata not initialized");
        _reserveCollectibles();
    }

    function withdraw() external override onlyOwner {
        _withdraw();
    }

    //================================================================================
    // Minting Functions
    //================================================================================

    /**
     * @dev Select random color, store, and remove from unused in after-mint hook.
     */
    function _afterTokenMint(address, uint256 tokenId) internal override {
        _tokenToColorIndex[tokenId] = _consumeUnusedColor(tokenId);
    }

    /**
     * @dev Selects random color from available colors.
     */
    function _consumeUnusedColor(uint256 tokenId) private returns (bytes8) {
        uint256 index = _reserved ? _generateRandomNum(tokenId) % _colorMetadata.length : tokenId - 1;
        bytes8 color = _colorMetadata[index];
        _colorMetadata[index] = _colorMetadata[_colorMetadata.length - 1];
        _colorMetadata.pop();
        return color;
    }

    /**
     * @dev Generates pseudorandom number.
     */
    function _generateRandomNum(uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, seed)));
    }


    //================================================================================
    // Metadata Functions
    //================================================================================

    /**
     * @dev On-chain, dynamic generation of Background metadata and SVG.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "GRNDS: URI query for nonexistent token");
        
        ColorTraits memory traits = _getColorTraits(tokenId);

        bytes memory byteString;
        byteString = abi.encodePacked(byteString, 'data:application/json;utf8,{');
        byteString = abi.encodePacked(byteString, '"name": "', traits.displayName, '",');
        byteString = abi.encodePacked(byteString, '"description": "', _generateDescriptionFromTraits(traits), '",');
        byteString = abi.encodePacked(byteString, '"created_by": "jpegmint.xyz",');
        byteString = abi.encodePacked(byteString, '"external_url": "https://www.justbackgrounds.xyz/",');
        byteString = abi.encodePacked(byteString, '"image": "data:image/svg+xml;utf8,' ,_generateSvgFromTraits(traits), '",');
        byteString = abi.encodePacked(byteString, '"attributes":', _generateAttributesFromTraits(traits));
        byteString = abi.encodePacked(byteString, '}');
        
        return string(byteString);
    }

    /**
     * @dev Generates Markdown formatted description string.
     */
    function _generateDescriptionFromTraits(ColorTraits memory traits) private pure returns (bytes memory description) {
        
        description = abi.encodePacked(
            '**Just Backgrounds** (b. 2021)\\n\\n'
            ,traits.displayName, '\\n\\n'
            ,'*Hand crafted SVG, ', _checkIfMatch(traits.special, 'Meme') ? '520 x 520' : '1080 x 1080', ' pixels*'
        );

        return description;
    }

    /**
     * @dev Generates SVGs based on traits.
     */
    function _generateSvgFromTraits(ColorTraits memory traits) private pure returns (bytes memory svg) {

        if (_checkIfMatch(traits.special, 'Meme')) {
            svg = abi.encodePacked(svg, "<svg xmlns='http://www.w3.org/2000/svg' width='520' height='520'>");
            svg = abi.encodePacked(svg
                ,"<defs><pattern id='grid' width='20' height='20' patternUnits='userSpaceOnUse'>"
                ,"<rect fill='black' x='0' y='0' width='10' height='10' opacity='0.1'/>"
                ,"<rect fill='white' x='10' y='0' width='10' height='10'/>"
                ,"<rect fill='black' x='10' y='10' width='10' height='10' opacity='0.1'/>"
                ,"<rect fill='white' x='0' y='10' width='10' height='10'/>"
                ,"</pattern></defs>"
                ,"<rect fill='url(#grid)' x='0' y='0' width='100%' height='100%'/>"
            );
        } else {
            svg = abi.encodePacked(svg, "<svg xmlns='http://www.w3.org/2000/svg' width='1080' height='1080'>");
            svg = abi.encodePacked(svg
                ,"<rect width='100%' height='100%' fill='#", traits.hexCode, "'"
                ,_checkIfMatch(traits.special, 'Transparent') ? " opacity='0'" : ""
                ,"/>"
            );
        }

        return abi.encodePacked(svg, '</svg>');
    }

    /**
     * @dev Generates OpenSea style JSON attributes array from on traits.
     */
    function _generateAttributesFromTraits(ColorTraits memory traits) private view returns (bytes memory attributes) {
        attributes = abi.encodePacked('[');
        attributes = abi.encodePacked(attributes,'{"trait_type": "Family", "value": "', traits.family, '"},');
        attributes = abi.encodePacked(attributes,'{"trait_type": "Source", "value": "', traits.source, '"},');
        attributes = abi.encodePacked(attributes,'{"trait_type": "Brightness", "value": "', traits.brightness, '"},');
        if (!_checkIfMatch(traits.special, 'None')) {
            attributes = abi.encodePacked(attributes,'{"trait_type": "Special", "value": "', traits.special, '"},');
        }
        attributes = abi.encodePacked(attributes
            ,'{"trait_type": "Edition", "display_type": "number", "value": ', traits.tokenId
            , ', "max_value": ', _tokenMaxSupply.toString(), '}'
        );
        return abi.encodePacked(attributes, ']');
    }
    
    function _getColorTraits(uint256 tokenId) private view returns (ColorTraits memory) {

        bytes8 colorBytes = _tokenToColorIndex[tokenId];
        ColorTraits memory traits = ColorTraits(
            tokenId.toString(),
            _extractColorHexCode(colorBytes),
            _extractColorName(colorBytes),
            '',
            _extractColorFamily(colorBytes),
            _extractColorSource(colorBytes),
            _extractColorBrightness(colorBytes),
            _extractColorSpecial(colorBytes)
        );

        if (_checkIfMatch(traits.special, 'Transparent') || _checkIfMatch(traits.special, 'Meme')) {
            traits.displayName = traits.name;
        } else {
            traits.displayName = string(abi.encodePacked(traits.name, " #", traits.hexCode));
        }

        return traits;
    }

    function _extractColorHexCode(bytes8 colorBytes) private pure returns (string memory) {
        uint8 r = uint8(colorBytes[0]);
        uint8 g = uint8(colorBytes[1]);
        uint8 b = uint8(colorBytes[2]);
        bytes memory buffer = new bytes(6);
        buffer[0] = _HEX_SYMBOLS[r >> 4 & 0xf];
        buffer[1] = _HEX_SYMBOLS[r & 0xf];
        buffer[2] = _HEX_SYMBOLS[g >> 4 & 0xf];
        buffer[3] = _HEX_SYMBOLS[g & 0xf];
        buffer[4] = _HEX_SYMBOLS[b >> 4 & 0xf];
        buffer[5] = _HEX_SYMBOLS[b & 0xf];
        return string(buffer);
    }

    function _extractColorName(bytes8 colorBytes) private pure returns (string memory) {
        uint256 nameBits = uint8(colorBytes[3]);
        nameBits *= 256;
        nameBits |= uint8(colorBytes[4]);
        nameBits *= 256;
        nameBits |= uint8(colorBytes[5]);

        bytes32 nameBytes = bytes32(nameBits);
        uint256 startIndex = uint256(nameBytes >> 5);
        uint256 endIndex = startIndex + (uint8(uint256(nameBytes)) & 0x1f);

        bytes memory result = new bytes(endIndex - startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = _COLOR_NAMES[i];
        }
        return string(result);
    }

    function _extractColorFamily(bytes8 colorBytes) private pure returns (string memory trait) {
        bytes1 bits = colorBytes[6];

             if (bits == 0x00) trait = 'Blue Colors';
        else if (bits == 0x01) trait = 'Brown Colors';
        else if (bits == 0x02) trait = 'Gray Colors';
        else if (bits == 0x03) trait = 'Green Colors';
        else if (bits == 0x04) trait = 'Orange Colors';
        else if (bits == 0x05) trait = 'Pink Colors';
        else if (bits == 0x06) trait = 'Purple Colors';
        else if (bits == 0x07) trait = 'Red Colors';
        else if (bits == 0x08) trait = 'White Colors';
        else if (bits == 0x09) trait = 'Yellow Colors';
    }

    function _extractColorSource(bytes8 colorBytes) private pure returns (string memory trait) {
        bytes1 bits = colorBytes[7] & 0x03;

             if (bits == 0x00) trait = 'CSS Color';
        else if (bits == 0x01) trait = 'HTML Basic';
        else if (bits == 0x02) trait = 'HTML Extended';
        else if (bits == 0x03) trait = 'Other';
    }

    function _extractColorBrightness(bytes8 colorBytes) private pure returns (string memory trait) {
        bytes1 bits = (colorBytes[7] >> 2) & 0x03;

             if (bits == 0x00) trait = 'Dark';
        else if (bits == 0x01) trait = 'Light';
        else if (bits == 0x02) trait = 'Medium';
    }

    function _extractColorSpecial(bytes8 colorBytes) private pure returns (string memory trait) {
        bytes1 bits = (colorBytes[7] >> 4) & 0x0F;

             if (bits == 0x00) trait = 'None';
        else if (bits == 0x01) trait = 'Gems';
        else if (bits == 0x02) trait = 'HEX Word';
        else if (bits == 0x03) trait = 'Meme';
        else if (bits == 0x04) trait = 'Metallic';
        else if (bits == 0x05) trait = 'Real Word';
        else if (bits == 0x06) trait = 'Transparent';
        else if (bits == 0x07) trait = 'Twin';
        else if (bits == 0x08) trait = 'Woods';
    }

    /**
     * @dev Compares strings and returns whether they match.
     */
    function _checkIfMatch(string memory a, string memory b) private pure returns (bool) {
        return (bytes(a).length == bytes(b).length) && keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
