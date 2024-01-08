pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

// HiPokerLoot (POKER) Official Website
// https://hipokerloot.com
// https://twitter.com/hipokerloot
// https://t.me/hipokerloot_official
// mint fee: 0.01 ETH

contract PokerLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    struct MetaInfo {
        string card1;
        string card2;
        string card3;
        string card4;
        string card5;
        uint256 price;
        address signedBy;
    }

    mapping(uint256 => MetaInfo) public metaInfo;

    address payable public taxPool;
    uint256 public claimFee = 0.01 ether;

    string[] private cards = [
        unicode"🂠",
        unicode"🂡",
        unicode"🂢",
        unicode"🂣",
        unicode"🂤",
        unicode"🂥",
        unicode"🂦",
        unicode"🂧",
        unicode"🂨",
        unicode"🂩",
        unicode"🂪",
        unicode"🂫",
        unicode"🂭",
        unicode"🂱",
        unicode"🂲",
        unicode"🂳",
        unicode"🂴",
        unicode"🂵",
        unicode"🂶",
        unicode"🂷",
        unicode"🂸",
        unicode"🂹",
        unicode"🂺",
        unicode"🂻",
        unicode"🂽",
        unicode"🂾",
        unicode"🃁",
        unicode"🃂",
        unicode"🃃",
        unicode"🃄",
        unicode"🃅",
        unicode"🃆",
        unicode"🃇",
        unicode"🃈",
        unicode"🃉",
        unicode"🃊",
        unicode"🃋",
        unicode"🃍",
        unicode"🃎",
        unicode"🃑",
        unicode"🃒",
        unicode"🃓",
        unicode"🃔",
        unicode"🃕",
        unicode"🃖",
        unicode"🃗",
        unicode"🃘",
        unicode"🃙",
        unicode"🃚",
        unicode"🃛",
        unicode"🃝",
        unicode"🃞",
        unicode"🃟"
    ];

    event TradeInChaos(
        uint256 indexed tokenId,
        address indexed owner,
        address indexed buyer,
        uint256 price
    );

    event SetPriceGuard(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function addressToString(address _addr)
        public
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(
                abi.encodePacked(
                    keyPrefix,
                    toString(tokenId),
                    metaInfo[tokenId].signedBy
                )
            )
        );
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function compareStrings(string memory a, string memory b)
        public
        view
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getCard(uint256 tokenId, string memory cardPosition)
        public
        view
        returns (string memory)
    {
        string memory card = pluck(tokenId, cardPosition, cards);

        if (
            !compareStrings(card, metaInfo[tokenId].card1) &&
            !compareStrings(card, metaInfo[tokenId].card2) &&
            !compareStrings(card, metaInfo[tokenId].card3) &&
            !compareStrings(card, metaInfo[tokenId].card4) &&
            !compareStrings(card, metaInfo[tokenId].card5)
        ) {
            return card;
        }

        return pluck(tokenId, cardPosition, cards);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[11] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 70px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="185" class="base">';

        parts[1] = metaInfo[tokenId].card1;

        parts[2] = '</text><text x="80" y="185" class="base">';

        parts[3] = metaInfo[tokenId].card2;

        parts[4] = '</text><text x="150" y="185" class="base">';

        parts[5] = metaInfo[tokenId].card3;

        parts[6] = '</text><text x="220" y="185" class="base">';

        parts[7] = metaInfo[tokenId].card4;

        parts[8] = '</text><text x="290" y="185" class="base">';

        parts[9] = metaInfo[tokenId].card5;

        parts[10] = "</text></svg>";

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
        output = string(abi.encodePacked(output, parts[9], parts[10]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Nut #',
                        toString(tokenId),
                        '", "description": "HiPokerLoot (POKER) are randomized, generated, and stored on chain. Images and other functionality are intentionally omitted for others to interpret. Feel free to use POKER in any way you want. Inspired and compatible with Poker Loot. This NFT was signed by ',
                        addressToString(metaInfo[tokenId].signedBy),
                        '.", "image": "data:image/svg+xml;base64,',
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

    function claim() public payable nonReentrant {
        require(msg.value == claimFee, "Error: claim fee is not matched");

        (bool isTaxSent, ) = taxPool.call{value: address(this).balance}("");
        require(isTaxSent, "Error: payout is not processable");

        // unlimited supply
        uint256 tokenId = totalSupply();

        _safeMint(_msgSender(), tokenId);

        // permanently update
        metaInfo[tokenId].card1 = getCard(tokenId, "card1");
        metaInfo[tokenId].card2 = getCard(tokenId, "card2");
        metaInfo[tokenId].card3 = getCard(tokenId, "card3");
        metaInfo[tokenId].card4 = getCard(tokenId, "card4");
        metaInfo[tokenId].card5 = getCard(tokenId, "card5");
        metaInfo[tokenId].signedBy = msg.sender;
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

    constructor() ERC721("HiPokerLoot NFT Token", "POKER") Ownable() {
        taxPool = payable(msg.sender);
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
