// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OriginWarp is ERC721, ERC721Enumerable, Ownable {
	
	using Strings for uint256;
	string _baseTokenURI;
	uint256 private _reserved = 300;
	uint256 public totalMinted;
	bool public _paused = false;
	mapping(address => uint256) public walletMints;
	
	constructor(string memory baseURI) ERC721("Origin Of The Uniwarp", "OUWP") {
		setBaseURI(baseURI);
	}
	
	function mint(uint256 num) public payable {
		uint256 supplyLimit = 5555;
		uint256 supply = totalMinted;
		require(msg.sender == tx.origin, "no bots"); // block smart contracts from minting
		require( !_paused, "Sale paused" );		
		require( supply + num < supplyLimit - _reserved, "Exceeds maximum supply." );
		require( walletMints[msg.sender] + num <= 5, "Exceeds maximum mint per wallet: 5." );
		
		walletMints[msg.sender] += num;		
		totalMinted += num;

		for(uint256 i=1; i < num+1; i++){	
			_safeMint( msg.sender, supply + i );
		}
	}
	
	function walletOfOwner(address _owner) public view returns(uint256[] memory) {	
		uint256 tokenCount = balanceOf(_owner);
		uint256[] memory tokensId = new uint256[](tokenCount);
		for(uint256 i; i < tokenCount; i++){
			tokensId[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokensId;
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}
	
	function giveAway(address _to, uint256 _amount) external onlyOwner() {
		require( _amount <= _reserved, "Exceeds reserved supply" );
		uint256 supply = totalMinted;
		walletMints[_to] += _amount;
		for(uint256 i=1; i < _amount+1; i++){
			_safeMint( _to, supply + i );
		}
		_reserved -= _amount;	
		totalMinted += _amount;
	}
	
	function setBaseURI(string memory baseURI) public onlyOwner {
		_baseTokenURI = baseURI;
	}
	
	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0
			? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
			: '';
	}

	function pause(bool val) public onlyOwner {
		_paused = val;
	}
	
	fallback() external payable { }
	
	receive() external payable { }

	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}