// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ABDKMath64x64.sol";
import "./Base64.sol";
import "./Roots.sol";
import "./Strings.sol";

interface IFixedMetadata {
    function tokenMetadata(
        uint256 tokenId,
        uint256 rarity,
        uint256 tokenMass,
        uint256 alphaMass,
        bool isAlpha,
        uint256 mergeCount) external view returns (string memory);
}

contract FixedMetadata is IFixedMetadata {

    struct ERC721MetadataStructure {
        bool isImageLinked;
        string name;
        string description;
        string createdBy;
        string image;
        ERC721MetadataAttribute[] attributes;
    }

    struct ERC721MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }

    using ABDKMath64x64 for int128;
    using Base64 for string;
    using Roots for uint;
    using Strings for uint256;

    address public owner;

    string private _name;
    string private _imageBaseURI;
    string private _imageExtension;
    uint256 private _maxRadius;
    string[] private _imageParts;
    mapping (string => string) private _classStyles;
    mapping (string => string) private _spheres;
    mapping (string => string) private _sphereDefs;

    string constant private _RADIUS_TAG = '<RADIUS>';
    string constant private _SPHERE_TAG = '<SPHERE>';
    string constant private _SPHERE_DEFS_TAG = '<SPHERE_DEFS>';
    string constant private _CLASS_TAG = '<CLASS>';
    string constant private _CLASS_STYLE_TAG = '<CLASS_STYLE>';

    constructor() {
        owner = msg.sender;
        _name = "f";
        _imageBaseURI = ""; // Set to empty string - results in on-chain SVG generation by default unless this is set later
        _imageExtension = ""; // Set to empty string - can be changed later to remain empty, .png, .mp4, etc
        _maxRadius = 1000;

        // Deploy with default SVG image parts - can be completely replaced later
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='2000' height='2000'>");
        _imageParts.push("<style>");
        _imageParts.push(".m1 #c{fill: #fff;}");
        _imageParts.push(".m1 #r{fill: #000;}");
        _imageParts.push(".m2 #c{fill: #fc3;}");
        _imageParts.push(".m2 #r{fill: #000;}");
        _imageParts.push(".m3 #c{fill: #fff;}");
        _imageParts.push(".m3 #r{fill: #33f;}");
        _imageParts.push(".m4 #c{fill: #fff;}");
        _imageParts.push(".m4 #r{fill: #f33;}");
        _imageParts.push(".a #c{fill: #000 !important;}");
        _imageParts.push(".a #r{fill: #fff !important;}");
        _imageParts.push(".s{transform:scale(calc(");
        _imageParts.push(_RADIUS_TAG);
        _imageParts.push(" / 1000));transform-origin:center}");
        _imageParts.push(_CLASS_STYLE_TAG);
        _imageParts.push("</style>");
        _imageParts.push("<g class='");
        _imageParts.push(_CLASS_TAG);
        _imageParts.push("'>");
        _imageParts.push("<rect id='r' width='2000' height='2000'/>");
        _imageParts.push("<circle id='c' cx='1000' cy='1000' r='");
        _imageParts.push(_RADIUS_TAG);
        _imageParts.push("'/>");
        _imageParts.push("<g class='s'>");
        _imageParts.push("<svg width='2000' height='2000' viewBox='0 0 800 800' fill='none' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>");
        _imageParts.push(_SPHERE_TAG);
        _imageParts.push("<defs>");
        _imageParts.push(_SPHERE_DEFS_TAG);
        _imageParts.push("<image id='i0' width='96' height='96' xlink:href='data:image/png;base64,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'/>");
        _imageParts.push("</defs></svg></g></g>");
        _imageParts.push("<defs></defs>");
        _imageParts.push("</svg>");

        
        string memory defaultSphere = "<circle cx='400' cy='400' r='400' fill='url(#pt0)'/> <g> <mask id='m0' style='mask-type:alpha' maskUnits='userSpaceOnUse' x='0' y='0' width='800' height='800'> <circle cx='400' cy='400' r='400' fill='url(#pt1)'/> </mask> <g mask='url(#m0)'> <rect x='-695.895' y='-297.542' width='1819.48' height='1854.64' transform='rotate(-13.0766 -695.895 -297.542)' fill='url(#p0)'/> </g> </g> <g style='mix-blend-mode:screen'> <circle cx='400' cy='400' r='400' fill='url(#pt2)'/> </g> <g style='mix-blend-mode:screen'> <circle cx='400' cy='400' r='400' fill='url(#pt3)'/> </g>";
        string memory alphaSphere = "<circle cx='400' cy='400' r='400' fill='url(#pt0)'/> <g style='mix-blend-mode:screen'> <circle cx='400' cy='400' r='400' fill='url(#pt1)'/> </g> <g opacity='0.2'> <mask id='m0' style='mask-type:alpha' maskUnits='userSpaceOnUse' x='0' y='0' width='800' height='800'> <circle cx='400' cy='400' r='400' fill='url(#pt2)'/> </mask> <g mask='url(#m0)'> <rect x='-695.895' y='-297.543' width='1819.48' height='1854.64' transform='rotate(-13.0766 -695.895 -297.543)' fill='url(#pattern0)'/> </g> </g>";

        _spheres["a"] = alphaSphere;
        _spheres["1"] = defaultSphere;
        _spheres["2"] = defaultSphere;
        _spheres["3"] = defaultSphere;
        _spheres["4"] = defaultSphere;

        string memory defaultSphereDef = "<pattern id='p0' patternContentUnits='objectBoundingBox' width='0.0325926' height='0.0325926'> <use xlink:href='#i0' transform='scale(0.0004)'/> </pattern> <radialGradient id='pt0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#E1E1E1'/> <stop offset='1'/> </radialGradient> <radialGradient id='pt1' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1'/> </radialGradient> <radialGradient id='pt2' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='white'/> <stop offset='0.404291' stop-color='#A2A2A2'/> <stop offset='1'/> </radialGradient> <radialGradient id='pt3' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#F4F4F4'/> <stop offset='1'/> </radialGradient>";
        string memory alphaSphereDef = "<pattern id='p0' patternContentUnits='objectBoundingBox' width='0.0325926' height='0.0325926'> <use xlink:href='#i0' transform='scale(0.0004)'/> </pattern> <radialGradient id='pt0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='0.197917'/> </radialGradient> <radialGradient id='pt1' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop offset='0.203125' stop-color='#C4C4C4' stop-opacity='0.9'/> <stop offset='0.723958'/> </radialGradient> <radialGradient id='pt2' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1'/> </radialGradient>";
        string memory yellowSphereDef = "<pattern id='p0' patternContentUnits='objectBoundingBox' width='0.0325926' height='0.0325926'> <use xlink:href='#i0' transform='scale(0.0004)' opacity='0.25'/> </pattern> <radialGradient id='pt0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='0.197917' stop-color='#FFCC33'/> </radialGradient> <radialGradient id='pt1' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1' stop-color='#FFCC33'/> </radialGradient> <radialGradient id='pt2' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1'/> </radialGradient>";

        _sphereDefs["a"] = alphaSphereDef;
        _sphereDefs["1"] = defaultSphereDef;
        _sphereDefs["2"] = yellowSphereDef;
        _sphereDefs["3"] = defaultSphereDef;
        _sphereDefs["4"] = defaultSphereDef;

    }

    function setName(string calldata name_) external {
        _requireOnlyOwner();
        _name = name_;
    }

    function setImageBaseURI(string calldata imageBaseURI_, string calldata imageExtension_) external {
        _requireOnlyOwner();
        _imageBaseURI = imageBaseURI_;
        _imageExtension = imageExtension_;
    }

    function setMaxRadius(uint256 maxRadius_) external {
        _requireOnlyOwner();
        _maxRadius = maxRadius_;
    }

    function tokenMetadata(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) external view override returns (string memory) {
        string memory base64Json = Base64.encode(bytes(string(abi.encodePacked(_getJson(tokenId, rarity, tokenMass, alphaMass, isAlpha, mergeCount)))));
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    function updateImageParts(string[] memory imageParts_) public {
        _requireOnlyOwner();
        _imageParts = imageParts_;
    }

    function pushToImageParts(string[] memory imageParts_) public {
        _requireOnlyOwner();

        for (uint i = 0; i < imageParts_.length; i++) {
            _imageParts.push(imageParts_[i]);
        }
    }

    function updateClassStyle(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _classStyles[cssClass] = cssStyle;
    }

    function getClassStyle(string memory cssClass) public view returns (string memory) {
        return _classStyles[cssClass];
    }

    function updateSphere(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _spheres[cssClass] = cssStyle;
    }

    function getSphere(string memory cssClass) public view returns (string memory) {
        return _spheres[cssClass];
    }

    function updateSphereDef(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _sphereDefs[cssClass] = cssStyle;
    }

    function getSphereDef(string memory cssClass) public view returns (string memory) {
        return _sphereDefs[cssClass];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function imageBaseURI() public view returns (string memory) {
        return _imageBaseURI;
    }

    function imageExtension() public view returns (string memory) {
        return _imageExtension;
    }

    function maxRadius() public view returns (uint256) {
        return _maxRadius;
    }

    function getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) public pure returns (string memory) {
        return _getClassString(tokenId, rarity, isAlpha, offchainImage);
    }

    function _getJson(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) private view returns (string memory) {
        string memory imageData =
        bytes(_imageBaseURI).length == 0 ?
        _getSvg(tokenId, rarity, tokenMass, alphaMass, isAlpha) :
        string(abi.encodePacked(imageBaseURI(), _getClassString(tokenId, rarity, isAlpha, true), "_", uint256(int256(_getScaledRadius(tokenMass, alphaMass, _maxRadius).toInt())).toString(), imageExtension()));

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
        isImageLinked: bytes(_imageBaseURI).length > 0,
        name: string(abi.encodePacked(name(), "(", tokenMass.toString(), ") #", tokenId.toString())),
        description: tokenMass.toString(),
        createdBy: "Non",
        image: imageData,
        attributes: _getJsonAttributes(tokenId, rarity, tokenMass, mergeCount, isAlpha)
        });

        return _generateERC721Metadata(metadata);
    }

    function _getJsonAttributes(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 mergeCount, bool isAlpha) private pure returns (ERC721MetadataAttribute[] memory) {
        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        ERC721MetadataAttribute[] memory metadataAttributes = new ERC721MetadataAttribute[](5);
        metadataAttributes[0] = _getERC721MetadataAttribute(false, true, false, "", "Mass", tokenMass.toString());
        metadataAttributes[1] = _getERC721MetadataAttribute(false, true, false, "", "Alpha", isAlpha ? "1" : "0");
        metadataAttributes[2] = _getERC721MetadataAttribute(false, true, false, "", "Tier", rarity.toString());
        metadataAttributes[3] = _getERC721MetadataAttribute(false, true, false, "", "Class", class.toString());
        metadataAttributes[4] = _getERC721MetadataAttribute(false, true, false, "", "Merges", mergeCount.toString());
        return metadataAttributes;
    }

    function _getERC721MetadataAttribute(bool includeDisplayType, bool includeTraitType, bool isValueAString, string memory displayType, string memory traitType, string memory value) private pure returns (ERC721MetadataAttribute memory) {
        ERC721MetadataAttribute memory attribute = ERC721MetadataAttribute({
        includeDisplayType: includeDisplayType,
        includeTraitType: includeTraitType,
        isValueAString: isValueAString,
        displayType: displayType,
        traitType: traitType,
        value: value
        });

        return attribute;
    }

    function _getSvg(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha) private view returns (string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _RADIUS_TAG)) {
                byteString = abi.encodePacked(byteString, _floatToString(_getScaledRadius(tokenMass, alphaMass, _maxRadius)));
            } else if (_checkTag(_imageParts[i], _SPHERE_TAG)) {
                if (isAlpha) {
                    byteString = abi.encodePacked(byteString, _spheres['a']);
                } else {
                    byteString = abi.encodePacked(byteString, _spheres[rarity.toString()]);
                }
            } else if (_checkTag(_imageParts[i], _SPHERE_DEFS_TAG)) {
                if (isAlpha) {
                    byteString = abi.encodePacked(byteString, _sphereDefs['a']);
                } else {
                    byteString = abi.encodePacked(byteString, _sphereDefs[rarity.toString()]);
                }
            } else if (_checkTag(_imageParts[i], _CLASS_TAG)) {
                byteString = abi.encodePacked(byteString, _getClassString(tokenId, rarity, isAlpha, false));
            } else if (_checkTag(_imageParts[i], _CLASS_STYLE_TAG)) {
                uint256 tensDigit = tokenId % 100 / 10;
                uint256 onesDigit = tokenId % 10;
                uint256 class = tensDigit * 10 + onesDigit;
                string memory classCss = getClassStyle(_getTokenIdClass(class));
                if(bytes(classCss).length > 0) {
                    byteString = abi.encodePacked(byteString, classCss);
                }
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _getScaledRadius(uint256 tokenMass, uint256 alphaMass, uint256 maximumRadius) private pure returns (int128) {
        int128 radiusMass = _getRadius64x64(tokenMass);
        int128 radiusAlphaMass = _getRadius64x64(alphaMass);
        int128 scalePercentage = ABDKMath64x64.div(radiusMass, radiusAlphaMass);
        int128 scaledRadius = ABDKMath64x64.mul(ABDKMath64x64.fromUInt(maximumRadius), scalePercentage);
        if(uint256(int256(scaledRadius.toInt())) == 0) {
            scaledRadius = ABDKMath64x64.fromUInt(1);
        }
        return scaledRadius;
    }

    // Radius = Cube Root(Mass) * Cube Root (0.23873241463)
    // Radius = Cube Root(Mass) * 0.62035049089
    function _getRadius64x64(uint256 mass) private pure returns (int128) {
        int128 cubeRootScalar = ABDKMath64x64.divu(62035049089, 100000000000);
        int128 cubeRootMass = ABDKMath64x64.divu(mass.nthRoot(3, 6, 32), 1000000);
        int128 radius = ABDKMath64x64.mul(cubeRootMass, cubeRootScalar);
        return radius;
    }

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("description", metadata.description, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));

        if(metadata.isImageLinked) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image_data", metadata.image, true));
        }

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute("attributes", _getAttributes(metadata.attributes), false));

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(ERC721MetadataAttribute[] memory attributes) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonArray());

        for (uint i = 0; i < attributes.length; i++) {
            ERC721MetadataAttribute memory attribute = attributes[i];

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(_getAttribute(attribute), i < (attributes.length - 1)));
        }

        byteString = abi.encodePacked(
            byteString,
            _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(ERC721MetadataAttribute memory attribute) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        if(attribute.includeDisplayType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("display_type", attribute.displayType, true));
        }

        if(attribute.includeTraitType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("trait_type", attribute.traitType, true));
        }

        if(attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("value", attribute.value, false));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute("value", attribute.value, false));
        }

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());

        return string(byteString);
    }

    function _getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _getRarityClass(rarity));

        if(isAlpha) {
            byteString = abi.encodePacked(
                byteString,
                string(abi.encodePacked(offchainImage ? "_" : " ", "a")));
        }

        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        byteString = abi.encodePacked(
            byteString,
            string(abi.encodePacked(offchainImage ? "_" : " ", _getTokenIdClass(class))));

        return string(byteString);
    }

    function _getRarityClass(uint256 rarity) private pure returns (string memory) {
        return string(abi.encodePacked("m", rarity.toString()));
    }

    function _getTokenIdClass(uint256 class) private pure returns (string memory) {
        return string(abi.encodePacked("c", class.toString()));
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(uint256(int256(value.toInt())).toString(), '.', _decimal4ToString(decimal4)));
    }

    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }

    function _openJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonPrimitiveNonStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonComplexAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }
}