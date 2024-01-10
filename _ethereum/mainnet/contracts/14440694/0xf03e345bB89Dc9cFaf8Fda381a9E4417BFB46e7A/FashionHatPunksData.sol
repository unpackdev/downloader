// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "./Ownable.sol";
import "./Strings.sol";
import "./StringUtilsLib.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

contract FashionHatPunksData is Ownable {
    using StringUtils for string;
    using Strings for uint16;
    using Strings for uint8;
    using Strings for uint256;
    
    PunkDataInterface immutable punkDataContract;
    
    enum HatType { BASEBALL, BUCKET, COWBOY, VISOR }
    enum HatSize { REGULAR, SMALL }
    enum HatColor { BLACK, GREY, RED, WHITE, TAN, BROWN }
    enum HatPosition { REGULAR, FLIPPED }
    
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    constructor(address punkDataContractAddress) {
        punkDataContract = PunkDataInterface(punkDataContractAddress);
    }
    
    function punkHatType(Punk memory punk) public view returns (HatType result) {
        uint[] memory choiceWeights = new uint[](4);
        
        for (uint i; i < 4; i++) {
            choiceWeights[i] = 25e8;
        }
        
        if (!visorLooksGood[punk.hair][punk.sex]) { 
            choiceWeights[uint(HatType.VISOR)] = 5e8;
        }
        
        if (punk.hair == PunkAttributeValue.COWBOY_HAT) {
            return HatType.COWBOY;
        }
        if (punk.hair == PunkAttributeValue.CAP ||
            punk.hair == PunkAttributeValue.BEANIE ||
            (punk.sex != PunkAttributeValue.FEMALE && originalEyePixelGap(punk) == 2)
        ) {
            return HatType.BASEBALL;
        }
        
        if ((punk.sex == PunkAttributeValue.FEMALE || originalEyePixelGap(punk) == 1) &&
            punk.mouth == PunkAttributeValue.CIGARETTE &&
            (canWearHat(punk, HatType.BUCKET) ||
            (canWearHat(punk, HatType.BASEBALL) && canFlipHat(punk)))
        ) {
            choiceWeights[uint(HatType.COWBOY)] /= 5;
            choiceWeights[uint(HatType.VISOR)] /= 5;
            
            if (!canFlipHat(punk)) {
                choiceWeights[uint(HatType.BASEBALL)] /= 5;
            }
        }
        
        if (punk.seed < 55 && canWearHat(punk, HatType.BASEBALL) &&
            punk.sex != PunkAttributeValue.FEMALE &&
            (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES) &&
            originalEyePixelGap(punk) != 1
        ) {
            return HatType.BASEBALL;
        }
        
        if (punk.seed < 75 &&
           punk.sex != PunkAttributeValue.FEMALE &&
           (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES) &&
           (canWearHat(punk, HatType.COWBOY) || canWearHat(punk, HatType.BUCKET))
        ) {
            choiceWeights[uint(HatType.BASEBALL)] = 0;
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        if (!visibleHairAttribute(punk) && 
            (canWearHat(punk, HatType.COWBOY) ||
             canWearHat(punk, HatType.BASEBALL) ||
             canWearHat(punk, HatType.BUCKET))
        ) {
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        if (punk.sex != PunkAttributeValue.FEMALE &&
            punk.hair == PunkAttributeValue.CLOWN_HAIR_GREEN &&
            (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES)
        ) {
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        if (punk.eyes == PunkAttributeValue.WELDING_GOGGLES && 
            (canWearHat(punk, HatType.COWBOY) ||
             canWearHat(punk, HatType.BASEBALL) ||
             canWearHat(punk, HatType.BUCKET))
        ) {
            choiceWeights[uint(HatType.VISOR)] = 0;
        }
        
        for (uint i; i < 4; i++) {
            if (!canWearHat(punk, HatType(i))) {
                choiceWeights[i] = 0;
            }
        }
        
        uint8 choiceIndex = weightedChoice(punk, choiceWeights, "hat_type");
        return HatType(choiceIndex);
    }
    
    function punkHatColor(Punk memory punk) public view returns (HatColor result) {
        HatType hatType = punkHatType(punk);
        
        uint[] memory choiceWeights = new uint[](6);
        
        if (hatType == HatType.BASEBALL) {
            choiceWeights[uint(HatColor.BLACK)] = 22.5e8;
            choiceWeights[uint(HatColor.GREY)] = 25e8;
            choiceWeights[uint(HatColor.RED)] = 20e8;
            choiceWeights[uint(HatColor.WHITE)] = 25e8;
            choiceWeights[uint(HatColor.TAN)] = 20e8;
            choiceWeights[uint(HatColor.BROWN)] = 0;
        } else if (hatType == HatType.BUCKET) {
            choiceWeights[uint(HatColor.BLACK)] = 50e8;
            choiceWeights[uint(HatColor.GREY)] = 0;
            choiceWeights[uint(HatColor.RED)] = 0;
            choiceWeights[uint(HatColor.WHITE)] = 0;
            choiceWeights[uint(HatColor.TAN)] = 50e8;
            choiceWeights[uint(HatColor.BROWN)] = 50e8;
        } else if (hatType == HatType.COWBOY) {
            choiceWeights[uint(HatColor.BLACK)] = 60e8;
            choiceWeights[uint(HatColor.GREY)] = 20e8;
            choiceWeights[uint(HatColor.RED)] = 0;
            choiceWeights[uint(HatColor.WHITE)] = 0;
            choiceWeights[uint(HatColor.TAN)] = 40e8;
            choiceWeights[uint(HatColor.BROWN)] = 0;
        } else if (hatType == HatType.VISOR) {
            choiceWeights[uint(HatColor.BLACK)] = 22.5e8;
            choiceWeights[uint(HatColor.GREY)] = 25e8;
            choiceWeights[uint(HatColor.RED)] = 20e8;
            choiceWeights[uint(HatColor.WHITE)] = 25e8;
            choiceWeights[uint(HatColor.TAN)] = 20e8;
            choiceWeights[uint(HatColor.BROWN)] = 0;
        }
        
        if (punk.hair == PunkAttributeValue.HOODIE) {
            choiceWeights[uint(HatColor.BLACK)] = 0;
            choiceWeights[uint(HatColor.GREY)] = 0;
            choiceWeights[uint(HatColor.RED)] = 10e8;
            choiceWeights[uint(HatColor.WHITE)] = 30e8;
            choiceWeights[uint(HatColor.TAN)] = 30e8;
        }
        
        if (punk.eyes == PunkAttributeValue.THREE_D_GLASSES || punk.hair == PunkAttributeValue.WILD_WHITE_HAIR) {
            choiceWeights[uint(HatColor.WHITE)] = 0;
        }
        
        if (punk.hair == PunkAttributeValue.DARK_HAIR && hatType == HatType.BUCKET) {
            choiceWeights[uint(HatColor.BLACK)] /= 10;
        }
        
        if (hatType == HatType.VISOR) {
            if (punk.hair == PunkAttributeValue.WILD_HAIR || punk.hair == PunkAttributeValue.HALF_SHAVED ||
               ((punk.hair == PunkAttributeValue.HEADBAND && punk.sex == PunkAttributeValue.FEMALE))) {
                choiceWeights[uint(HatColor.BLACK)] = 0;
            }
            
            if (punk.hair == PunkAttributeValue.WILD_BLONDE) {
                choiceWeights[uint(HatColor.TAN)] = 0;
            }
        }
        
        if (hatType == HatType.COWBOY || hatType == HatType.BUCKET) {
            if (
                eyesWithBlackTop(punk) ||
                punk.hair == PunkAttributeValue.FRUMPY_HAIR ||
                punk.hair == PunkAttributeValue.WILD_HAIR ||
                punk.hair == PunkAttributeValue.HALF_SHAVED
            ) {
                choiceWeights[uint(HatColor.BLACK)] = 0;
            }
        }
        
        if (punk.sex != PunkAttributeValue.FEMALE && (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES)) {
            choiceWeights[uint(HatColor.BLACK)] = 0;
        }
        
        if (punk.hair == PunkAttributeValue.CRAZY_HAIR && (punk.sex == PunkAttributeValue.FEMALE || hatType == HatType.VISOR)) {
            choiceWeights[uint(HatColor.RED)] = 0;
        }
        
        uint8 choiceIndex = weightedChoice(punk, choiceWeights, "hat_color");
        return HatColor(choiceIndex);
    }
    
    function punkHatPosition(Punk memory punk) public view returns (HatPosition result) {
        HatType hatType = punkHatType(punk);
        
        if (hatType != HatType.BASEBALL) {
            return HatPosition.REGULAR;
        }
        
        uint[] memory choiceWeights = new uint[](2);
        
        choiceWeights[uint(HatPosition.REGULAR)] = 50e8;
        choiceWeights[uint(HatPosition.FLIPPED)] = 50e8;
        
        if (punk.hair == PunkAttributeValue.HALF_SHAVED) {
            return HatPosition.FLIPPED;
        }
        
        if (!canFlipHat(punk)) {
            return HatPosition.REGULAR;
        }
        
        if (
            punk.sex != PunkAttributeValue.FEMALE &&
            (punk.eyes == PunkAttributeValue.VR || punk.eyes == PunkAttributeValue.BIG_SHADES) &&
            hatEyePixelGap(punk) == 1
        ) {
            return (punk.eyes == PunkAttributeValue.BIG_SHADES ? HatPosition.REGULAR : HatPosition.FLIPPED);
        }
        
        if ((punk.sex == PunkAttributeValue.FEMALE || originalEyePixelGap(punk) == 1) &&
            punk.mouth == PunkAttributeValue.CIGARETTE
        ) {
            choiceWeights[uint(HatPosition.REGULAR)] /= 10;
        }
        
        if (
            punk.hair == PunkAttributeValue.HOODIE ||
            punk.hair == PunkAttributeValue.BEANIE ||
            originalEyePixelGap(punk) == 2
        ) {
            return HatPosition.REGULAR;
        }
        
        uint8 choiceIndex = weightedChoice(punk, choiceWeights, "hat_position");
        return HatPosition(choiceIndex);
    }
    
    function hatEyePixelGap(Punk memory punk) public view returns (uint8 gap) {
        HatType currentHat = punkHatType(punk);
        
        if (
            currentHat == HatType.VISOR ||
            currentHat == HatType.BUCKET ||
            currentHat == HatType.COWBOY
        ) {
            return 1;
        }
        
        if (punk.hair == PunkAttributeValue.BANDANA) {
            if (punk.sex == PunkAttributeValue.FEMALE) {
                return 1;
            } else {
                if (punk.eyes == PunkAttributeValue.BIG_SHADES || punk.eyes == PunkAttributeValue.VR) {
                    return 2;
                } else {
                    return 1;
                }
            }
        }
        
        uint8 originalGap = originalEyePixelGap(punk);
        
        if (punk.sex != PunkAttributeValue.FEMALE) {
            if (
                punk.hair == PunkAttributeValue.CLOWN_HAIR_GREEN ||
                punk.hair == PunkAttributeValue.HOODIE
            ) {
                return 1;
            } else {
                return (originalGap > 0 ? originalGap : 2);
            }
        }
        
        if (
            (currentHat == HatType.BASEBALL &&
            (punk.hair == PunkAttributeValue.DARK_HAIR || punk.hair == PunkAttributeValue.ORANGE_SIDE)) ||
            (punk.hair == PunkAttributeValue.PINK_WITH_HAT || punk.hair == PunkAttributeValue.STRAIGHT_HAIR ||
             punk.hair == PunkAttributeValue.STRAIGHT_HAIR_BLONDE || punk.hair == PunkAttributeValue.STRAIGHT_HAIR_DARK)
        ) {
            return 1;
        }
        
        return (originalGap > 0 ? originalGap : 2);
    }
    
    function punkHatSize(Punk memory punk) public view returns (HatSize result) {
        HatType currentHat = punkHatType(punk);

        if (punk.sex != PunkAttributeValue.FEMALE) {
            return HatSize.REGULAR;
        }
        
        if (currentHat == HatType.BASEBALL && punk.hair == PunkAttributeValue.CRAZY_HAIR) {
            return HatSize.REGULAR;
        }
        
        if (currentHat == HatType.BUCKET && punk.hair == PunkAttributeValue.WILD_HAIR) {
            return HatSize.REGULAR;
        }
        
        if (
            currentHat == HatType.BUCKET ||
            currentHat == HatType.BASEBALL
        ) {
            if (
                punk.hair == PunkAttributeValue.BLONDE_BOB ||
                punk.hair == PunkAttributeValue.BLONDE_SHORT
            ) {
                return HatSize.REGULAR;
            }
        }
        
        if (
            currentHat == HatType.COWBOY ||
            currentHat == HatType.BUCKET ||
            currentHat == HatType.BASEBALL
        ) {
            if (
                punk.hair == PunkAttributeValue.FRUMPY_HAIR
            ) {
                return HatSize.REGULAR;
            }
        }
        
        if (
            currentHat == HatType.COWBOY ||
            currentHat == HatType.BUCKET
        ) {
            if (
                punk.hair == PunkAttributeValue.HALF_SHAVED ||
                punk.hair == PunkAttributeValue.WILD_BLONDE
            ) {
                return HatSize.REGULAR;
            }
        }
        
        if (
            punk.hair == PunkAttributeValue.STRAIGHT_HAIR_BLONDE ||
            punk.hair == PunkAttributeValue.STRAIGHT_HAIR ||
            punk.hair == PunkAttributeValue.STRAIGHT_HAIR_DARK
        ) {
            return HatSize.REGULAR;
        }
        
        return HatSize.SMALL;
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => bool)) public canFlipHatMapping;
    
    function setcanFlipHatMapping(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes) external onlyOwner {
        for (uint i; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            canFlipHatMapping[hair][sex] = true;
        }
    }
    
    function canFlipHat(Punk memory punk) public view returns (bool) {
        if (!canWearHat(punk, HatType.BASEBALL)) {
            return false;
        }
        
        return canFlipHatMapping[punk.hair][punk.sex];
    }
    
    function randomNumber(Punk memory punk, uint lessThanNumb, string memory seedAddition) public pure returns (uint) {
        uint16 seed = punk.seed;
        uint256 randomNum = uint256(
            keccak256(abi.encodePacked(punk.id.toString(), ":", seed.toString(), seedAddition))
        );
        
        return uint(randomNum % lessThanNumb);
    }
    
    function weightedChoice(Punk memory punk, uint[] memory choiceWeights, string memory seedAddition) public pure returns (uint8) {
        uint sumOfWeights;
        uint numChoices = choiceWeights.length;

        for (uint i; i < numChoices; i++) {
            sumOfWeights += choiceWeights[i];
        }
        
        uint randomNumberInstance = randomNumber(punk, sumOfWeights, seedAddition);
        
        for (uint8 i; i < numChoices; i++) {
            if (randomNumberInstance < choiceWeights[i]) {
                return i;
            } else {
                randomNumberInstance -= choiceWeights[i];
            }
        }
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => bool)) public visorLooksGood;
    
    function setVisorLooksGood(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes) external onlyOwner {
        for (uint i = 0; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            visorLooksGood[hair][sex] = true;
        }
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => bool)) public lacksVisibleHairAttribute;
    
    function setLacksVisibleHairAttribute(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes) external onlyOwner {
        for (uint i = 0; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            lacksVisibleHairAttribute[hair][sex] = true;
        }
    }
    
    function visibleHairAttribute(Punk memory punk) public view returns (bool) {
        return !lacksVisibleHairAttribute[punk.hair][punk.sex];
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => uint8)) public originalEyePixelGapMapping;
    
    function setOriginalEyePixelGap(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes, uint8[] memory gaps) external onlyOwner {
        for (uint i = 0; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            
            originalEyePixelGapMapping[hair][sex] = gaps[i];
        }
    }
    
    function originalEyePixelGap(Punk memory punk) public view returns (uint8 gap) {
        return originalEyePixelGapMapping[punk.hair][punk.sex];
    }
    
    function eyesWithBlackTop(Punk memory punk) public pure returns (bool) {
        if (punk.sex == PunkAttributeValue.FEMALE && punk.eyes == PunkAttributeValue.REGULAR_SHADES) {
            return true;
        }
        
        return (
            punk.eyes == PunkAttributeValue.NERD_GLASSES ||
            punk.eyes == PunkAttributeValue.HORNED_RIM_GLASSES ||
            punk.eyes == PunkAttributeValue.EYE_PATCH ||
            punk.eyes == PunkAttributeValue.EYE_MASK ||
            punk.eyes == PunkAttributeValue.CLASSIC_SHADES ||
            punk.eyes == PunkAttributeValue.BIG_SHADES ||
            punk.eyes == PunkAttributeValue.VR
        );
    }
    
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
    
    function initializePunk(uint16 punkId, uint16 punkSeed) public view returns (Punk memory) {
        Punk memory punk = Punk({
            id: punkId,
            seed: punkSeed,
            sex: PunkAttributeValue.NONE,
            hair: PunkAttributeValue.NONE,
            eyes: PunkAttributeValue.NONE,
            beard: PunkAttributeValue.NONE,
            ears: PunkAttributeValue.NONE,
            lips: PunkAttributeValue.NONE,
            mouth: PunkAttributeValue.NONE,
            face: PunkAttributeValue.NONE,
            emotion: PunkAttributeValue.NONE,
            neck: PunkAttributeValue.NONE,
            nose: PunkAttributeValue.NONE,
            cheeks: PunkAttributeValue.NONE,
            teeth: PunkAttributeValue.NONE
        });
        
        string memory attributes = punkDataContract.punkAttributes(punk.id);

        string[] memory attributeArray = attributes.split(",");
        
        for (uint i = 0; i < attributeArray.length; i++) {
            string memory untrimmedAttribute = attributeArray[i];
            string memory trimmedAttribute;
            
            if (i < 1) {
                trimmedAttribute = untrimmedAttribute.split(' ')[0];
            } else {
                trimmedAttribute = untrimmedAttribute._substring(int(bytes(untrimmedAttribute).length - 1), 1);
            }
            
            PunkAttributeValue attrValue = attrStringToEnumMapping[trimmedAttribute];
            PunkAttributeType attrType = attrValueToTypeEnumMapping[attrValue];
            
            if (attrType == PunkAttributeType.SEX) {
                punk.sex = attrValue;
            } else if (attrType == PunkAttributeType.HAIR) {
                punk.hair = attrValue;
            } else if (attrType == PunkAttributeType.EYES) {
                punk.eyes = attrValue;
            } else if (attrType == PunkAttributeType.BEARD) {
                punk.beard = attrValue;
            } else if (attrType == PunkAttributeType.EARS) {
                punk.ears = attrValue;
            } else if (attrType == PunkAttributeType.LIPS) {
                punk.lips = attrValue;
            } else if (attrType == PunkAttributeType.MOUTH) {
                punk.mouth = attrValue;
            } else if (attrType == PunkAttributeType.FACE) {
                punk.face = attrValue;
            } else if (attrType == PunkAttributeType.EMOTION) {
                punk.emotion = attrValue;
            } else if (attrType == PunkAttributeType.NECK) {
                punk.neck = attrValue;
            } else if (attrType == PunkAttributeType.NOSE) {
                punk.nose = attrValue;
            } else if (attrType == PunkAttributeType.CHEEKS) {
                punk.cheeks = attrValue;
            } else if (attrType == PunkAttributeType.TEETH) {
                punk.teeth = attrValue;
            }
        }
        
        return punk;
    }
    
    function punkAttributesAsJSON(uint16 punkId, uint16 punkSeed) public view returns (string memory json) {
        Punk memory punk = initializePunk(punkId, punkSeed);
        
        PunkAttributeValue none = PunkAttributeValue.NONE;
        bytes memory output = "[";
        
        HatType hat = punkHatType(punk);
        HatColor hatColor = punkHatColor(punk);
        HatPosition hatPosition = punkHatPosition(punk);
        
        PunkAttributeValue[13] memory attrArray = [
            punk.sex,
            (visibleHair(punk) ? punk.hair : none),
            punk.eyes,
            punk.beard,
            punk.ears,
            punk.lips,
            punk.mouth,
            punk.face,
            punk.emotion,
            punk.neck,
            punk.nose,
            punk.cheeks,
            punk.teeth
        ];
        
        bytes memory hatColorBytes;
        
        if (hatColor == HatColor.BLACK) {
            hatColorBytes = "Black";
        } else if (hatColor == HatColor.GREY) {
            hatColorBytes = "Grey";
        } else if (hatColor == HatColor.RED) {
            hatColorBytes = "Red";
        } else if (hatColor == HatColor.WHITE) {
            hatColorBytes = "White";
        } else if (hatColor == HatColor.TAN) {
            hatColorBytes = "Tan";
        } else if (hatColor == HatColor.BROWN) {
            hatColorBytes = "Brown";
        }
        
        bytes memory hatTypeBytes;
        
        if (hat == HatType.BASEBALL) {
            hatTypeBytes = "Baseball Cap";
        } else if (hat == HatType.BUCKET) {
            hatTypeBytes = "Bucket Hat";
        } else if (hat == HatType.COWBOY) {
            hatTypeBytes = "Cowboy Hat";
        } else if (hat == HatType.VISOR) {
            hatTypeBytes = "Visor";
        }
        
        for (uint i = 0; i < 13; ++i) {
            PunkAttributeValue attrVal = attrArray[i];
            
            if (attrVal != none) {
                output = abi.encodePacked(output, punkAttributeAsJSON(attrVal), ",");
            }
        }
        
        bytes memory hatName = abi.encodePacked(hatColorBytes, " ", hatTypeBytes);
        
        if (hatPosition == HatPosition.FLIPPED) {
            hatName = abi.encodePacked("Backwards ", hatName);
        }
        
        bytes memory hatTrait = abi.encodePacked(
            '{"trait_type":"Fashion Hat", "value":"', hatName, '"}'
        );
        
        return string(abi.encodePacked(output, hatTrait, "]"));
    }
    
    function punkAttributeAsJSON(PunkAttributeValue attribute) internal view returns (string memory json) {
        require(attribute != PunkAttributeValue.NONE);
        
        string memory attributeAsString = attrEnumToStringMapping[attribute];
        string memory attributeTypeAsString;
        
        PunkAttributeType attrType = attrValueToTypeEnumMapping[attribute];
        
        if (attrType == PunkAttributeType.SEX) {
            attributeTypeAsString = "Sex";
        } else if (attrType == PunkAttributeType.HAIR) {
            attributeTypeAsString = "Hair";
        } else if (attrType == PunkAttributeType.EYES) {
            attributeTypeAsString = "Eyes";
        } else if (attrType == PunkAttributeType.BEARD) {
            attributeTypeAsString = "Beard";
        } else if (attrType == PunkAttributeType.EARS) {
            attributeTypeAsString = "Ears";
        } else if (attrType == PunkAttributeType.LIPS) {
            attributeTypeAsString = "Lips";
        } else if (attrType == PunkAttributeType.MOUTH) {
            attributeTypeAsString = "Mouth";
        } else if (attrType == PunkAttributeType.FACE) {
            attributeTypeAsString = "Face";
        } else if (attrType == PunkAttributeType.EMOTION) {
            attributeTypeAsString = "Emotion";
        } else if (attrType == PunkAttributeType.NECK) {
            attributeTypeAsString = "Neck";
        } else if (attrType == PunkAttributeType.NOSE) {
            attributeTypeAsString = "Nose";
        } else if (attrType == PunkAttributeType.CHEEKS) {
            attributeTypeAsString = "Cheeks";
        } else if (attrType == PunkAttributeType.TEETH) {
            attributeTypeAsString = "Teeth";
        }
        
        return string(abi.encodePacked('{"trait_type":"', attributeTypeAsString, '", "value":"', attributeAsString, '"}'));
    }
    
    function visibleHair(Punk memory punk) public view returns (bool) {
        HatType hat = punkHatType(punk);

        if (visibleHairAttribute(punk)) { return true; }
        
        if (punk.hair == PunkAttributeValue.BEANIE && hat == HatType.BASEBALL) {
            return true;
        }
        
        bool tiaraBlocked = punk.eyes == PunkAttributeValue.REGULAR_SHADES ||
                            punk.eyes == PunkAttributeValue.CLASSIC_SHADES ||
                            punk.eyes == PunkAttributeValue.HORNED_RIM_GLASSES ||
                            punk.eyes == PunkAttributeValue.THREE_D_GLASSES ||
                            punk.eyes == PunkAttributeValue.EYE_PATCH ||
                            punk.eyes == PunkAttributeValue.EYE_MASK;
                             
        if (punk.hair == PunkAttributeValue.TIARA && (!tiaraBlocked || hatEyePixelGap(punk) == 2)) {
            return true;
        }
        
        return false;
    }
    
    mapping(PunkAttributeValue => PunkAttributeType) public attrValueToTypeEnumMapping;
    
    function setAttrValueToTypeEnumMapping(uint8[][] memory attrValuesAndTypes) external onlyOwner {
        for (uint i; i < attrValuesAndTypes.length; i++) {
            PunkAttributeValue attrVal = PunkAttributeValue(attrValuesAndTypes[i][0]);
            PunkAttributeType attrType = PunkAttributeType(attrValuesAndTypes[i][1]);
            
            attrValueToTypeEnumMapping[attrVal] = attrType;
        }
    }
    
    mapping(string => PunkAttributeValue) public attrStringToEnumMapping;
    mapping(PunkAttributeValue => string) public attrEnumToStringMapping;
    
    function setAttrStringToEnumMapping(string[] memory attrStrs, PunkAttributeValue[] memory attrEnums) external onlyOwner {
        for (uint i; i < attrStrs.length; i++) {
            string memory attrString = attrStrs[i];
            PunkAttributeValue attrEnum = attrEnums[i];
            
            attrStringToEnumMapping[attrString] = attrEnum;
            attrEnumToStringMapping[attrEnum] = attrString;
        }
    }
    
    mapping(PunkAttributeValue => mapping(PunkAttributeValue => mapping(HatType => bool))) public hatAvailableBySexAndHair;
    
    function canWearHat(Punk memory punk, HatType hat) public view returns (bool) {
        return hatAvailableBySexAndHair[punk.hair][punk.sex][hat];
    }
    
    function setAvailableHats(PunkAttributeValue[] memory hairs, PunkAttributeValue[] memory sexes, HatType[] memory hats) external onlyOwner {
        for (uint i; i < hairs.length; i++) {
            PunkAttributeValue hair = hairs[i];
            PunkAttributeValue sex = sexes[i];
            HatType hat = hats[i];
            
            hatAvailableBySexAndHair[hair][sex][hat] = true;
        }
    }
}