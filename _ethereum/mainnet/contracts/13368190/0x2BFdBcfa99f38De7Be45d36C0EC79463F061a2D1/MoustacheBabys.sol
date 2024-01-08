/**
* Moustache Babys is collection is a collection of 1000  babys on the Ethereum Blockchain. 
* Each Baby in our collection is unique.
* WEbsite: https://moustachebabys.com/

*/
// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";



contract MoustacheBabys is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	uint256 public totalTokensToMint = 1000;

	bool public isMintingActive = false;

	bool public instantRevealActive = false;
	uint256 public tokenIndex = 0;
	uint256 public totalGiveaways = 0;


	mapping(uint256 => uint256) public claimedPerID;

	uint256 public pricePerNFT = 60000000000000000; //0.06 ETH

	string private _baseTokenURI = "https://moustachebabys.com/api/";
	string private _contractURI = "ipfs://QmQzbvbg6B7EM4Vs3P7DisJxNkMcB8ydJcnMBKWiT2DgKA";

	

	constructor() ERC721("Moustache Babys", "MB") {}

	
	function buy(uint256 amount) public payable nonReentrant {
		require(amount <= 10, "max 10 tokens");
		require(amount > 0, "minimum 1 token");
		require(amount <= totalTokensToMint - tokenIndex, "greater than max supply");
		require(isMintingActive, "minting is not active");
		require(pricePerNFT * amount == msg.value, "exact value in ETH needed");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	
	function giveawaysMint(uint256 amount, address _to) public onlyOwner {
		totalGiveaways = totalGiveaways + amount;
		require(amount <= totalTokensToMint - tokenIndex, "amount is greater than the token available");
		require(totalGiveaways <= 100, "giveaways is finished");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_to);
		}

	}

	
	function _mintToken(address _to) private {
		tokenIndex++;
		require(!_exists(tokenIndex), "Token already exist.");
		_safeMint(_to, tokenIndex);
	}


	function tokensOfOwner(
		address _owner,
		uint256 _start,
		uint256 _limit
	) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = _start; index < _limit; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	
	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	

	//@dev toggle instant Reveal
	function stopInstantReveal() external onlyOwner {
		instantRevealActive = false;
	}

	function startInstantReveal() external onlyOwner {
		instantRevealActive = true;
	}

	//toggle minting
	function stopMinting() external onlyOwner {
		isMintingActive = false;
	}

	//toggle minting
	function startMinting() external onlyOwner {
		isMintingActive = true;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	//used by admin to lower the total supply [only owner]
	function lowerTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		require(_newTotalSupply < totalTokensToMint, "you can only lower it");
		totalTokensToMint = _newTotalSupply;
	}
	
	function setPricePerNFT(uint256 _pricePerNFT) public onlyOwner {
		pricePerNFT = _pricePerNFT;
	}


 	// [only owner]
	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// [only owner]
	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	
}