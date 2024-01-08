//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./base64.sol";
import "./Strings.sol";

interface MapInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getWaypointCount(uint256 tokenId) external view returns (uint256);

    function getWaypointCoord(uint256 tokenId, uint256 waypointIndex)
        external
        view
        returns (uint256[2] memory);

    function getWaypointName(uint256 tokenId, uint256 waypointIndex)
        external
        view
        returns (string memory);
}

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getChest(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);

    function getHand(uint256 tokenId) external view returns (string memory);

    function getHead(uint256 tokenId) external view returns (string memory);

    function getNeck(uint256 tokenId) external view returns (string memory);

    function getRing(uint256 tokenId) external view returns (string memory);

    function getWaist(uint256 tokenId) external view returns (string memory);

    function getWeapon(uint256 tokenId) external view returns (string memory);
}

contract LootMap is ERC721Enumerable, ReentrancyGuard, Ownable {
    MapInterface immutable mapContract;
    LootInterface immutable lootContract;
    uint256[2] private mapTokenIdsAllocation = [1, 10_000];
    uint256[2] private lootTokenIdsAllocation = [10_001, 18_000];

    constructor(MapInterface mapAddress, LootInterface lootAddress)
        ERC721("Loot Map", "LMAP")
    {
        mapContract = mapAddress;
        lootContract = lootAddress;
    }

    /// @notice Pseudo random number generator based on input
    /// @dev Not really random
    /// @param input The seed value
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /// @notice Gets a random value from a min and max range
    /// @dev a 2 value array the left is min and right is max
    /// @param tokenId a parameter just like in doxygen (must be followed by parameter name)
    /// @param rangeTuple a tuple with left value as min number and right as max
    function randomFromRange(uint256 tokenId, uint256[2] memory rangeTuple)
        internal
        pure
        returns (uint256)
    {
        uint256 rand = _random(
            string(abi.encodePacked(Strings.toString(tokenId)))
        );

        return (rand % (rangeTuple[1] - rangeTuple[0])) + rangeTuple[0];
    }

    function getRandomLootItem(uint256 lootTokenId, uint256 index)
        internal
        view
        returns (string memory)
    {
        try lootContract.ownerOf(lootTokenId) {
            if (index == 0) {
                return lootContract.getChest(lootTokenId);
            } else if (index == 1) {
                return lootContract.getFoot(lootTokenId);
            } else if (index == 2) {
                return lootContract.getHand(lootTokenId);
            } else if (index == 3) {
                return lootContract.getHead(lootTokenId);
            } else if (index == 4) {
                return lootContract.getNeck(lootTokenId);
            } else if (index == 5) {
                return lootContract.getRing(lootTokenId);
            } else if (index == 6) {
                return lootContract.getWaist(lootTokenId);
            }
            return lootContract.getWeapon(lootTokenId);
        } catch {
            return "??????????";
        }
    }

    function getMapTokenId(uint256 tokenId)
        public
        view
        returns (uint256 mapTokenId)
    {
        require(_exists(tokenId), "Token ID is invalid");

        if (
            tokenId >= mapTokenIdsAllocation[0] &&
            tokenId <= mapTokenIdsAllocation[1]
        ) {
            return tokenId;
        }
        uint256 chosenMapTokenId = randomFromRange(
            tokenId,
            mapTokenIdsAllocation
        );
        return chosenMapTokenId;
    }

    function getLootTokenId(uint256 tokenId)
        public
        view
        returns (uint256 lootTokenId)
    {
        require(_exists(tokenId), "Token ID is invalid");

        if (
            tokenId >= lootTokenIdsAllocation[0] &&
            tokenId <= lootTokenIdsAllocation[1]
        ) {
            return tokenId - 10_000;
        }
        uint256 chosenLootTokenId = randomFromRange(
            tokenId,
            [uint256(1), uint256(8_000)]
        );
        return chosenLootTokenId;
    }

    function getWaypointCoord(uint256 tokenId)
        public
        view
        returns (uint256[2] memory coords)
    {
        require(_exists(tokenId), "Token ID is invalid");
        uint256 chosenMapTokenId = getMapTokenId(tokenId);

        uint256[2] memory chosenWaypointCoord;
        try mapContract.getWaypointCount(chosenMapTokenId) returns (
            uint256 resultWaypointsCount
        ) {
            uint256 chosenWaypointIndex = randomFromRange(
                chosenMapTokenId,
                [1, resultWaypointsCount - 1]
            );
            chosenWaypointCoord = mapContract.getWaypointCoord(
                chosenMapTokenId,
                chosenWaypointIndex
            );
        } catch {
            chosenWaypointCoord = [uint256(129), uint256(129)];
        }

        return chosenWaypointCoord;
    }

    function getWaypointName(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "Token ID is invalid");
        uint256 chosenMapTokenId = getMapTokenId(tokenId);

        string memory chosenWaypointName;
        try mapContract.getWaypointCount(chosenMapTokenId) returns (
            uint256 resultWaypointsCount
        ) {
            uint256 chosenWaypointIndex = randomFromRange(
                chosenMapTokenId,
                [1, resultWaypointsCount - 1]
            );
            chosenWaypointName = mapContract.getWaypointName(
                chosenMapTokenId,
                chosenWaypointIndex
            );
        } catch {
            chosenWaypointName = "??????????";
        }

        return chosenWaypointName;
    }

    function getLootItem(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token ID is invalid");
        uint256 chosenLootTokenId = getLootTokenId(tokenId);

        uint256 chosenLootItemIndex = randomFromRange(
            chosenLootTokenId,
            [uint256(0), uint256(7)]
        );

        return getRandomLootItem(chosenLootTokenId, chosenLootItemIndex);
    }

    function claimLootMapsAsMapHolder(uint256[] memory mapTokenIds)
        public
        nonReentrant
    {
        for (uint256 index = 0; index < mapTokenIds.length; index++) {
            uint256 mapTokenId = mapTokenIds[index];
            require(
                mapContract.ownerOf(mapTokenId) == _msgSender(),
                "Sender does not own 1 or more Map Token Ids provided"
            );

            _safeMint(_msgSender(), mapTokenId);
        }
    }

    function claimLootMapsAsLootHolder(uint256[] memory lootTokenIds)
        public
        nonReentrant
    {
        for (uint256 index = 0; index < lootTokenIds.length; index++) {
            uint256 lootTokenId = lootTokenIds[index];
            require(
                lootContract.ownerOf(lootTokenId) == _msgSender(),
                "Sender does not own 1 or more Loot Token Ids provided"
            );

            _safeMint(_msgSender(), lootTokenId + 10_000);
        }
    }

    /// @notice Constructs the tokenURI, separated out from the public function as its a big function.
    /// @dev Generates the json data URI and svg data URI that ends up sent when someone requests the tokenURI
    /// @param tokenId the tokenId
    function _constructTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory mapName = string(
            abi.encodePacked("Loot Map #", Strings.toString(tokenId))
        );

        string memory name = getWaypointName(tokenId);
        string memory waypointNameSVG = string(
            abi.encodePacked(
                '<text dominant-baseline="middle" text-anchor="middle" fill="white" x="50%" y="150px">',
                name,
                "</text>"
            )
        );

        string memory lootItem = getLootItem(tokenId);
        string memory lootItemSVG = string(
            abi.encodePacked(
                '<text dominant-baseline="middle" text-anchor="middle" fill="white" x="50%" y="110px">',
                lootItem,
                "</text>"
            )
        );

        uint256[2] memory waypointCoord = getWaypointCoord(tokenId);
        string memory waypointCoordSVG;
        if (waypointCoord[0] == 129) {
            waypointCoordSVG = string(abi.encodePacked(""));
        } else {
            waypointCoordSVG = string(
                abi.encodePacked(
                    '<circle fill="white" cx="',
                    Strings.toString(waypointCoord[0]),
                    '" cy="',
                    Strings.toString(waypointCoord[1]),
                    '" r="4"/>'
                )
            );
        }

        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet" style="font:16px serif"><rect width="400" height="400" fill="black" />',
            lootItemSVG,
            '<text dominant-baseline="middle" text-anchor="middle" fill="white" x="50%" y="130px">discovered at</text>',
            waypointNameSVG,
            '<g transform="translate(133, 260)">',
            '<rect transform="translate(-3, -3)" width="134" height="134" fill="none" stroke="white" stroke-width="2"/>',
            '<line x1="0" x2="50" y1="0" y2="50" />',
            '<line x1="50" y2="50" />',
            waypointCoordSVG,
            "</g>",
            "</svg>"
        );

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                mapName,
                                '", "image":"',
                                image,
                                '", "description": "Loot Maps are randomly generated locations taken from the Map Project combined with randomly selected Loot items from the Loot Project, use them however you wish."}'
                            )
                        )
                    )
                )
            );
    }

    /// @notice Returns the json data associated with this token ID
    /// @param tokenId the token ID
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(_constructTokenURI(tokenId));
    }
}
