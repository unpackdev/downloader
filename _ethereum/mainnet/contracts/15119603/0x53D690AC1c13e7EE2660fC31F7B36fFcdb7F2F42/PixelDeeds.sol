//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";



/*

		  __...--~~~~~-._   _.-~~~~~--...__
		//               `V'               \\ 
	   //  NOTARIZE NOW   |  PIXELDEEDS.COM \\ 
	  //__...--~~~~~~-._  |  _.-~~~~~~--...__\\ 
	 //__.....----~~~~._\ | /_.~~~~----.....__\\
	====================\\|//====================
						`---`
						
*/


    
contract PixelDeeds is ERC721AQueryable, ERC721ABurnable, Ownable {


    constructor() ERC721A("Pixel Deeds", "PXD"){}

    bool public notaryIsActive;
    uint256 public constant maxDeeds = 5000;
    mapping(address => uint256) public notarizations;


    modifier areYouAllowedToNotarize(uint256 _amount) {

        require(tx.origin == msg.sender);
        require(notaryIsActive, "Notarization of deeds is closed.");
        require(_totalMinted() + _amount <= maxDeeds, "No more deeds left to notarize.");
        require(_amount > 0, "Must notarize more than 1.");
        require(_amount + notarizations[msg.sender] <= 3, "Maximum 3 deeds per wallet.");
        _;

    }


    function notarizeDeed(uint256 _amount) external areYouAllowedToNotarize(_amount) {

        notarizations[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);

    }


    function generateRGB(uint256 tokenId) internal view returns (uint256[3] memory) {
        
        uint256 r = uint256(keccak256(abi.encodePacked(tokenId, "r"))) % 256;
        uint256 g = uint256(keccak256(abi.encodePacked(tokenId, "g"))) % 256;
        uint256 b = uint256(keccak256(abi.encodePacked(tokenId, "b"))) % 256;
        uint256[3] memory rgbArray = [r, g, b];
        return rgbArray;

    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256[3] memory rgbArray = generateRGB(tokenId);

        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 99 99" shape-rendering="crispEdges" style="background-color:#fff;"><path stroke="rgb(',
            _toString(rgbArray[0]),
            ",",
            _toString(rgbArray[1]),
            ",",
            _toString(rgbArray[2]),
            ')" d="M49 49h1" /></svg>'
        ));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Pixel Deed #',
            _toString(tokenId),
            '","attributes": [ { "trait_type": "R", "value": "',
            _toString(rgbArray[0]),
            '" },{ "trait_type": "G", "value": "',
            _toString(rgbArray[1]),
            '" },{ "trait_type": "B", "value": "',
            _toString(rgbArray[2]),
            '" }], "description": "Ethereum-secured proof of ownership for pixel #',
            _toString(tokenId),
            '.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        ))));
       
        string memory generatedURI = string(abi.encodePacked('data:application/json;base64,', json));

        return generatedURI;

    }


    function setNotaryState(bool _state) external onlyOwner {
        notaryIsActive = _state;
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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