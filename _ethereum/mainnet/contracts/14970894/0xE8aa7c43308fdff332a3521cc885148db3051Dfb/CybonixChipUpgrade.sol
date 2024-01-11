// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./strings.sol";
import "./ERC721AQueryable.sol";
import "./ERC721A.sol";

contract CybonixChipUpgrade is ERC721A, ERC721AQueryable, Ownable {
	using Strings for uint256;
    string private _realBaseURI;
	bool private _paused = false;
	
    constructor()  ERC721A("Cybonix Chip Upgrade", "CBXNC"){
		
    }
	
    function airdropMultiple(address[] memory recipients) external onlyOwner() {
		require(recipients.length > 0, "Invalid count.");
		
        for (uint256 i = 0; i < recipients.length; i++) {
			airdrop(1, recipients[i]);
		}
	}

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        _realBaseURI = newBaseURI;
    }

	function paused() public view virtual returns (bool) {
        return _paused;
    }
	
    function pause() external onlyOwner() {
        _paused = true;
    }

    function unpause() external onlyOwner() {
        _paused = false;
    }

    function airdrop(uint256 count, address recipient) public onlyOwner() {
		require(count > 0, "Invalid count.");
		
        _safeMint(recipient, count);
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _realBaseURI;
    }
	
	function _startTokenId() internal pure override returns (uint256) {
      return 1;
    }
	
	function _beforeTokenTransfers(address from,
								   address to,
								   uint256 startTokenId,
								   uint256 quantity) internal virtual override { 
		super._beforeTokenTransfers(from,
								    to,
								    startTokenId,
								    quantity);
									
		require(_paused == false, "Contract paused.");
	}
}
