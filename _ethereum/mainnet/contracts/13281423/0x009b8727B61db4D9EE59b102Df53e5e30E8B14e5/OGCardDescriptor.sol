// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Strings.sol";
import "./IOGCards.sol";
import "./ILayerDescriptor.sol";

import "./base64.sol";

contract OGCardDescriptor is Ownable {
    using Strings for uint256;
    using Strings for uint8;

    string public ogCardUrl = '';
    string public ogCardDescription = 'OGCards are NFTs which evolve after each different holder';
    address public immutable frontLayerDescriptor;
    address public backLayerDescriptor;

    constructor(address _frontLayerDescriptor, address _backLayerDescriptor)
    {
        frontLayerDescriptor = _frontLayerDescriptor;
        backLayerDescriptor = _backLayerDescriptor;
    }

    function setOGCardUrl(string memory _ogCardUrl)
        external
        onlyOwner
    {
        ogCardUrl = _ogCardUrl;
    }

    function setOGCardDescription(string memory _ogCardDescription)
        external
        onlyOwner
    {
        ogCardDescription = _ogCardDescription;
    }

    function setBackLayerDescriptor(address _backLayerDescriptor)
        external
        onlyOwner
    {
        backLayerDescriptor = _backLayerDescriptor;
    }

    function tokenURI(address ogCards, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            metadata(ogCards, tokenId)
                        )
                    )
            )
        );
    }

    function metadata(address ogCards, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IOGCards.Card memory card = IOGCards(ogCards).cardDetails(tokenId);
        (, string[] memory names) = IOGCards(ogCards).ogHolders(tokenId);
        string memory attributes = cardAttributes(card.borderType, card.transparencyLevel, card.maskType, card.dna, card.mintTokenId, card.isGiveaway, names);

        string memory externalUrl = '';
        if (bytes(ogCardUrl).length > 0) {
            externalUrl = string(abi.encodePacked(
                '"external_url": "',
                ogCardUrl,
                tokenId.toString(),
                '",'
            ));
        }

        return string(abi.encodePacked(
			'{',
				'"name": "OGCard #', tokenId.toString(), '",', 
				'"description": "',ogCardDescription,'",',
                '"image": "',
                    'data:image/svg+xml;base64,', Base64.encode(bytes(svgImage(ogCards, tokenId, card))), '",',
                    externalUrl,
				'"attributes": [', attributes, ']',
			'}'
		));
    }

    function cardAttributes(uint8 borderType, uint8 transparencyLevel, uint8 maskType, uint256 dna, uint256 mintTokenId, bool isGiveaway, string[] memory names)
        public
        pure
        returns (string memory)
    {
        string memory attributes = string(abi.encodePacked(
            borderColorTrait(borderType),
            ',',
            transparencyTrait(transparencyLevel),
            ',',
            maskTrait(maskType),
            ',',
            dnaTrait(dna),
            ',',
            ogsTraits(names),
            ',',
            mintTokenIdTrait(mintTokenId, maskType, isGiveaway),
            ',',
            giveawayTrait(isGiveaway)
        ));

        return attributes;
    }

    // Traits
    function traitDefinition(string memory name, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', name ,'",',
                '"value": "', value ,'"',
            '}'
        ));
    }

    function borderColorTrait(uint8 borderType)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('Border Color', borderColorString(borderType));
    }

    function transparencyTrait(uint8 transparencyLevel)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('Transparency Level', transparencyLevelString(transparencyLevel));
    }

    function maskTrait(uint8 maskType)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('Mask', maskTypeString(maskType));
    }

    function dnaTrait(uint256 dna)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('DNA', dna.toString());
    }

    function giveawayTrait(bool isGiveaway)
        public
        pure
        returns (string memory)
    {
        string memory value = isGiveaway ? 'true' : 'false';
        return traitDefinition('Giveaway', value);
    }

    function mintTokenIdTrait(uint256 mintTokenId, uint8 maskType, bool isGiveaway)
        public
        pure
        returns (string memory)
    {
        string memory value = !isGiveaway && maskType > 0 ? mintTokenId.toString() : 'None';
        return traitDefinition('MintTokenId', value);
    }

    function ogsTraits(string[] memory names)
        public
        pure
        returns (string memory)
    {
        string memory traitsDefinitions = string(abi.encodePacked(
            '{',
                '"trait_type": "OGs",',
                '"value": ', names.length.toString(),
            '}'
        ));

        if (names.length > 0) {
            for (uint256 i = 0; i < names.length; i++) {
                string memory name = names[i];
                traitsDefinitions = string(abi.encodePacked(
                    traitsDefinitions,
                    ',',
                    traitDefinition('OG', name)
                ));
            }
        }

        return traitsDefinitions;
    }

    // Attributes to String
    function borderColorString(uint8 borderType)
        public
        pure
        returns (string memory)
    {
        return (borderType == 0 ? "#00ccff": // Light blue
                    (borderType == 1 ? "#ffffff" : // White
                        (borderType == 2 ? "#1eff00" : // Green
                            (borderType == 3 ? "#0070dd" : // Blue
                                (borderType == 4 ? "#a335ee" : "#daa520"))))); // Purple and Gold
    }

    function maskTypeString(uint8 maskType)
        public
        pure
        returns (string memory)
    {
        return (maskType == 0 ? "Ethereum" :
                    (maskType == 1 ? "CryptoPunk" :
                        (maskType == 2 ? "Animal Coloring Book" :
                            (maskType == 3 ? "Purrnelope's Country Club" : ""))));
    }

    function transparencyLevelString(uint8 transparencyLevel)
        public
        pure
        returns (string memory)
    {
        return transparencyLevel.toString();
    }

    function svgImage(address ogCards, uint256 tokenId, IOGCards.Card memory card)
        public
        view
        returns (string memory)
    {
        string memory font = "Avenir, Helvetica, Arial, sans-serif";
        string memory borderColor = borderColorString(card.borderType);

        return string(abi.encodePacked(
            '<svg id="ogcard-',tokenId.toString(),'" data-name="OGCard" xmlns="http://www.w3.org/2000/svg" width="300" height="300" class="ogcard-svg">',
                svgDefsAndStyles(tokenId, card.maskType, font, borderColor),
                '<g clip-path="url(#corners)">',
                    svgLayers(ogCards, tokenId, font, borderColor, card),
                    '<rect width="100%" height="100%" rx="30" ry="30" stroke="',borderColor,'" stroke-width="2" fill="rgba(0,0,0,0)"></rect>',
                '</g>',
                '</svg>'
		));
    }

    function svgLayers(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(
            ILayerDescriptor(backLayerDescriptor).svgLayer(ogCards, tokenId, font, borderColor, card),
            ILayerDescriptor(frontLayerDescriptor).svgLayer(ogCards, tokenId, font, borderColor, card)
        ));
    }

    function svgDefsAndStyles(uint256 tokenId, uint8 maskType, string memory font, string memory borderColor)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(
            '<defs>',
                '<rect id="rect-corners" width="100%" height="100%" rx="30" ry="30" />',
                ILayerDescriptor(frontLayerDescriptor).svgMask(maskType, borderColor, true, false),
                '<text id="token-id" x="205" y="270" font-family="',font,'" font-weight="bold" font-size="30px" fill="#000000">',
                '#',uint2strMask(tokenId),
                '</text>',
                '<path id="text-path-border" d="M35 15 H265 a20 20 0 0 1 20 20 V265 a20 20 0 0 1 -20 20 H35 a20 20 0 0 1 -20 -20 V35 a20 20 0 0 1 20 -20 z"></path>',
                '<clipPath id="corners"><use href="#rect-corners" /></clipPath>',
                '<mask id="mask">',
                    '<rect width="100%" height="100%" fill="#ffffff"></rect>',
                    '<g class="mask-path">',
                        ILayerDescriptor(frontLayerDescriptor).svgMask(maskType, borderColor, true, true),
                    '</g>',
                    '<use href="#token-id" />',
                '</mask>',
            '</defs>',
            '<style>',
                '.mask-path {animation: 2s mask-path infinite alternate linear;} @keyframes mask-path {0%, 100% {transform: translateY(-3%)}50% {transform: translateY(3%)}}',
            '</style>'
        ));
    }

    function uint2strMask(uint _i) internal pure returns (string memory _uintAsString) {
        uint maskSize = 3;
        if (_i == 0) {
            return "000";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(maskSize);
        uint k = maskSize;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        while (k != 0) {
            k = k-1;
            uint8 temp = 48;
            bstr[k] = bytes1(temp);
        }
        return string(bstr);
    }
}