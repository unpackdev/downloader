// SPDX-License-Identifier: MIT

/// @title Places descriptor
/// @author Places DAO

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./base64.sol";
import "./IPlaces.sol";
import "./IPlacesDescriptor.sol";

contract PlacesDescriptor is IPlacesDescriptor, Ownable {
    /**
     * @notice Create contract metadata for Opensea.
     */
    function constructContractURI()
        external
        pure
        override
        returns (string memory)
    {
        return "";
    }

    /**
     * @notice Create the ERC721 token URI for a token.
     */
    function constructTokenURI(uint256 tokenId, IPlaces.Place memory place)
        external
        pure
        override
        returns (string memory)
    {
        string[30] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 520 520"><style>.text { font-family: monospace; font-size: 16px; fill: white; } .name { font-size: 18px; font-weight: 600; } .blue { fill: #2681FF; }.black { fill: black; }</style>';

        parts[
            1
        ] = '<defs><filter x="0" y="0" width="1" height="1" id="blue"><feFlood flood-color="#2681FF" /><feComposite in="SourceGraphic" operator="xor" /></filter></defs><rect width="100%" height="100%" fill="black"/>';

        parts[
            2
        ] = '<circle cx="260" cy="260" r="164" fill="#102440" stroke="#none"/><circle cx="260" cy="260" r="12" fill="black" stroke="#2681FF" stroke-width="4"/><rect x="252" y="220" width="16" height="16" transform="rotate(45 260 228)" fill="#2681FF"/>';

        parts[
            3
        ] = '<text x="50%" y="224" text-anchor="middle" filter="url(#blue)" class="text name">';

        parts[4] = place.name;
        parts[
            5
        ] = '</text><text x="50%" y="224" text-anchor="middle" class="text name black">';
        parts[6] = place.name;
        parts[
            7
        ] = '</text><text x="50%" y="223" text-anchor="middle" class="text name">';
        parts[8] = place.name;
        parts[9] = '</text><g class="text"><text x="24" y="34">';
        parts[10] = place.attributes[0];
        parts[11] = '</text><text x="24" y="58">';
        parts[12] = place.attributes[1];
        parts[13] = '</text><text x="24" y="82">';
        parts[14] = place.attributes[2];
        parts[15] = '</text></g><g class="text"><text x="24" y="398">';
        parts[16] = place.sublocality;
        parts[17] = '</text><text x="24" y="422"><tspan>';
        parts[18] = place.locality;
        parts[19] = "</tspan><tspan>, </tspan><tspan>";
        parts[20] = place.administrativeArea;
        parts[21] = '</tspan></text><text x="24" y="446">';
        parts[22] = place.streetAddress;
        parts[23] = '</text><text x="24" y="470">Elevation ';
        parts[24] = (place.location.hasAltitude)
            ? place.location.altitude
            : "???";
        if (place.location.hasAltitude) {
            parts[25] = 'm</text><text x="24" y="494" class="blue">';
        } else {
            parts[25] = '</text><text x="24" y="494" class="blue">';
        }
        parts[26] = place.location.latitude;
        parts[27] = ", ";
        parts[28] = place.location.longitude;
        parts[29] = "</text></g></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[25],
                parts[26],
                parts[27],
                parts[28],
                parts[29]
            )
        );

        string[14] memory traitParts;
        traitParts[0] = '"trait_type": "SUBLOCALITY", "value": "';
        traitParts[1] = place.sublocality;
        traitParts[2] = '"}, {"trait_type": "LOCALITY", "value": "';
        traitParts[3] = place.locality;
        traitParts[
            4
        ] = '"}, {"trait_type": "SUBADMINISTRATIVE AREA", "value": "';
        traitParts[5] = place.subadministrativeArea;
        traitParts[6] = '"}, {"trait_type": "ADMINISTRATIVE AREA", "value": "';
        traitParts[7] = place.administrativeArea;
        traitParts[8] = '"}, {"trait_type": "COUNTRY", "value": "';
        traitParts[9] = place.country;
        traitParts[10] = '"}, {"trait_type": "POSTAL CODE", "value": "';
        traitParts[11] = place.postalCode;
        traitParts[12] = '"}, {"trait_type": "ATTRIBUTE", "value": "';
        traitParts[13] = place.attributes[0];

        string memory traits = string(
            abi.encodePacked(
                traitParts[0],
                traitParts[1],
                traitParts[2],
                traitParts[3],
                traitParts[4],
                traitParts[5],
                traitParts[6],
                traitParts[7],
                traitParts[8]
            )
        );
        traits = string(
            abi.encodePacked(
                traits,
                traitParts[9],
                traitParts[10],
                traitParts[11],
                traitParts[12],
                traitParts[13]
            )
        );

        bool hasSecondTrait = bytes(place.attributes[1]).length > 0;
        bool hasThirdTrait = bytes(place.attributes[2]).length > 0;
        if (hasSecondTrait && hasThirdTrait) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[1],
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[2]
                )
            );
        } else if (hasSecondTrait) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[1]
                )
            );
        } else if (hasThirdTrait) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '"}, {"trait_type": "ATTRIBUTE", "value": "',
                    place.attributes[2]
                )
            );
        }

        traits = string(
            abi.encodePacked(
                traits,
                '"}, {"display_type": "number", "trait_type": "LATITUDE", "value": ',
                place.location.latitude,
                '}, {"display_type": "number", "trait_type": "LONGITUDE", "value": ',
                place.location.longitude
            )
        );

        if (place.location.hasAltitude) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '}, {"display_type": "number", "trait_type": "ALTITUDE", "value": ',
                    place.location.altitude
                )
            );
        }

        // props to Brecht Devos Base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        place.name,
                        unicode" – Place #",
                        toString(tokenId),
                        '", "description": "Places is an experiment to establish geographic locations as non-fungible tokens on the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": [{',
                        traits,
                        "}]}"
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /**
     * @notice [MIT License] via Loot, inspired by OraclizeAPI's implementation - MIT license
     * @dev https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
