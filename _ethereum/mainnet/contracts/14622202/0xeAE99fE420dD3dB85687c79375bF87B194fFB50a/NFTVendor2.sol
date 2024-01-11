// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "Address.sol";
import "IERC20.sol";
import "IERC721SafeMint.sol";

contract NFTVendor2 is Ownable {
	using Address for address payable;

	IERC20 public silver;
	IERC20 public gold;
	address payable public holding;
	address public auth;

	IERC721SafeMint public token;
	uint256 public saleEnd;

	uint256 public priceEth;
	uint256 public priceSilver;
	uint256 public priceGold;

	bool public saleActive;
	uint256 private _saleStart;

	bool public whitelistEnabled;
	bool public freeMintingEnabled;
	mapping(address => bool) public freeMinters;

	uint256 public maxPerAccount = 999999999;
	mapping(address => uint256) public purchased; // TODO make private and make a getter
	mapping(address => uint256) private lastPurchaseSale;

	constructor(address tokenAddress, address silverAddress, address goldAddress, address payable holdingAddress, address authWallet) {
		token = IERC721SafeMint(tokenAddress);
		silver = IERC20(silverAddress);
		gold = IERC20(goldAddress);
		holding = holdingAddress;
		auth = authWallet;
	}

	// ADMINISTRATIVE

	function beginSale(uint256 amount, uint256 maxPerUser) public onlyOwner {
		saleActive = true;
		saleEnd = token.totalSupply() + amount;
		maxPerAccount = maxPerUser;
		_saleStart = block.timestamp;
	}

	function addToSale(uint256 amount) public onlyOwner {
		saleEnd += amount;
	}

	function endSale() public onlyOwner {
		saleActive = false;
	}

	function addFreeMinter(address user) public onlyOwner {
		freeMinters[user] = true;
	}

	function addFreeMinters(address[] calldata users) public onlyOwner {
		for (uint i = 0; i < users.length; i++)
			freeMinters[users[i]] = true;
	}

	// PURCHASE

	function _buy(address account, uint256 amount, uint8 v, bytes32 r, bytes32 s, uint256 timestamp) internal {
		require(saleActive, "No sale currently active.");
		require(token.totalSupply() + amount <= saleEnd, "Not enough NFTs available to purchase.");
		if (whitelistEnabled) {
			require(block.timestamp < timestamp + 10 minutes, "Signature expired");
			bytes32 hash = keccak256(abi.encode("NFTVendor2_buy", _msgSender(), timestamp));
			address signer = ecrecover(hash, v, r, s);
			require(signer == auth, "Invalid signature");
		}

		uint256 totalBought = amount;
		if (lastPurchaseSale[account] == _saleStart)
			totalBought += purchased[account];
		require(totalBought <= maxPerAccount, "Overrunning max purchases per account.");
		purchased[account] = totalBought;
		if (lastPurchaseSale[account] != _saleStart)
			lastPurchaseSale[account] = _saleStart;

		token.safeMint(_msgSender(), amount);
	}

	function freeMint(uint8 v, bytes32 r, bytes32 s, uint256 timestamp) public {
		require(freeMintingEnabled, "Free minting is not enabled.");
		require(freeMinters[_msgSender()], "No free mints available for this address.");
		_buy(_msgSender(), 1, v, r, s, timestamp);
		freeMinters[_msgSender()] = false;
	}

	function buyWithSilver(uint256 amount, uint8 v, bytes32 r, bytes32 s, uint256 timestamp) public {
		require(priceSilver != 0, "Purchase with silver disabled.");
		_buy(_msgSender(), amount, v, r, s, timestamp);
		silver.transferFrom(_msgSender(), holding, amount * priceSilver);
	}

	function buyWithGold(uint256 amount, uint8 v, bytes32 r, bytes32 s, uint256 timestamp) public {
		require(priceGold != 0, "Purchase with gold disabled.");
		_buy(_msgSender(), amount, v, r, s, timestamp);
		gold.transferFrom(_msgSender(), holding, amount * priceGold);
	}

	function buyWithEth(uint256 amount, uint8 v, bytes32 r, bytes32 s, uint256 timestamp) public payable {
		require(priceEth != 0, "Purchase with eth disabled.");
		require(msg.value == amount * priceEth, "Incorrect payment.");
		_buy(_msgSender(), amount, v, r, s, timestamp);
		// being careful about reentrancy shenanigans
		holding.sendValue(msg.value);
	}

	// SETTERS

	function setToken(address tokenAddress) public onlyOwner {
		token = IERC721SafeMint(tokenAddress);
	}

	function setHoldingAddress(address payable holdingAddress) public onlyOwner {
		holding = holdingAddress;
	}

	function setAuthWallet(address authWallet) public onlyOwner {
		auth = authWallet;
	}

	function setPrices(uint256 silverPrice, uint256 goldPrice, uint256 ethPrice) public onlyOwner {
		priceSilver = silverPrice;
		priceGold = goldPrice;
		priceEth = ethPrice;
	}

	function setSilverPrice(uint256 price) public onlyOwner {
		priceSilver = price;
	}

	function setGoldPrice(uint256 price) public onlyOwner {
		priceGold = price;
	}

	function setEthPrice(uint256 price) public onlyOwner {
		priceEth = price;
	}

	function setWhitelistStatus(bool status) public onlyOwner {
		whitelistEnabled = status;
	}

	function setFreeMintStatus(bool status) public onlyOwner {
		freeMintingEnabled = status;
	}

	function setMaxPerAccount(uint256 max) public onlyOwner {
		maxPerAccount = max;
	}
}
