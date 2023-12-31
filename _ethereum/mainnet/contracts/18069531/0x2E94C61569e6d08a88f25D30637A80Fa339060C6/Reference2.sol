// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract Reference2 is ERC721, Ownable {
	event MetadataUpdate(uint256 _tokenId);

	string private _image = "";

	constructor(address wallet) ERC721("Reference2", "RFR2") {
		_mint(wallet, 1);
	}

	function totalSupply() public pure returns (uint256) {
		return 1;
	}

	function updateReference(string memory newImage) public onlyOwner {
		_image = newImage;
		emit MetadataUpdate(1);
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		if (!_exists(tokenId)) revert("Nonexistent token");
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(abi.encodePacked('{"name":"That Camera","image":"', _image, '"}'))
				)
			);
	}
}
