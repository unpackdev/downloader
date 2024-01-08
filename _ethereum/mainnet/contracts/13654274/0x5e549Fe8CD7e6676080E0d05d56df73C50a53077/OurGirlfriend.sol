// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract OurGirlfriend is ERC721Enumerable, Ownable, ReentrancyGuard {

    event Wooed(address _wooer, uint256 tokenId, uint256 _newScore);

    mapping (uint256 => uint256) public relationshipScores;
    address public soulmate;
    uint256 public lastWooed;

    uint256 public mintRevenue;
    uint256 private creatorShareClaimed;
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant MAX_SUPPLY = 7777;

    string[] private HOBBIES = [
        "Play vidya",
        "Eat ramen",
        "Watch anime",
        "Cuddle",
        "Go on a hike",
        "Read to each other",
        "Night on the town",
        "Walk on the beach",
        "Role play",
        "Shop together",
        "Redecorate",
        "Go to the gym",
        "Dance",
        "Travel",
        "Gossip about friends",
        "Go sightseeing",
        "Clean the house",
        "Make home movies",
        "Fight"
    ];

    constructor() ERC721("Asami", "ASAMI") Ownable() {}

    function startARelationship() payable public nonReentrant { 
        require(msg.value == PRICE, "It costs 0.07 ETH to start a relationship");
        require(totalSupply() < MAX_SUPPLY, "Our GF is at max social capacity.");
        // Our GF is exclusive once she has found her soulmate.
        require(soulmate == address(0), "Our GF has found her soulmate.");
        relationshipScores[totalSupply()] = 1;
        mintRevenue += PRICE;
        _safeMint(_msgSender(), totalSupply());

    }

    function isGfTired() internal view returns (bool) {
        return lastWooed + 1 hours > block.timestamp;
    }

    function woo(uint256 tokenId) public nonReentrant { 
        // Our GF is sleeping until all her relationships have been started.
        require(totalSupply() == MAX_SUPPLY, "Our GF is sleeping.");
        // Please be respectful of other people's relationships with our GF.
        require(ownerOf(tokenId) == _msgSender(), "That isn't your relationship.");
        // Our GF gets tired for a bit after she is wooed.
        require(!isGfTired(), "Our GF is tired.");
        require(soulmate == address(0), "Our GF has found her soulmate.");

        relationshipScores[tokenId] += 1;
        lastWooed = block.timestamp;

        emit Wooed(_msgSender(), tokenId, relationshipScores[tokenId]);

        // If your relationship score goes to 30, you become Our GF's soulmate
        if (relationshipScores[tokenId] == 30) {
            soulmate = _msgSender();
            _safeMint(_msgSender(), MAX_SUPPLY);
            // Our GF's soulmate gets half the mint revenue and Our GF's heart
            payable(_msgSender()).transfer(mintRevenue / 2);
        }
    }

    function creatorWithdraw() public nonReentrant onlyOwner {
        uint256 claimableAmount = (mintRevenue / 2) - creatorShareClaimed;
        creatorShareClaimed += claimableAmount;
        payable(owner()).transfer(claimableAmount);
    }

    function relationshipStatus(uint256 tokenId) public view returns (string memory) {
        uint256 relationshipScore = relationshipScores[tokenId];
        if (relationshipScore < 1) {
            return "Stranger";
        } else if (relationshipScore < 2) {
            return "Friend";
        } else if (relationshipScore < 10) {
            return "Someone Special";
        } else if (relationshipScore < 30) {
            return "Lover";
        } else {
            return "Soulmate";
        }
    }

    function relationshipLevel(uint256 tokenId) internal view returns (string memory) {
        uint256 relationshipScore = relationshipScores[tokenId];
        if (relationshipScore < 1) {
            return "1";
        } else if (relationshipScore < 2) {
            return "2";
        } else if (relationshipScore < 10) {
            return "3";
        } else if (relationshipScore < 30) {
            return "4";
        } else {
            return "5";
        }
    }

    function howIsSheFeeling() public view returns (string memory) {
        if (totalSupply() < MAX_SUPPLY) {
            return "Asleep.";
        } else if (isGfTired()) {
            return "Tired.";
        } else {
            // This means she can be wooed
            return "Excited to see you.";
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (tokenId == 7777) {
            return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "Asami (v0.1)`s Heart", "description": "Asami has found her soulmate.", "animation_url": "https://assets.idolresearchersapi.com/ASAMI-HEART.mp4", "attributes": [ { "trait_type": "Feels", "value": "Fulfilled" } ], "image": "https://assets.idolresearchersapi.com/ASAMI-HEART.png"}'))))));
        }

        string memory paddedTokenId = Strings.toString(tokenId);
        if (tokenId < 10) {
            paddedTokenId = string(abi.encodePacked('000', Strings.toString(tokenId)));
        } else if (tokenId < 100) {
            paddedTokenId = string(abi.encodePacked('00', Strings.toString(tokenId)));
        } else if (tokenId < 1000) {
            paddedTokenId = string(abi.encodePacked('0', Strings.toString(tokenId)));
        }

        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId)));
        string memory imageUrl = string(abi.encodePacked('https://assets.idolresearchersapi.com/ASAMI-', paddedTokenId, '-' , relationshipLevel(tokenId), '.svg'));

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "Asami (v0.1) #', paddedTokenId, '", "description": "Asami is looking for her soulmate.", "attributes": [ { "trait_type": "Relationship Status", "', relationshipStatus(tokenId) , '" }, { "trait_type": "Alignment", "value": "', tokenId % 2 == 0 ? 'Light' : 'Dark', '" }, { "trait_type": "Auspicious Number", "value": ', Strings.toString(tokenId % 7 + 1) , ' }, { "trait_type": "Zodiac", "value": "Scorpio" }, { "trait_type": "Anon Let`s", "value": "', HOBBIES[rand % HOBBIES.length], '" } ], "image": "', imageUrl, '"}'))))));
    }
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