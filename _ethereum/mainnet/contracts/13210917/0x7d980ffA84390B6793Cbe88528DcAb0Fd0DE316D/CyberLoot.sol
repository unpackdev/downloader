// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CyberLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    
    bool public saleIsActive = false;
    uint256 public constant NFT_PRICE = 50000000000000000; // 0.05 ETH
    uint256 public MAX_SUPPLY = 8000;
    uint256 public RESERVE = 200;
    mapping(address => bool) minted;

    string[] private weapons = [
        "Plasma Pistol",
        "Laser Rifle",
        "Railgun",
        "Samurai Sword",
        "Baseball Bat",
        "D5 Sidewinder AR",
        "Dying Night Pistol",
        "Doom Postol",
        "DB-2 Satara AR",
        "Widow Maker AR",
        "Machete",
        "Kukri",
        "Cleaver"
    ];
    
    string[] private outerChestWear = [
        "Bomber Jacket",
        "Tactical Jacket",
        "Badge-Coat",
        "Evening Jacket",
        "Coral Bodysuit",
        "Classic Shirt",
        "Breastplate",
        "Biker Jacket",
        "Polyamide Jumpsuit",
        "Bolero Rubber",
        "Biker Coat"
    ];
    
    string[] private innerChestWear = [
        "Tank-Top",
        "Turtleneck",
        "Composite Vest",
        "Tactical Vest",
        "Plaid Shirt",
        "Cotton Shirt",
        "Loose-Fit Shirt"
    ];
    
    string[] private headWear = [
        "Baseball Cap",
        "Bandana",
        "Mafioso Helmet",
        "Carbon Fiber Helmet",
        "Beanie",
        "Biohacker brain",
        "Vanadium helmet",
        "Avantgarde helmet",
        "Mechanical head"
    ];

    string[] private legWear = [
        "Cargo Pants",
        "Cut-off Shorts",
        "Sweatpants",
        "Corporate Slacks",
        "Leather Pants",
        "Tactical Pants",
        "Cut-Off Shorts",
        "Plastic Shinos",
        "Bitch Skirt",
        "Formal Skirt"
    ];
    
    string[] private footWear = [
        "Dress Shoes",
        "Combat Boots",
        "Slip-On Sneakers",
        "Monkey Kicks",
        "Chelsea Boots",
        "Work Boots",
        "Dress Shoes",
        "Sneakers",
        "Punk Fleets",
        "Muddy Fleets"
    ];
    
    string[] private eyeWear = [
        "Aviators",
        "Eyepatch",
        "Tech Goggles",
        "Menpo",
        "Sport Sunglasses",
        "Chakra glasses",
        "Sceleton glasses",
        "Techno glasses",
        "Square Glasses",
        "Graffiti Glasses"
    ];
    
    string[] private cyberWare = [
        "Mechatronic Core",
        "Optical Enhancer",
        "Accelerator",
        "Bionic Joints",
        "Subdermal Armor",
        "Bioconductor",
        "Feedback Circuit",
        "Cataresist",
        "Kerenzikov"
    ];
    
    string[] private prefixes = [
        "Psycho",
        "Reinforced",
        "Ultralight",
        "Heavy-Duty",
        "Classic",
        "Durable",
        "Light",
        "Modified",
        "Solid",
        "Strong",
        "Worn",
        "Holo-Tinted",
        "Military"
    ];
    
    string[] private namePrefixes = [
        "Atomic", 
        "Mecha", 
        "Vox", 
        "Cyborg", 
        "Flatline",
        "Militech",
        "Moore",
        "Stephenson",
        "Tetratronic",
        "Zetatech",
        "Bionic",
        "Butcher"
    ];
    
    string[] private nameSuffixes = [
        "Gorilla"
        "Vector",
        "Ice",
        "Net",
        "Machine",
        "Electric",
        "Ozob",
        "Char",
        "EMP",
        "F-GX",
        "X-22",
        "Veteran",
        "Johnny"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }
    
    function getOuterChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OUTER", outerChestWear);
    }
    
    function getInnerChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INNER", innerChestWear);
    }
    
    function getHeadWear(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", headWear);
    }

    function getLegWear(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LEG", legWear);
    }
    
    function getFootWear(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOOT", footWear);
    }
    
    function getEyeWear(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "EYE", eyeWear);
    }
    
    function getCyberWare(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CYBER", cyberWare);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 51;
        if (greatness > 40) {
            output = string(abi.encodePacked(prefixes[rand % prefixes.length], " ", output));
        }
        if (greatness >= 49) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 49) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }
    
    

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: arial; font-size: 14px; }</style><rect width="100%" height="100%" fill="#7a04eb" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getOuterChest(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getInnerChest(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getHeadWear(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getLegWear(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getFootWear(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getEyeWear(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getCyberWare(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Cyber Loot is randomized gears generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        
        return output;
    }
    
    function reserve(uint256 numberOfTokens) public nonReentrant onlyOwner {
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Would exceed max supply of Cyber Loot");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    modifier mintOnlyOnce() {
        require(!minted[_msgSender()], 'Can only mint once');
        minted[_msgSender()] = true;
        _;
    }
    
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, 'Sale is not active at the moment');
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY - RESERVE, "Purchase would exceed max supply of Cyber Loot");
        require(NFT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function mintForFree() public mintOnlyOnce {
        require(saleIsActive, 'Sale is not active at the moment');
        require(totalSupply().add(1) <= MAX_SUPPLY - RESERVE, 'Purchase would exceed max supply of Cyber Loot');
        _safeMint(msg.sender, totalSupply());
    }
    
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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
    
    constructor() ERC721("Cyber Loot", "CLOOT") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
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