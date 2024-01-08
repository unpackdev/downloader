//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./base64.sol";

contract Bliomes is ERC721Enumerable, ReentrancyGuard, Ownable {
    ERC721 public constant LOOT =
        ERC721(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613);

    string[] private atmosphere = [
        "Stimulating",
        "Electrifying",
        "Stormy",
        "Sexy",
        "Horny",
        "Wet",
        "Hot",
        "Raunchy",
        "Vibrating",
        "Kinky",
        "Dripping",
        "Gushing",
        "Pulsating"
    ];
    uint16[] private atmosphereRarities = [
        15,
        15,
        15,
        15,
        15,
        25,
        25,
        12,
        10,
        7,
        4,
        2,
        1
    ];
    uint256 private atmosphereTotal = 0;

    string[] private terrain = [
        "Rocky",
        "Snowy",
        "Swampy",
        "Sandy",
        "Grassy",
        "Urban",
        "Mossy",
        "Concrete",
        "Classy",
        "Hard",
        "Dirty"
    ];
    uint16[] private terrainRarities = [13, 13, 13, 13, 13, 8, 8, 8, 6, 4, 1];
    uint256 private terrainTotal = 0;

    string[] private landmark = [
        "Streets",
        "Motel",
        "Brothel",
        "Hotel",
        "Yacht"
    ];
    uint16[] private landmarkRarities = [40, 20, 10, 10, 2];
    uint256 private landmarkTotal = 0;

    string[] private bliomes = [
        "Desert",
        "Forest",
        "Jungle",
        "City",
        "Ruins",
        "Metropolis",
        "Plains",
        "Mountains",
        "Sea",
        "Tundra"
    ];
    uint16[] private bliomeRarities = [10, 12, 10, 15, 10, 15, 15, 10, 5, 10];
    uint256 private bliomeTotal = 0;

    string[] private planet = [
        "Mars",
        "Venus",
        "Earth",
        "Mercury",
        "Jupiter",
        "Saturn",
        "Uranus",
        "Neptune",
        "Pluto",
        "Sedna"
    ];
    uint16[] private planetRarities = [10, 10, 25, 15, 10, 10, 5, 10, 5, 1];
    uint256 private planetTotal = 0;

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getCoordinates(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        uint256 rand = random(
            string(abi.encodePacked("Coordinates", toString(tokenId)))
        );
        string memory x = string(
            abi.encodePacked(
                toString(rand % 1000),
                ".",
                toString((rand / 1000) % 1000)
            )
        );
        rand = rand / 1000000;
        string memory y = string(
            abi.encodePacked(
                toString(rand % 1000),
                ".",
                toString((rand / 1000) % 1000)
            )
        );

        return string(abi.encodePacked("Coordinates: (", x, ", ", y, ")"));
    }

    function getAtmosphere(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            pluck(
                tokenId,
                "Atmosphere",
                atmosphere,
                atmosphereRarities,
                atmosphereTotal
            );
    }

    function getTerrain(uint256 tokenId) public view returns (string memory) {
        return
            pluck(tokenId, "Terrain", terrain, terrainRarities, terrainTotal);
    }

    function getLandmark(uint256 tokenId) public view returns (string memory) {
        return
            pluck(
                tokenId,
                "Landmark",
                landmark,
                landmarkRarities,
                landmarkTotal
            );
    }

    function getBliome(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Bliome", bliomes, bliomeRarities, bliomeTotal);
    }

    function getPlanet(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Planet", planet, planetRarities, planetTotal);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray,
        uint16[] memory probabilityArray,
        uint256 total
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        uint256 prob = (rand % total) + 1;
        return
            string(
                abi.encodePacked(
                    keyPrefix,
                    ": ",
                    selector(sourceArray, probabilityArray, prob)
                )
            );
    }

    function selector(
        string[] memory sourceArray,
        uint16[] memory probabilityArray,
        uint256 probability
    ) internal pure returns (string memory) {
        uint256 curr = 0;
        for (uint256 i = 0; i < probabilityArray.length; i++) {
            curr += probabilityArray[i];
            if (curr >= probability) {
                return sourceArray[i];
            }
        }
        revert("No item found!");
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[14] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#01ff01" /><text x="10" y="20" class="base">';

        parts[1] = getBliome(tokenId);
        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getTerrain(tokenId);
        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getAtmosphere(tokenId);
        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getLandmark(tokenId);
        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getPlanet(tokenId);
        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getCoordinates(tokenId);
        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = "</text></svg>";

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
                parts[13]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bliomes #',
                        toString(tokenId),
                        '", "description": "Bliomes are detailed instructions of where to locate your bloot.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId >= 8009 && tokenId < 9576, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function claimForLoot(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8009, "Token ID invalid");
        require(LOOT.ownerOf(tokenId) == msg.sender, "Not Loot owner");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId >= 9576 && tokenId < 9644, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    constructor() ERC721("Bliomes", "BIOME") Ownable() {
        for (uint256 i = 0; i < atmosphereRarities.length; i++) {
            atmosphereTotal += uint256(atmosphereRarities[i]);
        }
        for (uint256 i = 0; i < terrainRarities.length; i++) {
            terrainTotal += uint256(terrainRarities[i]);
        }
        for (uint256 i = 0; i < landmarkRarities.length; i++) {
            landmarkTotal += uint256(landmarkRarities[i]);
        }
        for (uint256 i = 0; i < bliomeRarities.length; i++) {
            bliomeTotal += uint256(bliomeRarities[i]);
        }
        for (uint256 i = 0; i < planetRarities.length; i++) {
            planetTotal += uint256(planetRarities[i]);
        }
    }
}
