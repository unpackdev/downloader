// SPDX-License-Identifier: none

pragma solidity ^0.8.13;

import "./Pausable.sol";
import "./Token.sol";
import "./Operable.sol";

contract BMTSeller is Operable, Pausable {
	address public immutable token;

	mapping(uint256 => uint256) public tokens;
	uint256 public tokensCount;
	uint256[] public tokensSold;

	uint256 public price;
	address public wallet;

	constructor(
		address _token,
		uint256 _tokensCount,
		uint256 _price,
		address _wallet
	) Operable(_msgSender()) {
		token = _token;
		tokensCount = _tokensCount;

		setPrice(_price);
		setWallet(_wallet);

		setPause(true);
	}

	function setPrice(uint256 _price) public onlyOperator {
		price = _price;
		emit SetPrice(price);
	}

	function setWallet(address _wallet) public onlyOperator {
		wallet = _wallet;
		emit SetWallet(_wallet);
	}

	function setPause(bool state) public onlyOperator {
		state ? _pause() : _unpause();
	}

	function available(uint256 from, uint256 to) public view returns (uint256[] memory _available) {
		_available = new uint256[](to - from);
		uint256 idx;
		for (uint256 i = from; i < to; i++) {
			if (tokens[i] == 0) {
				_available[idx] = i;
			} else {
				_available[idx] = tokens[i];
			}
			idx++;
		}
	}

	function sold(uint256 from, uint256 to) public view returns (uint256[] memory _sold) {
		_sold = new uint256[](to - from + 1);
		uint256 idx;
		for (uint256 i = from; i <= to; i++) {
			_sold[idx] = tokensSold[i];
			idx++;
		}
	}

	function contractData()
		public
		view
		returns (
			uint256 _price,
			uint256 _tokensCount,
			uint256 _sold,
			bool _paused
		)
	{
		_price = price;
		_tokensCount = tokensCount;
		_sold = tokensSold.length;
		_paused = paused();
	}

	function buy() public payable whenNotPaused returns (uint256 tokenId_) {
		require(msg.sender.code.length == 0, "Only humans");
		require(msg.value == price, "Not enough funds");

		require(tokensCount != 0, "All tokens minted");

		uint256 random = uint256(
			keccak256(abi.encodePacked(
				block.timestamp + 
				block.difficulty + 
				((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) + 
				block.gaslimit + 
				((uint256(keccak256(abi.encodePacked(msg.sender)))) / block.timestamp) + 
				block.number + 
				tokensCount
			))
		);
		uint256 tokenIndex = (random % tokensCount) + 1;

		if (tokens[tokenIndex] == 0) {
			tokenId_ = tokenIndex;
		} else {
			tokenId_ = tokens[tokenIndex];
		}

		if (tokens[tokensCount] == 0) {
			tokens[tokenIndex] = tokensCount;
		} else {
			tokens[tokenIndex] = tokens[tokensCount];
		}

		tokensCount--;
		tokensSold.push(tokenId_);

		IToken(token).mint(msg.sender, tokenId_);

		(bool success, ) = wallet.call{ value: price }("");
		require(success, "Can't sent to wallet");
	}

	event SetPrice(uint256 price);
	event SetWallet(address wallet);
}
