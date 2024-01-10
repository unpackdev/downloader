// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract SkinnyMouse is ERC721, Ownable {
	using Counters for Counters.Counter;
	
	uint256 public constant TOTAL_SUPPLY = 12222;
	address public _recipient;
	uint8 public percentage;
	bool public isMintingAllowed = true;
	uint256 public  mint_price;
	Counters.Counter public currentTokenId;
	string public baseTokenURI;

	constructor() ERC721("SkinnyMouse", "SkinnyMouse") {
		baseTokenURI = "https://bafybeiahchad4tzxsgjbsa5hwific2runycyhycxzigejagcj56vgogwda.ipfs.dweb.link/allMetadata/";
		percentage = 5;
		mint_price = 0.04 ether;
		_recipient = address(this);
	}

	function mintTo(address recipient) external payable returns (uint256) {
		require(currentTokenId._value < TOTAL_SUPPLY, "Max supply reached");
		require (isMintingAllowed == true, "It's not possible to create NFT now");
		require(msg.value >= mint_price, "Not enough Ether in msg.value");

		currentTokenId.increment();
		uint256 newItemId = currentTokenId.current();
		_safeMint(recipient, newItemId);
	return newItemId;
	}

	function setMintingAllowed(bool trueFalse) external onlyOwner {
		isMintingAllowed = trueFalse;
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}
	
	function setNewMintPrice(uint256 newPriceInWei) external onlyOwner {
		mint_price = newPriceInWei;
	}

	function setNewBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
		baseTokenURI = _baseTokenURI;
	}

	function withdrawAllBalance(address payable payee) external onlyOwner {
		payee.transfer(address(this).balance);
	}

	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
	external 
	view 
	returns (address receiver, uint256 royaltyAmount) {
		return (_recipient, (_salePrice * percentage * 100) / 10000);
	}	
	
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
	}

	function setRoyaltiesPercentage(uint8 _newPercentage) external onlyOwner{
		require(_newPercentage < 100, "percentage can't be 100 or more");
		percentage = _newPercentage;
	}

    function setRecipient(address newRecipient) external onlyOwner{
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _recipient = newRecipient;
    }
}