// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";

// Follow is a social graph built with NFTs.
// Each NFT is represented as a one way "follow" relationship
// E.g. address X follows address Y, where X is the token minter.
// You can also trade these relationships. Owners of the token
// do not have permission to change who you are following.
// Follow is free to mint (minus gas). The first 10K tokens are
// "special" in that they have 3 emojis added to the SVG metadata.
// Feel free to interpret these emojis however you'd like!
// Learn more at follownft.io
// Created by @neelmango
// MIT License

contract Follow is ERC721Enumerable, Ownable {
    // The first 10000 are "special", early adopter
    // tokens which have 3 random emojis. Interpret
    // the emojis in any way you'd like!.
    uint256 public constant MAX_SPECIAL = 10000;

    bool public saleIsActive = false;

    // Maps tokenID to address that token minter is following.
    mapping(uint256 => address) public tokenMinterIsFollowing;

    // Maps tokenID to address that minted token.
    mapping(uint256 => address) public tokenMinter;

    // Checks if a tokenID is unfollowed. Default state is followed.
    mapping(uint256 => bool) public isUnfollowed;

    // Keeps track if X ever followed Y
    // Should also check "isUnfollowed" to get current status.
    // In order to block duplicates from being minted.
    mapping(address => mapping(address => bool)) public didXFollowY;

    // Emojis used for the first 10K mints.
    string[] private emojis = [
        unicode"😁",
        unicode"😮",
        unicode"😎",
        unicode"🤣",
        unicode"😍",
        unicode"🤩",
        unicode"🤪",
        unicode"🤐",
        unicode"👀",
        unicode"😈",
        unicode"🤯",
        unicode"🥳",
        unicode"🤓",
        unicode"👻",
        unicode"💩"
    ];

    // Custom data structure used for iterating through
    // People you are following, and people following you.
    using IndexedSet for IndexedSet.Set;

    IndexedSet.Set followersOfAddress;
    IndexedSet.Set addressIsFollowing;

    constructor() ERC721("Follow", "FOLLOW") {}

    // Creates an NFT that says msg.sender follows addressToFollow
    // This NFT will always represent this relationship, even if
    // transferred to other owners.
    function mint(address addressToFollow) public {
        require(saleIsActive, "sale not active");
        require(!didXFollowY[msg.sender][addressToFollow], "already exists");
        require(addressToFollow != msg.sender, "can't follow self");
        uint256 mintIndex = totalSupply();

        _safeMint(msg.sender, mintIndex);

        tokenMinterIsFollowing[mintIndex] = addressToFollow;
        tokenMinter[mintIndex] = msg.sender;

        followersOfAddress.insert(addressToFollow, msg.sender);
        addressIsFollowing.insert(msg.sender, addressToFollow);
        didXFollowY[msg.sender][addressToFollow] = true;
    }

    // Can only flip sale state once!
    function startSale() public onlyOwner {
        require(!saleIsActive, "sale already active");
        saleIsActive = true;
    }

    // How many followers does X have?
    function getNumFollowersOfX(address x) public view returns (uint256) {
        return followersOfAddress.setLength[x];
    }

    // Iterate through the followers of X.
    // The index ordering has no meaning.
    function getFollowerOfXAtIndex(address x, uint256 index)
        public
        view
        returns (address)
    {
        require(index < followersOfAddress.setLength[x]);
        return followersOfAddress.keyAddressToIndexedSet[x][index];
    }

    // How many addresses is X following?
    function getNumAddressesXIsFollowing(address x)
        public
        view
        returns (uint256)
    {
        return addressIsFollowing.setLength[x];
    }

    // Iterate through the addresses that X is following.
    // The index ordering has no meaning.
    function getAddressXIsFollowingAtIndex(address x, uint256 index)
        public
        view
        returns (address)
    {
        require(index < addressIsFollowing.setLength[x]);
        return addressIsFollowing.keyAddressToIndexedSet[x][index];
    }

    // Is X following Y?
    function isXFollowingY(address x, address y) public view returns (bool) {
        uint256 index = addressIsFollowing.keyValueAddressToIndex[x][y];
        return addressIsFollowing.keyAddressToIndexedSet[x][index] == y;
    }

    // Toggle follow state.
    // This will update necessary counts and internal state.
    function toggleFollow(uint256 tokenId) public {
        require(msg.sender == tokenMinter[tokenId], "not owner");
        isUnfollowed[tokenId] = !isUnfollowed[tokenId];
        address addressToFollow = tokenMinterIsFollowing[tokenId];

        // Update follower counts and follower tracking.
        if (isUnfollowed[tokenId]) {
            followersOfAddress.remove(addressToFollow, msg.sender);
            addressIsFollowing.remove(msg.sender, addressToFollow);
        } else {
            followersOfAddress.insert(addressToFollow, msg.sender);
            addressIsFollowing.insert(msg.sender, addressToFollow);
        }
    }

    // Code below inspired by Loot contract 0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenOwner = toAsciiString(ownerOf(tokenId));
        string memory isFollowing = toAsciiString(
            tokenMinterIsFollowing[tokenId]
        );

        string[9] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>text{fill:white;font-family:sans-serif;font-size:12px;text-anchor:middle}</style><rect width="100%" height="100%" fill="black"/><text x="175" y="140">0x';

        parts[1] = tokenOwner;

        parts[
            2
        ] = '</text><text x="175" y="160">is following</text><text x="175" y="180">0x';

        parts[3] = isFollowing;

        parts[4] = '</text><text x="175" y="200">';

        uint256 index1 = uint256(keccak256(abi.encodePacked(tokenId))) % 15;
        uint256 index2 = uint256(keccak256(abi.encodePacked(tokenId, "1"))) % 15;
        uint256 index3 = uint256(keccak256(abi.encodePacked(tokenId, "2"))) % 15;

        if (tokenId < MAX_SPECIAL) {
            parts[5] = emojis[index1];
            parts[6] = emojis[index2];
            parts[7] = emojis[index3];
        }

        parts[8] = "</text></svg>";

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

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Follow #',
                        toString(tokenId),
                        '","attributes":[{"trait_type":"Minter","value":"0x',
                        tokenOwner,
                        '"}, {"trait_type":"Is Following","value":"0x',
                        isFollowing,
                        '"}],"description":"Follow is a social graph built with NFTs. More at follownft.io","image":"data:image/svg+xml;base64,',
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

    // Used to convert an address to an Ascii string.
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// Inspired by OpenZeppelin/ERC721Enumerable [MIT]
// Key is an address, value is a set of addresses
// The set is enumerable
library IndexedSet {
    struct Set {
        // Map a (key) address to a set of (values) addresses
        // the set is indexed from 0..n where n is the size of the set.
        mapping(address => mapping(uint256 => address)) keyAddressToIndexedSet;
        // Given a key address and a value address, find the index of the value
        // address in the set associated with the key address.
        mapping(address => mapping(address => uint256)) keyValueAddressToIndex;
        // Given a key address, what is the length of the set.
        mapping(address => uint256) setLength;
    }

    function insert(
        Set storage self,
        address key,
        address value
    ) internal {
        uint256 size = self.setLength[key];
        self.keyAddressToIndexedSet[key][size] = value;
        self.keyValueAddressToIndex[key][value] = size;
        self.setLength[key]++;
    }

    // Remove last element and swap with removed element
    function remove(
        Set storage self,
        address key,
        address value
    ) internal {
        uint256 lastIndex = self.setLength[key] - 1;
        uint256 removeIndex = self.keyValueAddressToIndex[key][value];

        // Skip swap if removed element is already the last element
        if (lastIndex != removeIndex) {
            address lastAddress = self.keyAddressToIndexedSet[key][lastIndex];

            // Move last address to deleted slot
            self.keyAddressToIndexedSet[key][removeIndex] = lastAddress;
            // Update the index
            self.keyValueAddressToIndex[key][lastAddress] = removeIndex;
        }

        // Delete element at end of set.
        delete self.keyValueAddressToIndex[key][value];
        delete self.keyAddressToIndexedSet[key][lastIndex];
        self.setLength[key]--;
    }
}
