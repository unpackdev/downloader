// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

import "./ERC721I.sol";
import "./TinyOwnable.sol";
import "./TinyWithdraw.sol";

abstract contract Security {
	modifier onlySender() {
		require(tx.origin == msg.sender, "The caller is another contract");
		_;
	}
}

contract OCYC is Ownable, ERC721I, Withdraw, Security {
	uint256 public maxSupply = 5000;
	bool public mintIsActive;
	uint256 public maxMintsPerWallet = 100;
	uint256 public maxMintsPerTx = 20;
	uint256 public maxFreeMints = 500;
	uint256 public price = 0.005 ether;

	constructor() ERC721I("Okay Casino Yatch Club", "OCYC") {}

	modifier mintConstraints(uint256 quantity) {
		_constrains(quantity);
		_;
	}

	function _constrains(uint256 quantity) private view {
		require(mintIsActive, "Mint not ready");
		require(quantity >= 1 && quantity <= maxMintsPerTx, "Invalid Quantity");
		require(balanceOf[msg.sender] < maxMintsPerWallet, "Limit Reached");
		require(maxSupply > totalSupply, "Sold out");
	}

	function _mintLoop(address target, uint256 quantity) internal {
		uint256 startId = totalSupply + 1;
		for (uint256 i = 0; i < quantity; i++) {
			_mint(target, startId + i);
		}
		totalSupply += quantity;
	}

	function freeMint(uint256 quantity)
		external
		onlySender
		mintConstraints(quantity)
	{
		require(totalSupply < maxFreeMints, "No more free mints");
		_mintLoop(msg.sender, quantity);
	}

	function mint(uint256 quantity)
		external
		payable
		onlySender
		mintConstraints(quantity)
	{
		require(msg.value >= price * quantity, "Not correct ether");
		_mintLoop(msg.sender, quantity);
	}

	function adminMint(uint256 quantity, address _target) external onlyOwner {
		require(maxSupply >= totalSupply + quantity, "Sold out");
		_mintLoop(_target, quantity);
	}

	function setBaseTokenURI(string memory baseURI) external onlyOwner {
		_setBaseTokenURI(baseURI);
	}

	function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
		_setBaseTokenURI_EXT(ext_);
	}

	function toggleSale() external onlyOwner {
		mintIsActive = !mintIsActive;
	}

	function updatePrice(uint256 _price) external onlyOwner {
		price = _price;
	}

	function updateContractVariables(
		uint256 _maxMintsPerWallet,
		uint256 _maxMintsPerTx,
		uint256 _maxFreeMints,
		uint256 _price
	) external onlyOwner {
		maxMintsPerWallet = _maxMintsPerWallet;
		maxMintsPerTx = _maxMintsPerTx;
		maxFreeMints = _maxFreeMints;
		price = _price;
	}
}
