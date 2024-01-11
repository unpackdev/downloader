// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./base64.sol";
import "./IOneWar.sol";
import "./Strings.sol";

library NFTDescriptor {
    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    struct ExtraAttributes {
        uint256 redeemableGold;
        bool hasWarCountdownBegun;
        uint256 blocksUntilSanctuaryEnds;
    }

    struct TokenURIParams {
        string name;
        string description;
        IOneWar.Settlement attributes;
        ExtraAttributes extraAttributes;
    }

    enum AttributeType {
        PROPERTY,
        RANKING,
        STAT
    }

    struct Attribute {
        AttributeType attributeType;
        string svgHeading;
        string attributeHeading;
        string value;
        bool onSVG;
    }

    function constructTokenURI(TokenURIParams memory _params) internal pure returns (string memory) {
        Attribute[] memory formattedAttributes = formatAttributes(_params.attributes, _params.extraAttributes);
        string memory motto = _params.attributes.motto;
        string memory image = generateSVGImage(formattedAttributes, motto);
        string memory attributes = generateAttributes(formattedAttributes, motto);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _params.name,
                                '","description":"',
                                _params.description,
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '","attributes":',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function formatGold(uint256 _gold) internal pure returns (string memory) {
        string memory integer = string(abi.encodePacked(Strings.toString(_gold / GOLD_DENOMINATION)));
        string memory decimal;
        for (uint8 i = 0; i < GOLD_DECIMALS; i++) {
            uint256 digit = (_gold / 10**i) % 10;
            if (digit != 0 || bytes(decimal).length != 0) {
                decimal = string(abi.encodePacked(Strings.toString(digit), decimal));
            }
        }

        if (bytes(decimal).length != 0) {
            return string(abi.encodePacked(integer, ".", decimal));
        }

        return integer;
    }

    function formatAttributes(IOneWar.Settlement memory _attributes, ExtraAttributes memory _extraAttributes)
        internal
        pure
        returns (Attribute[] memory)
    {
        Attribute[] memory attributes = new Attribute[](_extraAttributes.hasWarCountdownBegun ? 12 : 11);
        attributes[0] = Attribute(
            AttributeType.STAT,
            "Soldiers",
            "Soldiers",
            Strings.toString(_attributes.soldiers),
            true
        );
        attributes[1] = Attribute(AttributeType.STAT, "Towers", "Towers", Strings.toString(_attributes.towers), true);
        attributes[2] = Attribute(
            AttributeType.STAT,
            "Catapults",
            "Catapults",
            Strings.toString(_attributes.catapults),
            true
        );
        attributes[3] = Attribute(
            AttributeType.STAT,
            "Treasure",
            "$GOLD Treasure",
            formatGold(_attributes.treasure),
            true
        );
        attributes[4] = Attribute(
            AttributeType.STAT,
            "Miners",
            "$GOLD Miners",
            Strings.toString(_attributes.miners),
            true
        );
        attributes[5] = Attribute(
            AttributeType.STAT,
            "Redeemed",
            "$GOLD Redeemed",
            formatGold(_attributes.goldRedeemed),
            false
        );
        attributes[6] = Attribute(
            AttributeType.STAT,
            "Redeemable",
            "$GOLD Redeemable",
            formatGold(_extraAttributes.redeemableGold),
            true
        );
        attributes[7] = Attribute(
            AttributeType.PROPERTY,
            "Genesis",
            "Genesis Block",
            Strings.toString(_attributes.genesis),
            true
        );
        attributes[8] = Attribute(
            AttributeType.PROPERTY,
            "Founder",
            "Founder",
            Strings.toString(_attributes.founder),
            true
        );
        attributes[9] = Attribute(AttributeType.RANKING, "Glory", "Glory", Strings.toString(_attributes.glory), true);
        attributes[10] = Attribute(
            AttributeType.STAT,
            "Sanctuary",
            "Sanctuary Duration",
            Strings.toString(_attributes.sanctuary),
            false
        );

        if (_extraAttributes.hasWarCountdownBegun) {
            attributes[11] = Attribute(
                AttributeType.STAT,
                "Sanctuary Remaining",
                "Blocks Until Sanctuary Ends",
                Strings.toString(_extraAttributes.blocksUntilSanctuaryEnds),
                false
            );
        }

        return attributes;
    }

    function generateSVGImage(Attribute[] memory _attributes, string memory _motto)
        internal
        pure
        returns (string memory)
    {
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" '
        'preserveAspectRatio="xMinYMin meet" '
        'viewBox="0 0 300 300">'
        "<style>"
        'text { fill: #646464; font-family: "Courier New", monospace; font-size: 12px; } '
        ".motto { font-size: 8px; text-anchor: middle; font-style: italic; font-weight: bold; } "
        ".right { text-transform: uppercase; } "
        ".left > text { text-anchor: end; }"
        "</style>"
        "<rect "
        'width="100%" '
        'height="100%" '
        'fill="#eee"'
        "/>";

        if (bytes(_motto).length > 0) {
            svg = string(abi.encodePacked(svg, '<text x="150" y="22" class="motto">', _motto, "</text>"));
        }

        string memory headings = '<g class="right" transform="translate(170,55)">';
        string memory values = '<g class="left" transform="translate(130,55)">';

        uint16 _y = 0;
        for (uint8 i = 0; i < _attributes.length; i++) {
            Attribute memory attribute = _attributes[i];
            if (!attribute.onSVG) {
                continue;
            }

            string memory textOpen = string(abi.encodePacked('<text y="', Strings.toString(_y), '">'));

            headings = string(abi.encodePacked(headings, textOpen, attribute.svgHeading, "</text>"));

            string memory value = Strings.equal(attribute.svgHeading, "Founder")
                ? Strings.truncateAddressString(attribute.value)
                : attribute.value;

            values = string(abi.encodePacked(values, textOpen, value, "</text>"));

            _y += 25;
        }

        headings = string(abi.encodePacked(headings, "</g>"));
        values = string(abi.encodePacked(values, "</g>"));

        svg = string(
            abi.encodePacked(
                svg,
                "<path "
                'stroke="#696969" '
                'stroke-width="1.337" '
                'stroke-dasharray="10,15" '
                'stroke-linecap="round" '
                'd="M150 46 L150 256"'
                "/>",
                headings,
                values,
                "</svg>"
            )
        );

        return Base64.encode(bytes(svg));
    }

    /**
     * @notice Parse Settlement attributes into a string.
     */
    function generateAttributes(Attribute[] memory _attributes, string memory _motto)
        internal
        pure
        returns (string memory)
    {
        string memory attributes = "[";
        for (uint8 i = 0; i < _attributes.length; i++) {
            Attribute memory attribute = _attributes[i];
            attributes = string(
                abi.encodePacked(
                    attributes,
                    "{",
                    AttributeType.STAT == attribute.attributeType ? '"display_type":"number",' : "",
                    '"trait_type":"',
                    attribute.attributeHeading,
                    '","value":',
                    AttributeType.STAT == attribute.attributeType || AttributeType.RANKING == attribute.attributeType
                        ? attribute.value
                        : string(abi.encodePacked('"', attribute.value, '"')),
                    "},"
                )
            );
        }

        attributes = string(abi.encodePacked(attributes, '{"trait_type":"Motto","value":"', _motto, '"}]'));

        return attributes;
    }
}
