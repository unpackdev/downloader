// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./console.sol";
import "./ERC721Namable.sol";
import "./YieldToken.sol";

/* 

░█████╗░░█████╗░██╗░░░░░░█████╗░██████╗░░██████╗  ░█████╗░███╗░░██╗  ░█████╗░██╗░░██╗░█████╗░██╗███╗░░██╗
██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔════╝  ██╔══██╗████╗░██║  ██╔══██╗██║░░██║██╔══██╗██║████╗░██║
██║░░╚═╝██║░░██║██║░░░░░██║░░██║██████╔╝╚█████╗░  ██║░░██║██╔██╗██║  ██║░░╚═╝███████║███████║██║██╔██╗██║
██║░░██╗██║░░██║██║░░░░░██║░░██║██╔══██╗░╚═══██╗  ██║░░██║██║╚████║  ██║░░██╗██╔══██║██╔══██║██║██║╚████║
╚█████╔╝╚█████╔╝███████╗╚█████╔╝██║░░██║██████╔╝  ╚█████╔╝██║░╚███║  ╚█████╔╝██║░░██║██║░░██║██║██║░╚███║
░╚════╝░░╚════╝░╚══════╝░╚════╝░╚═╝░░╚═╝╚═════╝░  ░╚════╝░╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝

░░░░░░  ███╗░░██╗░█████╗░  ██╗██████╗░███████╗░██████╗  ███╗░░██╗░█████╗░  ██████╗░░██████╗
░░░░░░  ████╗░██║██╔══██╗  ██║██╔══██╗██╔════╝██╔════╝  ████╗░██║██╔══██╗  ██╔══██╗██╔════╝
█████╗  ██╔██╗██║██║░░██║  ██║██████╔╝█████╗░░╚█████╗░  ██╔██╗██║██║░░██║  ██████╦╝╚█████╗░
╚════╝  ██║╚████║██║░░██║  ██║██╔═══╝░██╔══╝░░░╚═══██╗  ██║╚████║██║░░██║  ██╔══██╗░╚═══██╗
░░░░░░  ██║░╚███║╚█████╔╝  ██║██║░░░░░██║░░░░░██████╔╝  ██║░╚███║╚█████╔╝  ██████╦╝██████╔╝
░░░░░░  ╚═╝░░╚══╝░╚════╝░  ╚═╝╚═╝░░░░░╚═╝░░░░░╚═════╝░█  ╚═╝░░╚══╝░╚════╝░  ╚═════╝░╚═════╝░

         :         . : 
         .       *
                      (
                        )     (
                 ___...(-------)-....___
             .-""       )    (          ""-.
       .-'``'|-._             )         _.-|
      /  .--.|   `""---...........---""`   |
     /  /    |                             |
     |  |    |                             |
      \  \   |       Colors On Chain       |
       `\ `\ |                             |
         `\ `|         Exclusively         |
         _/ /\        Generated and        /
        (__/  \      Stored On Chain      /
     _..---""` \                         /`""---.._
  .-'           \                       /          '-.
 :               `-.__             __.-'              :
 :                  ) ""---...---"" (                 :
  '._               `"--...___...--"`              _.'
    \""--..__                              __..--""/
     '._     """----.....______.....----"""     _.'
        `""--..,,_____            _____,,..--""`
                      `"""----"""`

*/

contract Color is ERC721Namable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    Counters.Counter private _tokenIds;

    struct Metadata {
        string hexCode;
    }

    mapping(uint256 => Metadata) public idToMetadata;
    mapping(string => uint256) public hexToDecimal;
    mapping(uint256 => string) public decimalToHex;
    mapping(uint256 => mapping(uint256 => bool)) public hasMixedWith;

    uint256 constant public BREED_PRICE = 500 ether;
	mapping(address => uint256) public balanceGen;
    uint256 public bebes;

    YieldToken public yieldToken;

    string[] private hexes = [
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "A",
        "B",
        "C",
        "D",
        "E",
        "F"
    ];
    uint256[] private decimals = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15
    ];

    constructor() ERC721Namable("Colors On Chain", "Color") {
        // Init mapping for converting hex to dec
        for (uint i=0; i < 16; i++) {
            hexToDecimal[hexes[i]] = decimals[i];
            decimalToHex[decimals[i]] = hexes[i];
        }
    }

    function setYieldToken(address _yield) external onlyOwner {
		yieldToken = YieldToken(_yield);
	}

    function changeName(uint256 tokenId, string memory newName) public override {
		yieldToken.burn(msg.sender, nameChangePrice);
		super.changeName(tokenId, newName);
	}

    function transferFrom(address from, address to, uint256 tokenId) public override {
		yieldToken.updateReward(from, to, tokenId);
		if (tokenId < 8889)
		{
			balanceGen[from]--;
			balanceGen[to]++;
		}
		ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		yieldToken.updateReward(from, to, tokenId);
		if (tokenId < 8889)
		{
			balanceGen[from]--;
			balanceGen[to]++;
		}
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}

    function getReward() external {
		yieldToken.updateReward(msg.sender, address(0), 0);
		yieldToken.getReward(msg.sender);
	}

    function getAHex(
        uint256 tokenId,
        string memory position,
        string[] memory hexArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(position, toString(tokenId)))
        );
        string memory output = hexArray[rand % hexArray.length];
        output = string(abi.encodePacked(output));
        return output;
    }


    function generateColor(uint256 tokenId) public view returns (string memory) {
        string[6] memory parts;
        parts[0] = getAHex(tokenId, "0", hexes);
        parts[1] = getAHex(tokenId, "1", hexes);
        parts[2] = getAHex(tokenId, "2", hexes);
        parts[3] = getAHex(tokenId, "3", hexes);
        parts[4] = getAHex(tokenId, "4", hexes);
        parts[5] = getAHex(tokenId, "5", hexes);
        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5]
            )
        );

        return output;
    }

    function getColorHexCode(uint256 tokenId) public view returns (string memory colorHexCode) {
        Metadata memory color = idToMetadata[tokenId];
        return color.hexCode;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[5] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">';
        parts[1] = '<rect width="100%" height="100%" fill="#';
        parts[2] = getColorHexCode(tokenId);
        parts[3] = '" />';
        parts[4] = "</svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Color #',
                        toString(tokenId),
                        '", "description": "Colors On Chain are randomized hex colors generated and stored on chain. All functionality is intentionally omitted for others to interpret. Feel free to use Colors in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": [{"trait_type": "Hex", "value": "#',
                        getColorHexCode(tokenId),
                        '"}]}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function fetchSaleFunds() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function amountMinted() public view returns (uint256) {
        return _tokenIds.current();
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

    // Let there be colors!
    function mint(uint256 num) public payable {
        require(num < 11, "You can only mint 10 at a time");
        uint256 newItemId = _tokenIds.current();
        require(newItemId > 99, "presale mint not complete");
        require(newItemId + num < 8889, "Exceeds max supply");
        require(msg.value == num * 0.08888 ether, "not enough eth sent");

        for(uint256 i; i < num; i++) {
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            string memory color = generateColor(newItemId);
            idToMetadata[newItemId] = Metadata(
                color
            );

            _safeMint(msg.sender, newItemId);
            balanceGen[msg.sender]++;

        }
        yieldToken.updateRewardOnMint(msg.sender, num);
        payable(owner()).transfer(num * 0.08888 ether);
    }

    // Used for airdrops, giveaways, and vault storage
    function preMintMint(uint256 num) public onlyOwner {
        uint256 newItemId = _tokenIds.current();
        require(newItemId + num < 101, "Exceeds max supply");

        for(uint256 i; i < num; i++) {
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            string memory color = generateColor(newItemId);
            idToMetadata[newItemId] = Metadata(
                color
            );
            _safeMint(msg.sender, newItemId);
            balanceGen[msg.sender]++;
        }
        // Perfect Red
        _tokenIds.increment();
        newItemId = _tokenIds.current();
        idToMetadata[newItemId] = Metadata(
            "FF0000"
        );
        _safeMint(msg.sender, newItemId);
        balanceGen[msg.sender]++;

        // Perfect Green
        _tokenIds.increment();
        newItemId = _tokenIds.current();
        idToMetadata[newItemId] = Metadata(
            "00FF00"
        );
        _safeMint(msg.sender, newItemId);
        balanceGen[msg.sender]++;

        // Perfect Blue
        _tokenIds.increment();
        newItemId = _tokenIds.current();
        idToMetadata[newItemId] = Metadata(
            "0000FF"
        );
        _safeMint(msg.sender, newItemId);
        balanceGen[msg.sender]++;
        yieldToken.updateRewardOnMint(msg.sender, num.add(3));   
    }

    function getRed(uint256 tokenId) public view returns(uint256) {
        uint256 redValue = hexToDecimal[getAHex(tokenId, "0", hexes)] * 16 + hexToDecimal[getAHex(tokenId, "1", hexes)];
        return redValue;
    }
    
    function getGreen(uint256 tokenId) public view returns(uint256) {
        uint256 greenValue = hexToDecimal[getAHex(tokenId, "4", hexes)] * 16 + hexToDecimal[getAHex(tokenId, "5", hexes)];
        return greenValue;
    }

    function getBlue(uint256 tokenId) public view returns(uint256) {
        uint256 blueValue = hexToDecimal[getAHex(tokenId, "2", hexes)] * 16 + hexToDecimal[getAHex(tokenId, "3", hexes)];
        return blueValue;
    }

    function buildHexString(uint256 red, uint256 green, uint256 blue) public view returns(string memory) {
        string[6] memory parts;
        unchecked {
            uint256 a = red / 16;
            uint256 b = red % 16;
            parts[0] = decimalToHex[a];
            parts[1] = decimalToHex[b];

            uint256 c = green / 16;
            uint256 d = green % 16;
            parts[2] = decimalToHex[c];
            parts[3] = decimalToHex[d];

            uint256 e = blue / 16;
            uint256 f = blue % 16;
            parts[4] = decimalToHex[e];
            parts[5] = decimalToHex[f];
        }

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5]
            )
        );
        return output;
    }

    function breed(uint256 tokenIdOne, uint256 tokenIdTwo) public payable {
        require(ERC721.ownerOf(tokenIdOne) == msg.sender && ERC721.ownerOf(tokenIdTwo) == msg.sender, "not your colors");
        uint256 newItemId = _tokenIds.current();
        require(newItemId > 8888, "Minting has not completed");
        require(hasMixedWith[tokenIdOne][tokenIdTwo] == false, "Cannot breed the same colors twice");
        hasMixedWith[tokenIdOne][tokenIdTwo] = true;
        _tokenIds.increment();
        newItemId = _tokenIds.current();

        yieldToken.burn(msg.sender, BREED_PRICE);
        bebes++;

        uint256 r1 = getRed(tokenIdOne);
        uint256 r2 = getRed(tokenIdTwo);

        uint256 g1 = getGreen(tokenIdOne);
        uint256 g2 = getGreen(tokenIdTwo);

        uint256 b1 = getBlue(tokenIdOne);
        uint256 b2 = getBlue(tokenIdTwo);

        // Additive Color Theory
        uint256 newColorR = ((r1 + r2).div(2));
        uint256 newColorG = ((g1 + g2).div(2));
        uint256 newColorB = ((b1 + b2).div(2));

        string memory output = buildHexString(newColorR, newColorG, newColorB);
        idToMetadata[newItemId] = Metadata(
            output
        );
        _safeMint(msg.sender, newItemId);
    }

    function sendPrizeToContract(uint256 amount) public payable {
       require(msg.value == amount, "wrong amount sent");
    }

    // Who will claim the prize? GO BREED!
    function claimPrize(uint256 tokenId) public {
        require(ERC721.ownerOf(tokenId) == msg.sender, "not your color"); 
        require(keccak256(abi.encodePacked(idToMetadata[tokenId].hexCode)) == keccak256(abi.encodePacked("FFFFFF")), "wrong color, keep breeding!");

        payable(msg.sender).transfer(address(this).balance);
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
