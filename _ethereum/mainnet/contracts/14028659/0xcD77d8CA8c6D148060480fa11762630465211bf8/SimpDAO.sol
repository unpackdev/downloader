//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Counters.sol";
contract SimpDAO is ERC721A, Ownable {

    uint256 public mintPrice = 0.01 ether;
    uint32 constant public maxSupply = 1111;
    uint32 constant public freeMintMax = 500;
    uint256 public freeMintCount = 0;
    uint256 public saleStartTimestamp;

    constructor() ERC721A("SimpDAO", "Simp", 2, maxSupply) {
    }

    function mint(uint256 _quantity) external payable {
        require(msg.value >= mintPrice * _quantity, "Insufficent ethereum amount sent");
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint256 _quantity) external {
        require(freeMintCount +_quantity < freeMintMax, "Free mint limit reached");
        _safeMint(msg.sender, _quantity);
        freeMintCount += _quantity;
    }

 
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
	
        string memory image = string(abi.encodePacked('<svg width="512pt" height="512pt" version="1.0" viewBox="0 0 512.000000 512.000000" xmlns="http://www.w3.org/2000/svg"> <g transform="translate(0 512) scale(.1 -.1)"> <path d="m465 5104c-228-45-406-225-450-458-22-117-23-4054 0-4173 44-235 222-413 459-458 117-22 4054-23 4173 0 235 44 413 222 458 459 22 117 23 4054 0 4173-44 235-222 413-459 458-112 22-4072 21-4181-1zm2409-943c280-57 470-163 532-296 50-105 24-256-58-349-64-74-105-91-218-91-89 0-105 3-245 52-227 79-369 92-494 44-114-43-172-105-193-203-16-79 0-129 61-189 61-59 156-99 426-179 113-33 241-74 284-90 372-137 572-321 657-605 36-120 45-357 20-484-79-388-360-677-765-785-140-38-263-50-445-43-488 17-848 151-947 353-35 71-39 188-9 268 25 67 83 130 145 161 33 16 60 20 145 19 102 0 111-2 287-62 212-72 278-89 389-98 210-17 388 65 461 214 24 50 28 69 28 149 0 85-2 94-30 135-37 53-129 116-221 152-38 14-181 60-319 100-404 120-546 188-691 331-130 129-190 272-201 476-28 526 341 950 903 1039 96 15 384 4 498-19z"/> </g> </svg> '));
        string memory output = string(abi.encodePacked(image));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Simp #', toString(tokenId),'","attributes": [ { "trait_type": "Simp", "value": "','True','" }]',', "description": "Certified Simp - ', toString(tokenId),'/1000','", "image": "data:image/svg+xml;base64,',Base64.encode(bytes(output)),'"}'))));
		output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    	
	 /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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