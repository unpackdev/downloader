pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

import "./console.sol";

import "./FashionHatPunksData.sol";

interface HatPunkData {
    struct Punk {
        uint16 id;
        uint16 seed;
        PunkAttributeValue sex;
        PunkAttributeValue hair;
        PunkAttributeValue eyes;
        PunkAttributeValue beard;
        PunkAttributeValue ears;
        PunkAttributeValue lips;
        PunkAttributeValue mouth;
        PunkAttributeValue face;
        PunkAttributeValue emotion;
        PunkAttributeValue neck;
        PunkAttributeValue nose;
        PunkAttributeValue cheeks;
        PunkAttributeValue teeth;
    }
    
    enum HatType { BASEBALL, BUCKET, COWBOY, VISOR }
    enum HatSize { REGULAR, SMALL }
    enum HatColor { BLACK, GREY, RED, WHITE, TAN, BROWN }
    enum HatPosition { REGULAR, FLIPPED }
    
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
                                
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    function punkHatType(Punk memory punk) external view returns (HatType);
    function punkHatSize(Punk memory punk) external view returns (HatSize);
    function punkHatColor(Punk memory punk) external view returns (HatColor);
    function punkHatPosition(Punk memory punk) external view returns (HatPosition);
    
    function hatEyePixelGap(Punk memory punk) external view returns (uint8);
    
    function initializePunk(uint16 punkId, uint16 punkSeed) external view returns (Punk memory);
    
    function punkAttributesAsJSON(uint16 punkId, uint16 punkSeed) external view returns (string memory);
}

contract FashionHatPunksRenderer is Ownable {
    using Strings for uint32;
    using Strings for uint16;
    using Strings for uint8;
    using Strings for uint256;
    
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    PunkDataInterface immutable punkDataContract;
    HatPunkData immutable hatDataContract;
    
    mapping(HatPunkData.HatType =>
            mapping(HatPunkData.HatSize =>
            mapping(HatPunkData.HatColor => bytes))) public hatImages;
            
    function setHatImages(HatPunkData.HatType[] memory hatTypes,
                           HatPunkData.HatSize[] memory hatSizes,
                           HatPunkData.HatColor[] memory hatColors,
                           bytes[] memory hatImagesAry) external onlyOwner {

        for (uint i; i < hatTypes.length; i++) {
            HatPunkData.HatType hat = hatTypes[i];
            HatPunkData.HatSize size = hatSizes[i];
            HatPunkData.HatColor color = hatColors[i];
            
            hatImages[hat][size][color] = hatImagesAry[i];
        }
    }
    
    mapping(HatPunkData.PunkAttributeValue => bytes) public nonhatImages;
    
    function setNonhatImages(HatPunkData.PunkAttributeValue[] memory attributeValues, bytes[] memory imageData) external onlyOwner {
        for (uint8 i = 0; i < attributeValues.length; i++) {
            nonhatImages[attributeValues[i]] = imageData[i];
        }
    }
    
    constructor(address fashionHatPunkDataAddress, address punkDataContractAddress) {
      punkDataContract = PunkDataInterface(punkDataContractAddress);
      hatDataContract = HatPunkData(fashionHatPunkDataAddress);
    }
    
    function bytesToSvgRects(bytes memory pixelBytes) public pure returns (string memory rects) {
        uint len = pixelBytes.length;
        
        for (uint i; i < len; ++i) {
            uint8 colorClassInt = uint8(pixelBytes[i]);
            
            if (colorClassInt > 0) {
                uint x = i % 24;
                uint y = i / 24;
                
                rects = string(abi.encodePacked(rects, '<rect x="', x.toString(), '" y="', y.toString(),'" class="c', colorClassInt.toString(), '"/>'));
            }
        }
    }
 
    function hatOverlayPosition(HatPunkData.Punk memory punk) public view returns (int8 x, int8 y) {
        HatPunkData.HatType hat = hatDataContract.punkHatType(punk);
        HatPunkData.HatPosition position = hatDataContract.punkHatPosition(punk);
        int8 gap = int8(hatDataContract.hatEyePixelGap(punk));
        
        if (punk.sex != HatPunkData.PunkAttributeValue.FEMALE) {
            if (position == HatPunkData.HatPosition.FLIPPED) {
                x = -23;    
            }
            
            return (x, -(gap - 1));
        }
        
        if (hat == HatPunkData.HatType.BASEBALL) {
            if (position == HatPunkData.HatPosition.FLIPPED) {
                x = -23;
            } else if (
                punk.hair == HatPunkData.PunkAttributeValue.BLONDE_BOB ||
                punk.hair == HatPunkData.PunkAttributeValue.BLONDE_SHORT ||
                punk.hair == HatPunkData.PunkAttributeValue.STRAIGHT_HAIR_DARK ||
                punk.hair == HatPunkData.PunkAttributeValue.STRAIGHT_HAIR_BLONDE ||
                punk.hair == HatPunkData.PunkAttributeValue.STRAIGHT_HAIR ||
                punk.hair == HatPunkData.PunkAttributeValue.CRAZY_HAIR ||
                punk.hair == HatPunkData.PunkAttributeValue.TASSLE_HAT ||
                punk.hair == HatPunkData.PunkAttributeValue.FRUMPY_HAIR
            ) {
                x = 0;               
            } else {
                x = 1;
            }
        } else {
            if (hat == HatPunkData.HatType.VISOR) {
                punk.hair == HatPunkData.PunkAttributeValue.STRAIGHT_HAIR_BLONDE ? x = 0 : x = 1;
            } else {
                x = 0;
            }
        }
        
        return (x, -(gap - 2));
    }
    
    function intToString(int256 value) internal pure returns (string memory) {
        if (value >= 0) {
            return uint(value).toString();
        } else {
            return string(abi.encodePacked("-", uint(-value).toString()));
        }
    }
    
    function nonHatSvgs(HatPunkData.Punk memory punk) public view returns (bytes memory svg) {
        HatPunkData.PunkAttributeValue female = HatPunkData.PunkAttributeValue.FEMALE;
        HatPunkData.PunkAttributeValue big_shades = HatPunkData.PunkAttributeValue.BIG_SHADES;
        HatPunkData.PunkAttributeValue vr = HatPunkData.PunkAttributeValue.VR;
        HatPunkData.PunkAttributeValue clown_nose = HatPunkData.PunkAttributeValue.CLOWN_NOSE;
        HatPunkData.PunkAttributeValue bandana = HatPunkData.PunkAttributeValue.BANDANA;
        HatPunkData.HatType hat = hatDataContract.punkHatType(punk);
        HatPunkData.HatType visor = HatPunkData.HatType.VISOR;
        HatPunkData.HatType baseball = HatPunkData.HatType.BASEBALL;
        HatPunkData.HatPosition position = hatDataContract.punkHatPosition(punk);
        
        uint y;
        
        if (punk.sex == female && punk.hair == bandana) {
            svg = abi.encodePacked(
                svg,
                '<g>',
                    bytesToSvgRects(nonhatImages[bandana]),
                '</g>'
            );
        }
        
        if (punk.eyes == big_shades) {
            y = punk.sex == female ? 2 : 0;
            
            svg = abi.encodePacked(
                svg,
                '<g transform="translate(0,', y.toString(), ')">',
                    bytesToSvgRects(nonhatImages[big_shades]),
                '</g>'
            );
        } else if (punk.eyes == vr) {
            y = punk.sex == female ? 2 : 0;
            
            if (hat != visor && !(hat == baseball && position == HatPunkData.HatPosition.REGULAR)) {
                svg = abi.encodePacked(
                    svg,
                    '<g transform="translate(0,', y.toString(), ')">',
                        bytesToSvgRects(nonhatImages[vr]),
                    '</g>'
                );
            }

            if (punk.nose == clown_nose) {
                y = punk.sex == female ? 1 : 0;
                
                svg = abi.encodePacked(
                    svg,
                    '<g transform="translate(0,', y.toString(), ')">',
                        bytesToSvgRects(nonhatImages[clown_nose]),
                    '</g>'
                );
            }
        }
    }
    
    function getHatSvg(HatPunkData.Punk memory punk) public view returns (bytes memory) {
        HatPunkData.HatType hat = hatDataContract.punkHatType(punk);
        HatPunkData.HatSize size = hatDataContract.punkHatSize(punk);
        HatPunkData.HatColor color = hatDataContract.punkHatColor(punk);
        HatPunkData.HatPosition position = hatDataContract.punkHatPosition(punk);
        
        (int8 x, int8 y) = hatOverlayPosition(punk);
        
        bytes memory transform = 'transform="';
        
        if (position == HatPunkData.HatPosition.FLIPPED) {
            transform = abi.encodePacked(transform, 'scale(-1, 1) ');
        }
        
        transform = abi.encodePacked(
            transform,
            'translate(', intToString(x), ',', intToString(y), ')"'
        );
        
        return abi.encodePacked(
            '<g ', transform, ' >',
                bytesToSvgRects(hatImages[hat][size][color]),
            '</g>'
        );
    }
    
    function getSpecialMaskCoords(HatPunkData.Punk memory punk) public view returns (uint8 x, uint8 y) {
        HatPunkData.HatType hat = hatDataContract.punkHatType(punk);
        
        if (punk.sex == HatPunkData.PunkAttributeValue.FEMALE &&
            punk.hair == HatPunkData.PunkAttributeValue.HEADBAND
        ) {
            return (5, 11);
        }
        
        if (punk.sex != HatPunkData.PunkAttributeValue.FEMALE &&
            punk.hair == HatPunkData.PunkAttributeValue.WILD_HAIR &&
            hat == HatPunkData.HatType.BASEBALL
        ) {
            return (2, 9);
        }
    }
    
    function getRegularMaskCoords(HatPunkData.Punk memory punk) public view returns (uint8 x, uint8 y) {
        HatPunkData.HatType hat = hatDataContract.punkHatType(punk);
        uint8 gap = hatDataContract.hatEyePixelGap(punk);
        
        if (hat == HatPunkData.HatType.VISOR) {
            return (0, 0);
        }
        
        if (punk.hair == HatPunkData.PunkAttributeValue.BANDANA &&
            punk.sex != HatPunkData.PunkAttributeValue.FEMALE
        ) {
            return (0, 7);
        }
        
        if (punk.sex != HatPunkData.PunkAttributeValue.FEMALE) {
            y++;
            
            if (hat == HatPunkData.HatType.BASEBALL) {
                if (
                    punk.hair == HatPunkData.PunkAttributeValue.CLOWN_HAIR_GREEN ||
                    punk.hair == HatPunkData.PunkAttributeValue.BEANIE ||
                    punk.hair == HatPunkData.PunkAttributeValue.HOODIE
                ) {
                    return (0, 0);
                }
            }
        }
        
        y += gap + 12;
        
        return (x, (23 - y));
    }
    
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
    
    function punkImageSvg(uint16 punkId, uint16 punkSeed, uint32 backgroundColor, bool phunkify) external view returns (string memory) {
        HatPunkData.Punk memory punk = hatDataContract.initializePunk(punkId, punkSeed);
        
        bytes memory pixels = punkDataContract.punkImage(punk.id);
        
        string memory punkRects;
    
        string memory containerOpener = phunkify ? '<g transform="scale(-1,1) translate(-24,0)">' : '<g>';
        
        (uint maskX, uint maskY) = getRegularMaskCoords(punk);
        (uint spMaskX, uint spMaskY) = getSpecialMaskCoords(punk);
        
        bytes memory buffer = new bytes(8);
        for (uint256 y = 0; y < 24; y++) {
            for (uint256 x = 0; x < 24; x++) {
                uint256 p = (y * 24 + x) * 4;
                
                bool pointIsMasked = y <= maskY || x <= maskX;
                
                if (x == spMaskX && y == spMaskY) {
                    pointIsMasked = true;
                }
                
                if (punk.sex == HatPunkData.PunkAttributeValue.FEMALE &&
                    punk.mouth == HatPunkData.PunkAttributeValue.CIGARETTE &&
                    x == 19 && y == 10
                ) {
                    pointIsMasked = false;
                }
                
                if (uint8(pixels[p + 3]) > 0 && !pointIsMasked) {
                    for (uint256 i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    punkRects = string(
                        abi.encodePacked(
                            punkRects,
    '<rect x="', x.toString(),'" y="', y.toString(), '" fill="#', string(buffer), '"/>'
                        )
                    );
                }
            }
        }
        
        bytes memory almostFinalSVG = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.2" viewBox="0 0 24 24">',
                '<style>rect{width:1px;height:1px}.c1{fill:#000000}.c2{fill:#074b3e}.c3{fill:#085949}.c4{fill:#09614f}.c5{fill:#0a6a56}.c6{fill:#142c7c}.c7{fill:#1637a4}.c8{fill:#181818}.c9{fill:#1a43c8}.c10{fill:#222222}.c11{fill:#282828}.c12{fill:#333333}.c13{fill:#3c3c3c}.c14{fill:#44585c}.c15{fill:#4f3623}.c16{fill:#4f666b}.c17{fill:#505050}.c18{fill:#593d28}.c19{fill:#5e402a}.c20{fill:#67462e}.c21{fill:#690c45}.c22{fill:#697984}.c23{fill:#6b7c87}.c24{fill:#7c909c}.c25{fill:#8c0d5b}.c26{fill:#8d8d8d}.c27{fill:#8e240e}.c28{fill:#8f0000}.c29{fill:#908274}.c30{fill:#9a2710}.c31{fill:#9d0000}.c32{fill:#a82b11}.c33{fill:#aa0000}.c34{fill:#aa9a8a}.c35{fill:#ab9b8b}.c36{fill:#ad2160}.c37{fill:#b1a59a}.c38{fill:#b1b1b1}.c39{fill:#b4b4b4}.c40{fill:#b5a99f}.c41{fill:#ba0000}.c42{fill:#bfb2a6}.c43{fill:#cacaca}.c44{fill:#d2d2d2}.c45{fill:#d60000}.c46{fill:#d6c8bb}.c47{fill:#d7c9bc}.c48{fill:#f0f0f0}.c49{fill:#fafafa}</style>',
                containerOpener,
                    '<rect x="0" y="0" style="width:100%;height:100%" fill="#', toHexStringNoPrefix(backgroundColor, 4), '"/>',
                    punkRects,
                    getHatSvg(punk),
                    nonHatSvgs(punk),
                '</g>',
            "</svg>"
        );
        
        // So it will look okay in Safari!
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.2" viewBox="0 0 3072 3072"><image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" href="data:image/svg+xml;base64,',
            Base64.encode(almostFinalSVG),
            '" /></svg>'
        ));
    }
}