//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface NProjectInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Objects is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public nProjectPrice = 20000000000000000; //0.02 ETH
    uint256 public publicPrice = 50000000000000000; //0.05 ETH


    //N Project Contract
    address public nProjectAddress = 0x05a46f1E545526FB803FF974C790aCeA34D1f2D6;
    NProjectInterface public nProjectContract = NProjectInterface(nProjectAddress);

    string[] private s1 = [
        "Extremely",
        "Very",
        "Moderately",
        "Slightly"
    ];

    string[] private s2 = [
        "Adventurous",
        "Aggressive", 
        "Bloody", 
        "Confused", 
        "Dangerous",
        "Depressed", 
        "Grotesque", 
        "Mysterious"
        "Strange", 
        "Frightened", 
        "Gentle", 
        "Creepy", 
        "Charming", 
        "Clumsy", 
        "Cheerful", 
        "Disturbed", 
        "Happy", 
        "Naughty"
    ];

    string[] private s3 = [
        "White",
        "Yellow",
        "Blue",
        "Red",
        "Green",
        "Black",
        "Brown",
        "Azure",
        "Ivory",
        "Teal",
        "Silver",
        "Purple",
        "Gray",
        "Orange",
        "Maroon"
    ];

    string[] private s4 = [
        "Aardvark", 
        "Dog", 
        "Tuna", 
        "Camel",
        "Penguin", 
        "Cabbage", 
        "Asparagus"
        "Bean", 
        "Pepper", 
        "Pen", 
        "Paper", 
        "Stapler", 
        "Scissors", 
        "Cigarette", 
        "Telephone", 
        "Computer", 
        "Toothbrush"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[9] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 28px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="40" class="base">';

        parts[1] = pluck(tokenId, "s1", s1);

        parts[2] = '</text><text x="10" y="80" class="base">';

        parts[3] = pluck(tokenId, "s2", s2);

        parts[4] = '</text><text x="10" y="120" class="base">';

        parts[5] = pluck(tokenId, "s3", s3);

        parts[6] = '</text><text x="10" y="160" class="base">';

        parts[7] = pluck(tokenId, "s4", s4);

        parts[8] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );

        output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], parts[8]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Object #',
                        toString(tokenId),
                        '", "description": "Objects are randomly generated and stored on chain, free for interpretation", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 8888 && tokenId <= 12000, "Token ID invalid");
        require(publicPrice <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
        require((publicPrice * tokenIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 8888 && tokenIds[i] < 12000, "Token ID invalid");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function mintWithN(uint256 NId) public payable nonReentrant {
        require(nProjectPrice <= msg.value, "Ether value sent is not correct");
        require(NId > 0 && NId <= 8888, "Token ID invalid");
        require(nProjectContract.ownerOf(NId) == msg.sender, "Not the owner of this n project");
        _safeMint(_msgSender(), NId);
    }

    function multiMintWithN(uint256[] memory NIds) public payable nonReentrant {
        require((publicPrice * NIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < NIds.length; i++) {
            require(NIds[i] > 0 && NIds[i] <= 8888, "Token ID invalid");
            require(nProjectContract.ownerOf(NIds[i]) == msg.sender, "Not the owner of this n project");
            _safeMint(_msgSender(), NIds[i]);
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

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

    constructor() ERC721("Objects (for n holders)", "OBJS") Ownable() {}
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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