pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Checkpointable.sol";

// Copied from dope loot contract: https://etherscan.io/address/0x8707276df042e89669d69a177d3da7dc78bd8723#code

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

contract FootyVerse is ERC721Checkpointable, ReentrancyGuard, Ownable {
    
    uint256 public constant MAX_RESERVE_FOR_OWNER = 500;
    uint256 public totalClaimedByOwner;
    
    string[] private positions = [
       "Goalkeeper",
       "Left Back",
       "Right Back",
       "Centre Back",
       "Defensive Midfielder",
       "Attacking Midfielder",
       "Central Midfielder",
       "Left Winger",
       "Right Winger",
       "Forward"
    ];

    string[][] private specializationsForPositions;

    string[] private mentalAttributes = [
       "Aggressive",
       "Composed",
       "Intelligent",
       "Aware",
       "Reactive",
       "Defensive",
       "Team Player",
       "Leader",
       "Visionary"
    ];

    string[] private physicalAttributes = [
       "Strength",
       "Stamina",
       "Height",
       "Speed",
       "Balance",
       "Acceleration",
       "Jumping",
       "Agility",
       "Endurance"
    ];

    string[] private skills = [
       "Passing",
       "Tackling",
       "Dribbling",
       "Marking",
       "Interceptions",
       "Positioning",
       "Heading",
       "Crossing",
       "Finishing",
       "Tracking",
       "Ball Control"
    ];

    string[] private specialSkills = [
       "Free Kicks",
       "Penalties",
       "Long Shots",
       "Volleys",
       "Slide Tackle",
       "Standing Tackle",
       "Corners",
       "Finesse Shots",
       "Power Shots",
       "One on One",
       "Two Footed",
       "Versatile"
    ];

    string[] private visuals = [
       "Bald",
       "Styled Beard",
       "Fire Shoes",
       "Piercings",
       "Gloves",
       "Afro",
       "Styled Hair",
       "Long Hair",
       "Sleeve Tattoo",
       "Ponytail"
    ];

    string[] private celebrations = [
       "Cartwheel",
       "Somersault",
       "Pointing to Sky",
       "Kissing Camera",
       "Knee Glide",
       "Kissing Team Logo",
       "Cupping Ears",
       "Heart",
       "Robot Dance",
       "Take Off Jersey",
       "Jump Fence"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getPosition(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "POSITION", positions);
    }

    function getMental(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MENTAL", mentalAttributes);
    }

    function getPhysical(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "PHYSICAL", physicalAttributes);
    }

    function getSkill(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SKILL", skills);
    }

    function getSpecialSkill(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SPECIALSKILL", specialSkills);
    }

    function getVisual(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "VISUAL", visuals);
    }

    function getCelebration(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CELEBRATION", celebrations);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        uint256 required_index = rand % sourceArray.length;
        string memory output = sourceArray[required_index];
        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256(abi.encodePacked("POSITION"))) {
            uint256 greatness = rand % 11;
            if (greatness == 10) {
                uint256 randSpecial = random(string(abi.encodePacked(toString(rand), keyPrefix, toString(tokenId))));
                output = string(abi.encodePacked(output, " - ", specializationsForPositions[required_index][randSpecial % specializationsForPositions[required_index].length]));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[15] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getPosition(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getMental(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getPhysical(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getSkill(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getSpecialSkill(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getVisual(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getCelebration(tokenId);

        parts[14] = "</text></svg>";

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
                parts[14]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Player #',
                        toString(tokenId),
                        '", "description": "FootyVerse is randomized football (soccer) player generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use in any way you want.", "image": "data:image/svg+xml;base64,',
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

    function claim(uint256 tokenId) external nonReentrant {
        require(tokenId > 0 && tokenId < 10001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    // To be used for dev incentives and partnerships by DAO (Owner)
    function claimByOwner(uint256 tokenId) external nonReentrant onlyOwner {
        require(tokenId > 10000, "Token ID invalid");
        require(totalClaimedByOwner < MAX_RESERVE_FOR_OWNER, "Maximum reserve claimed");
        totalClaimedByOwner = totalClaimedByOwner + 1;
        _safeMint(_msgSender(), tokenId);
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

    constructor() ERC721("FOOTY", "FOOTY") Ownable() {
       specializationsForPositions.push(["Sweeper Keeper", "Owns the Box", "Shot Stopper"]);    // GK
       specializationsForPositions.push(["Wing Back", "Full Back", "Inverted Wing Back"]);   // LB
       specializationsForPositions.push(["Wing Back", "Full Back", "Inverted Wing Back"]);   // RB
       specializationsForPositions.push(["Sweeper", "Libero", "Ball Playing"]);   // CB
       specializationsForPositions.push(["Regista", "Ball Winner", "Anchor Man", "Segundo Volante"]);   // CDM
       specializationsForPositions.push(["Trequartista", "Fantasista", "False 9", "Shadow Striker", "Roaming Playmaker", "Raumdeuter"]);  // CAM
       specializationsForPositions.push(["Regista", "Ball Winner", "Mezzala", "Box to Box", "Carrilero"]);    // CM
       specializationsForPositions.push(["Mezzala", "Roaming Playmaker", "Inverted Winger"]);    // LW
       specializationsForPositions.push(["Mezzala", "Roaming Playmaker", "Inverted Winger"]);    // RW
       specializationsForPositions.push(["False 9", "Target Man", "Poacher", "Shadow Striker", "Raumdeuter", "Fox in the Box"]);    // FW
    }
}