pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract EAA is ERC721A, Ownable {
	string public baseTokenURI;
	bool public saleActive;
	uint256 price = 0.03 ether;
	uint256 public constant MAX_SUPPLY = 4_444;
	uint256 public maxMint = 10;

	address constant w1 = 0x31b0D9C20A03ca9E71B4Ed9B1a0979C8ce255848;
	address constant w2 = 0xE2C2FC250270C60f7254bA8D73253bf2B5850be7;

	constructor() ERC721A("Elite Army Apes", "EAA") {}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function mintReserve(uint256 quantity, address receiver) external onlyOwner {
		require(totalSupply() + quantity <= MAX_SUPPLY, "Out of supply");
		_safeMint(receiver, quantity);
	}

	function setSaleStatus(bool _status) external onlyOwner {
		saleActive = _status;
	}

	function setMaxMint(uint256 _max) external onlyOwner {
		maxMint = _max;
	}

	function setPrice(uint256 _price) external onlyOwner {
		price = _price;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		baseTokenURI = baseURI;
	}

	function freeMint() external {
		require(saleActive == true, "sale not active");
		require(totalSupply() < 500, "Out of free supply");
		_safeMint(msg.sender, 1);
	}

	function buy(uint256 amount) external payable {
		require(saleActive == true, "sale not active");
		require(amount <= maxMint, "Exceeds number");
		require(totalSupply() + amount + 1 <= MAX_SUPPLY, "Out of supply");
		require(msg.value >= price * amount, "Value below price");
		_safeMint(msg.sender, amount + 1);
	}

	function withdrawAll() public payable onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0);
		_widthdraw(w1, (balance * 85) / 100);
		_widthdraw(w2, address(this).balance);
	}

	function _widthdraw(address _address, uint256 _amount) private {
		(bool success, ) = _address.call{ value: _amount }("");
		require(success, "Transfer failed.");
	}

	/// @notice Prefix for tokenURI return values.

	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}
}
