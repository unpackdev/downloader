// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Mount is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes private _temperamentsProbTable;
    bytes private _temperamentsAliasTable;
    string[] private _temperaments;

    bytes private _mountsProbTable;
    bytes private _mountsAliasTable;
    string[] private _mounts;

    uint64 public constant offerExpires = 1633039199; // Thu Sep 30 2021 21:59:59 GMT+0000
    address public constant lootAddress =
        0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    address public constant xLootAddress =
        0x8bf2f876E2dCD2CAe9C3d272f325776c82DA366d;
    LootInterface public constant lootContract = LootInterface(lootAddress);
    LootInterface public constant xLootContract = LootInterface(xLootAddress);

    address constant t1 = 0x05343aDE6Fc7d42d33Cf75fFd3fd9F671Ef012b0;
    address constant t2 = 0x2d6E54419b781fa3Ce9eC7396B0b91eafB59fcC1;
    address constant t3 = 0x2817500b31f80fb78f43DF7E699d58511094b146;
    address constant t4 = 0x762EcB27cfEf08542fA69b898E9117047045437A;

    uint256 private _price = 0.03 ether;
    uint256 private _priceWithXLoot = 0.02 ether;
    uint256 private _priceWithLoot = 0.01 ether;

    constructor(
        string[] memory mounts,
        bytes memory mountsAliasTable,
        bytes memory mountsProbTable,
        string[] memory temperaments,
        bytes memory temperamentsAliasTable,
        bytes memory temperamentsProbTable
    ) ERC721("Mount", "MNT") {
        _mounts = mounts;
        _mountsAliasTable = mountsAliasTable;
        _mountsProbTable = mountsProbTable;
        _temperaments = temperaments;
        _temperamentsAliasTable = temperamentsAliasTable;
        _temperamentsProbTable = temperamentsProbTable;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 16000 && tokenId <= 20000, "Token ID invalid");
        require(msg.value >= _price, "Did not send enough ETH");
        _safeMint(_msgSender(), tokenId);
    }

    function mintWithXLoot(uint256 lootId) public payable nonReentrant {
        require(lootId > 8000 && lootId <= 16000, "Token ID invalid");
        require(
            xLootContract.ownerOf(lootId) == msg.sender,
            "Not the owner of this loot"
        );
        require(block.timestamp <= offerExpires, "Offer Expired");
        require(msg.value >= _priceWithXLoot, "Did not send enough ETH");
        _safeMint(_msgSender(), lootId);
    }

    function mintWithLoot(uint256 lootId) public payable nonReentrant {
        require(lootId > 0 && lootId <= 8000, "Token ID invalid");
        require(
            lootContract.ownerOf(lootId) == msg.sender,
            "Not the owner of this loot"
        );
        require(block.timestamp <= offerExpires, "Offer Expired");
        require(msg.value >= _priceWithLoot, "Did not send enough ETH");
        _safeMint(_msgSender(), lootId);
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

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getAttributeSeed(uint256 tokenId, string memory attribute)
        internal
        pure
        returns (uint256)
    {
        return random(string(abi.encodePacked(attribute, toString(tokenId))));
    }

    function getRandomAttribute(
        uint256 tokenId,
        string memory attribute,
        uint256 min,
        uint256 max
    ) internal pure returns (string memory) {
        uint256 rand = (getAttributeSeed(tokenId, attribute) % (max - min)) +
            min;
        return string(abi.encodePacked(attribute, ": ", toString(rand)));
    }

    function getMount(uint256 tokenId) public view returns (string memory) {
        uint256 idx = getAttributeSeed(tokenId, "MOUNT") % _mounts.length;
        uint256 prob = getAttributeSeed(tokenId, "MOUNTALIAS") % _mounts.length;

        uint8 resIdx = prob < uint8(_mountsProbTable[prob])
            ? uint8(idx)
            : uint8(_mountsAliasTable[idx]);
        return _mounts[resIdx];
    }

    function getTemperament(uint256 tokenId) public view returns (string memory) {
        uint256 idx = getAttributeSeed(tokenId, "TEMPERAMENT") % _temperaments.length;
        uint256 prob = getAttributeSeed(tokenId, "TEMPERAMENTALIAS") % _temperaments.length;

        uint8 resIdx = prob < uint8(_temperamentsProbTable[prob])
        ? uint8(idx)
        : uint8(_temperamentsAliasTable[idx]);
        return _temperaments[resIdx];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getTemperament(tokenId);

        parts[2] = ' ';

        parts[3] = getMount(tokenId);

        parts[4] = '</text><text x="10" y="40" class="base">';

        parts[5] = getRandomAttribute(tokenId, "Speed", 1, 10);

        parts[6] = '</text><text x="10" y="60" class="base">';

        parts[7] = getRandomAttribute(tokenId, "Intelligence", 1, 20);

        parts[8] = '</text><text x="10" y="80" class="base">';

        parts[9] = getRandomAttribute(tokenId, "Combat Experience", 1, 10);

        parts[10] = '</text><text x="10" y="100" class="base">';

        parts[11] = getRandomAttribute(tokenId, "Armor Class", 1, 5);

        parts[12] = '</text><text x="10" y="120" class="base">';

        parts[13] = getRandomAttribute(tokenId, "Natural Charm", 1, 100);

        parts[14] = '</text><text x="10" y="140" class="base">';

        parts[15] = getRandomAttribute(tokenId, "Soul Saturation", 1, 100);

        parts[16] = "</text></svg>";

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

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Mount #',
                        toString(tokenId),
                        '", "description": "Mounts is a Loot derivative that equips adventurers with a trusty steed or beast for use in the Loot metaverse. Bond with your companion, show off rare traits and personalities, and use your Mount to explore the outer limits of your imagination!", "image": "data:image/svg+xml;base64,',
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

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        require(payable(t1).send(_each), "Failed to send to t1");
        require(payable(t2).send(_each), "Failed to send to t2");
        require(payable(t3).send(_each), "Failed to send to t3");
        require(payable(t4).send(_each), "Failed to send to t4");
    }
}
