// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";


interface IERC20 {

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


//_________  ________  ___  ___       ___       ________  _______   _______   ___  __    ________
//|\___   ___\\   __  \|\  \|\  \     |\  \     |\   ____\|\  ___ \ |\  ___ \ |\  \|\  \ |\   ____\
//\|___ \  \_\ \  \|\  \ \  \ \  \    \ \  \    \ \  \___|\ \   __/|\ \   __/|\ \  \/  /|\ \  \___|_
//     \ \  \ \ \   _  _\ \  \ \  \    \ \  \    \ \  \  __\ \  \_|/_\ \  \_|/_\ \   ___  \ \_____  \
//      \ \  \ \ \  \\  \\ \  \ \  \____\ \  \____\ \  \|\  \ \  \_|\ \ \  \_|\ \ \  \\ \  \|____|\  \
//       \ \__\ \ \__\\ _\\ \__\ \_______\ \_______\ \_______\ \_______\ \_______\ \__\\ \__\____\_\  \
//        \|__|  \|__|\|__|\|__|\|_______|\|_______|\|_______|\|_______|\|_______|\|__| \|__|\_________\
//                                                                                          \|_________|


contract TrillGeeks is ERC1155, Ownable {

	using SafeMath for uint256;
	using Strings for string;
	uint256 public mintedAssets;

	// useful info
	string public _baseURI = "https://trillgeeks.s3.us-east-2.amazonaws.com/j/";
	string public _contractURI = "";
	bool public sellStart = false;
	uint256 public totalSupplyCount = 3000;
	uint256 public maxMintPerBatch = 100;

	mapping(uint256 => string) public _tokenURIs;

	uint256 public itemPrice;

	constructor() ERC1155(_baseURI) {
		itemPrice = 30000000000000000; // 0.03 ETH
	}

	function setItemPrice(uint256 _price) public onlyOwner {
		itemPrice = _price;
	}

	function getItemPrice() public view returns (uint256) {
		return itemPrice;
	}

	function safeMint() public payable {
		require(sellStart == true, "Wait for sales to start!");
		require(msg.value >= itemPrice, "insufficient ETH");
		require(mintedAssets < totalSupplyCount, "All Assets has been minted!");
		mintedAssets = mintedAssets + 1;
		_mint(msg.sender, mintedAssets, 1, "0x0000");
	}

	function safeMintBatch(uint256 _count) public payable {
		require(sellStart == true, "Wait for sales to start!");
		require(itemPrice.mul(_count) >= msg.value, "insufficient ETH");
		require(_count <= maxMintPerBatch, "100 is a limit");
		require(mintedAssets + _count <= totalSupplyCount, "All Assets has been minted!");
		for (uint256 i = 0; i < _count; i++) {
			mintedAssets = mintedAssets + 1;
			_mint(msg.sender, mintedAssets, 1, "0x0000");
		}
	}

	function mintBatch(address to, uint256 _count) public onlyOwner {
		require(mintedAssets + _count <= totalSupplyCount, "All Assets has been minted!");
		for (uint256 i = 0; i < _count; i++) {
			mint(to);
		}
	}

	function mint(address to) public onlyOwner {
		require(mintedAssets < totalSupplyCount, "All Assets has been minted!");
		mintedAssets = mintedAssets + 1;
		_mint(to, mintedAssets, 1, "0x0000");
	}


	function setBaseURI(string memory _newUri) public onlyOwner {
		_baseURI = _newUri;
	}

	function setSellStart(bool f) public onlyOwner {
		sellStart = f;
	}

	function getSellStart() public view returns (bool) {
		return sellStart;
	}

	function setContractURI(string memory _newUri) public onlyOwner {
		_contractURI = _newUri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}



	// utility functions
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

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
}
