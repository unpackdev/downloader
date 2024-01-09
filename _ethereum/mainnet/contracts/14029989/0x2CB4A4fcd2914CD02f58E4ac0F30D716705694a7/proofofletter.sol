// SPDX-License-Identifier: MIT


/*
       ,---.
     ,'_   _`.
   {{ |o| |o| }}
  {{{ '-'O'-' }}}
  {{( (`-.-') )}}
   {{{.`---',}}}
       `---'    lulz
*/


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

                                                                                    

contract circusOfClowns is ERC721, Ownable {

	uint public maxSupply = 1000;
	
	mapping(address => uint) public addressClaimed;
	


    using Counters for Counters.Counter;
    Counters.Counter private bSupply;

    constructor() ERC721("Circus Of Clowns", "CLOWN") {

    }


    function totalSupply() public view returns (uint256 supply) {
        return bSupply.current();
    }

	
    function claim() external payable {
        require(bSupply.current() + 1 <= maxSupply, "No more supply.");
		require(addressClaimed[msg.sender] < 5, "Five per wallet.");
        
		addressClaimed[msg.sender] += 1;
        for(uint i = 0; i < 1; i++) {
		  uint256 _tokenId = bSupply.current() + 1;

             if (_tokenId > 150) {
                require (msg.value >= 5000000000000000, "Now costs 0.005 ETH.");
                _safeMint(msg.sender, _tokenId);
                bSupply.increment();
             } else {
             _safeMint(msg.sender, _tokenId);
             bSupply.increment();
             }
        }
    }

	
	
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
	
        string memory image = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" width="350" height="350" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><rect x="0" y="0" width="36" height="36" fill="none" stroke="none" /><circle fill="#4289C1" cx="29" cy="3" r="2"/><circle fill="#4289C1" cx="33" cy="8" r="3"/><circle fill="#4289C1" cx="33" cy="4" r="3"/><circle fill="#4289C1" cx="7" cy="3" r="2"/><circle fill="#4289C1" cx="3" cy="8" r="3"/><circle fill="#4289C1" cx="3" cy="4" r="3"/><path fill="#FEE7B8" d="M36 18c0 9.941-8.059 18-18 18S0 27.941 0 18S8.059 0 18 0s18 8.059 18 18"/><circle fill="#4289C1" cx="30.5" cy="4.5" r="2.5"/><circle fill="#4289C1" cx="32" cy="7" r="2"/><circle fill="#4289C1" cx="5.5" cy="4.5" r="2.5"/><circle fill="#4289C1" cx="4" cy="7" r="2"/><circle fill="#FF7892" cx="6.93" cy="21" r="4"/><circle fill="#FF7892" cx="28.93" cy="21" r="4"/><path fill="#DA2F47" d="M27.335 23.629a.501.501 0 0 0-.635-.029c-.039.029-3.922 2.9-8.7 2.9c-4.766 0-8.662-2.871-8.7-2.9a.5.5 0 0 0-.729.657C8.7 24.472 11.788 31 18 31s9.301-6.528 9.429-6.743a.499.499 0 0 0-.094-.628z"/><path fill="none" d="M27.335 23.629a.501.501 0 0 0-.635-.029c-.039.029-3.922 2.9-8.7 2.9c-4.766 0-8.662-2.871-8.7-2.9a.5.5 0 0 0-.729.657C8.7 24.472 11.788 31 18 31s9.301-6.528 9.429-6.743a.499.499 0 0 0-.094-.628z"/><ellipse fill="#664500" cx="11.5" cy="11.5" rx="2.5" ry="3.5"/><ellipse fill="#664500" cx="25.5" cy="11.5" rx="2.5" ry="3.5"/><circle fill="#BB1A34" cx="18.5" cy="19.5" r="3.5"/></svg>'));
        string memory output = string(abi.encodePacked(image));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Circus Of Clowns #', toString(tokenId),'","attributes": [ { "trait_type": "Not ', unicode"🤡" ,'", "value": "','False','" }]',', "description": "Certified ', unicode"🤡", ' - ', toString(tokenId),'/1000',' -- First 150 Mints Free then 0.005 ETH. -- Max 5 per wallet ", "image": "data:image/svg+xml;base64,',Base64.encode(bytes(output)),'"}'))));
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

    function withdraw() public payable onlyOwner {
        payable(owner()).call{value: address(this).balance}("");
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