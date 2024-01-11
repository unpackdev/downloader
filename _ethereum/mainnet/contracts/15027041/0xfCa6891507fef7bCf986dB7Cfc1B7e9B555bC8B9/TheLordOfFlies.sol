// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

import "./Strings.sol";
import "./SafeMath.sol";

struct ContractInfo {
	string name;
	string symbol;
}

struct MintInfo {
	bool ownerMintUnrestricted;
	uint256 mintPrice;
	uint256 maxSupply;
	uint256 freeQuantity;
	uint256 singleAddressLimitQuantity;
}

struct WithdrawInfo {
	address withdrawAddress;
}

contract TheLordOfFlies is ERC721A, Ownable, Pausable {
	using Strings for uint256;
	using SafeMath for uint256;

	string baseTokenURI;

	MintInfo mintInfo;
	WithdrawInfo withdrawInfo;
	address immutable proxyRegistryAddress;

	constructor(
		ContractInfo memory _contractInfo,
		MintInfo memory _mintInfo,
		WithdrawInfo memory _withdrawInfo,
		address _proxyRegistryAddress,
		string memory _baseTokenURI
	) ERC721A(_contractInfo.name, _contractInfo.symbol) {
		proxyRegistryAddress = _proxyRegistryAddress;
		mintInfo = _mintInfo;
		withdrawInfo = _withdrawInfo;
		baseTokenURI = _baseTokenURI;
	}

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "Must from real wallet address");
		_;
	}

	function mint(uint256 _quantity) external callerIsUser payable whenNotPaused {
		uint256 _hasMinted = totalSupply();
		uint256 _currentMintedCount = balanceOf(msg.sender);

		uint256 _remainFreeQuantity = 0;
		if (mintInfo.freeQuantity > _hasMinted) {
			_remainFreeQuantity = mintInfo.freeQuantity - _hasMinted;
		}
		
		uint256 _needPayPrice = 0;
		if (_quantity > _remainFreeQuantity) {
			_needPayPrice = (_quantity - _remainFreeQuantity) * mintInfo.mintPrice;
		}

		require(_quantity > 0, "Invalid quantity");
		require(_hasMinted + _quantity <= mintInfo.maxSupply, "Exceed supply");
		require(_currentMintedCount + _quantity <= mintInfo.singleAddressLimitQuantity, "Exceed mint limit");
		require(msg.value >= _needPayPrice, "Ether is not enough");

		_mint(msg.sender, _quantity);
	}

	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	function _baseURI() internal view override returns (string memory) {
		return baseTokenURI;
	}

	function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
		baseTokenURI = _baseTokenURI;
	}

	function openMint() public onlyOwner {
		_unpause();
	}

	function closeMint() public onlyOwner {
		_pause();
	}

	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool)
	{
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		return proxyRegistryAddress == operator || address(proxyRegistry.proxies(owner)) == operator || super.isApprovedForAll(owner, operator);
	}

	function setWithdrawAddress(address _address) external onlyOwner {
		withdrawInfo.withdrawAddress = _address;
	}

	function withdraw() external callerIsUser {
		require(msg.sender == withdrawInfo.withdrawAddress || msg.sender == owner(), 'Has not Permission');
		require(
			payable(withdrawInfo.withdrawAddress).send(address(this).balance),
			"Withdraw fail"
		);
	}
}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}
