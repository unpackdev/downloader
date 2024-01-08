// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

contract Minutes is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	string private _baseTokenURI = "https://api.minutesnft.com/metadata/";
	string private _contractURI = "ipfs://QmQ8sE7BLBCTCAQf6Qu78PnrydoSUw55Xpu5j79EczhZAC";

	//toggle the sale
	bool public isSaleActive = false;

	//no more than 1440
	uint256 public constant totalTokenToMint = 1440; //minutes in a day

	//the enumerable part from ERC721Enumerable
	uint256 public tokenIndex = 0;

	//price per token
	uint256 public pricePerToken = 50000000000000000; //0.05 ETH

	constructor() ERC721("MinutesNFT", "MINUTES") {}

	/*
	 * This is how you get one, or more...
	 */
	function mint(uint256 amount) public payable nonReentrant {
		require(amount > 0, "minimum 1 token");
		require(amount <= totalTokenToMint - tokenIndex, "greater than max supply");
		require(isSaleActive, "sale is not active");
		require(amount <= 20, "max 20 tokens at once");
		require(pricePerToken * amount == msg.value, "exact value in ETH needed");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	/*
	 * private mint function
	 */
	function _mintToken(address destinationAddress) private {
		tokenIndex++;
		require(!_exists(tokenIndex), "Token already exist.");
		_safeMint(destinationAddress, tokenIndex);
	}

	/*
	 * Helper functions
	 */
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			// Return an empty array
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
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

	function stopSale() external onlyOwner {
		isSaleActive = false;
	}

	function startSale() external onlyOwner {
		isSaleActive = true;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	/*
	 * Change price
	 */
	function changeItemPrice(uint256 _newPrice) public onlyOwner {
		pricePerToken = _newPrice;
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}
