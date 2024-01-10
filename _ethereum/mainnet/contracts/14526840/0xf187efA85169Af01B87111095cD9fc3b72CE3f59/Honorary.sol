// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Honorary is Ownable, ERC721A {
	
    using Strings for uint256;
	
	constructor() ERC721A("LighttheNight_Honorary_Collection", "Hikari.H", 100, 9999) {}

	function mint(address account, uint256 amount) external onlyOwner{
		_safeMint(account, amount);
	}
	
	function withdraw() external {
		uint256 balance = address(this).balance;
        (bool sent, ) = owner().call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

	// // metadata URI
	string private _baseTokenURI;
	
	function tokenURI(uint256 tokenId) public view override returns (string memory){
		require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseTokenURI;
		
		return bytes(baseURI).length > 0 ? 
			string(abi.encodePacked(baseURI, tokenId.toString())) : "";
	}

	function setBaseURI(string calldata baseURI) external onlyOwner {
		_baseTokenURI = baseURI;
	}

	function setOwnersExplicit(uint256 quantity) external onlyOwner {
		_setOwnersExplicit(quantity);
	}	

	function numberMinted(address owner) public view returns (uint256) {
		return _numberMinted(owner);
	}

	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
		return ownershipOf(tokenId);
	}
	
	fallback() external payable {}

    receive() external payable {}
}