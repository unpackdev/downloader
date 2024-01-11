// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";

contract GGhorseNFT is ERC721A, Ownable, ReentrancyGuard {  
    using Strings for uint256; 
    string public _basehorse = 'https://gateway.pinata.cloud/ipfs/QmRCHQZPTt1myEcGQQzHgo74PtXupr6VYf4ESbuchNErtG/';
    bool public byebye = false;
    uint256 public horses = 5000;
    uint256 public horsebyebye = 1; 
    mapping(address => uint256) public sellhorse;
		
	constructor() ERC721A("GGWorld Horse", "GGHORSE", 1000) {}

	function _baseURI() internal view virtual override returns (string memory) {
			return _basehorse;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_basehorse, _tokenId.toString(), ".json"));
	}

 	function freehorse() external nonReentrant {
			uint256 totalhorse = totalSupply();
			require(byebye);
			require(totalhorse + horsebyebye <= horses);
			require(msg.sender == tx.origin);
			require(sellhorse[msg.sender] < horsebyebye);
			_safeMint(msg.sender, horsebyebye);
			sellhorse[msg.sender] += horsebyebye;
	}

 	function makehorserun(address lords, uint256 _horses) public onlyOwner {
			uint256 totalhorse = totalSupply();
	    require(totalhorse + _horses <= horses);
			_safeMint(lords, _horses);
	}

	function makehorsegobyebye(bool _bye) external onlyOwner {
			byebye = _bye;
	}

	function spredhorse(uint256 _byebye) external onlyOwner {
			horsebyebye = _byebye;
	}

	function makehorsehaveparts(string memory parts) external onlyOwner {
			_basehorse = parts;
	}

	function sumthinboutfunds() public payable onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
			require(success);
	}
}