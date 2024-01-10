// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721A.sol";

contract CybonixDrones is ERC721A, Ownable {
	using Strings for uint256;
    event airDropped(uint256 count, address recipient);
    string private _realBaseURI;
	uint256 _maxSupplyCount;

    constructor(uint256 maxSupplyCount)  ERC721A("Cybonix Drones", "CBD75"){
		_maxSupplyCount = maxSupplyCount;
    }
	
    function airdropMultipleRecipients(address[] memory recipients) external onlyOwner() {
		require(recipients.length > 0 && recipients.length <= _maxSupplyCount, "Invalid count.");
		require((totalSupply() + recipients.length) <= _maxSupplyCount, "Exceeding supply count.");
		
        for (uint256 i = 0; i < recipients.length; i++) {
			airdrop(1, recipients[i]);
		}
	}

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        _realBaseURI = newBaseURI;
    }

    function airdrop(uint256 count, address recipient) public onlyOwner() {
		require(count > 0 && count <= _maxSupplyCount, "Invalid count.");
		require((totalSupply() + count) <= _maxSupplyCount, "Exceeding supply count.");
		
        _safeMint(recipient, count);

        emit airDropped(count, recipient);
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _realBaseURI;
    }
}
