// SPDX-License-Identifier: MIT
/*                
/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//     ________  __                        __                 __           //
//    |        \|  \                      |  \               |  \          //
//     \$$$$$$$$| $$____    ______        | $$       ______  | $$____      //
//       | $$   | $$    \  /      \       | $$      |      \ | $$    \     //
//       | $$   | $$$$$$$\|  $$$$$$\      | $$       \$$$$$$\| $$$$$$$\    //
//       | $$   | $$  | $$| $$    $$      | $$      /      $$| $$  | $$    //
//       | $$   | $$  | $$| $$$$$$$$      | $$_____|  $$$$$$$| $$__/ $$    //
//       | $$   | $$  | $$ \$$     \      | $$     \\$$    $$| $$    $$    //
//        \$$    \$$   \$$  \$$$$$$$       \$$$$$$$$ \$$$$$$$ \$$$$$$$     //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////            
*/

pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Lab is ERC721A, Ownable {
	using Strings for uint256;

    string public BASE_URI = "ipfs://QmchjNBDQjhZBSV7X9k1AfYHzW9wjSdPCTQZQSzsfPsja7/";
	string public TOKEN_URI_SUFFIX = ".json";

    constructor() ERC721A("The Lab: Scientists", "LAB") Ownable(0x5096Efb5cb8742D6eCE0F3dfbcfb5f8C15f3590b) {
		_mint(owner(), 200);
	}

    function setBaseUri(string memory uri) public onlyOwner {
        BASE_URI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }
	
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
	{
		require(_exists(tokenId), "query for nonexistent token");
		return string(abi.encodePacked(BASE_URI, tokenId.toString(), TOKEN_URI_SUFFIX));
	}
}