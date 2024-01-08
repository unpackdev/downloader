// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./console.sol";

import "./MinterRole.sol";

contract RiddleKey is ERC1155, Ownable, MinterRole {
	using SafeMath for uint;
	uint256 public constant WOODEN = 1;
	uint256 public constant IRON = 2;
	uint256 public constant SILVER = 3;
	uint256 public constant GOLD = 4;
	uint256 public constant DIAMOND = 5;

	uint256 public constant WOODEN_MAX_SUPPLY = 1000;
	uint256 public constant IRON_MAX_SUPPLY = 500;
	uint256 public constant SILVER_MAX_SUPPLY = 125;
	uint256 public constant GOLD_MAX_SUPPLY = 25;
	uint256 public constant DIAMOND_MAX_SUPPLY = 1;

	mapping(uint256 => mapping (uint256 => bytes32)) private _tokenKeyByLevel;    // key store for amount of tokens by level. tokenId => index => key

	mapping(uint => uint) private _maxSupplyByLevel;
	mapping(uint => uint) private _currentSupplyByLevel;   // the number of keys that sold out on the particular level
	mapping(uint => uint) private _tokenLevel;             // the level of the token. token => level
	mapping(uint32 => uint) private _tokenOfLevel;           // the token of the level. level => token

	constructor() public ERC1155('http://localhost:4000/nfts/') {
		_initialize();
	}

	function initialize() external onlyOwner {
		_initialize();
	}

	function _initialize() private {
		_burn(msg.sender, WOODEN, balanceOf(msg.sender, WOODEN));
		_burn(msg.sender, IRON, balanceOf(msg.sender, IRON));
		_burn(msg.sender, SILVER, balanceOf(msg.sender, SILVER));
		_burn(msg.sender, GOLD, balanceOf(msg.sender, GOLD));
		_burn(msg.sender, DIAMOND, balanceOf(msg.sender, DIAMOND));
		_mint(msg.sender, WOODEN, WOODEN_MAX_SUPPLY, '');
		_mint(msg.sender, IRON, IRON_MAX_SUPPLY, '');
		_mint(msg.sender, SILVER, SILVER_MAX_SUPPLY, '');
		_mint(msg.sender, GOLD, GOLD_MAX_SUPPLY, '');
		_mint(msg.sender, DIAMOND, DIAMOND_MAX_SUPPLY, '');

		_tokenLevel[WOODEN] = 1;
		_tokenLevel[IRON] = 2;
		_tokenLevel[SILVER] = 3;
		_tokenLevel[GOLD] = 4;
		_tokenLevel[DIAMOND] = 5;

		_tokenOfLevel[1] = WOODEN;
		_tokenOfLevel[2] = IRON;
		_tokenOfLevel[3] = SILVER;
		_tokenOfLevel[4] = GOLD;
		_tokenOfLevel[5] = DIAMOND;

		_maxSupplyByLevel[WOODEN] = WOODEN_MAX_SUPPLY;
		_maxSupplyByLevel[IRON] = IRON_MAX_SUPPLY;
		_maxSupplyByLevel[SILVER] = SILVER_MAX_SUPPLY;
		_maxSupplyByLevel[GOLD] = GOLD_MAX_SUPPLY;
		_maxSupplyByLevel[DIAMOND] = DIAMOND_MAX_SUPPLY;

		_currentSupplyByLevel[_tokenOfLevel[1]] = 0;
		_currentSupplyByLevel[_tokenOfLevel[2]] = 0;
		_currentSupplyByLevel[_tokenOfLevel[3]] = 0;
		_currentSupplyByLevel[_tokenOfLevel[4]] = 0;
		_currentSupplyByLevel[_tokenOfLevel[5]] = 0;
	}

	/**
	* @dev transfer 1 of token
	*/
	function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyOwner {
		require(_currentSupplyByLevel[_tokenLevel[tokenId]] < _maxSupplyByLevel[_tokenLevel[tokenId]], 'Key limit reached');
		require(balanceOf(to, tokenId) < 1, 'One wallet should have only one Key');

		ERC1155.safeTransferFrom(from, to, tokenId, amount, data);
		_currentSupplyByLevel[_tokenLevel[tokenId]] = _currentSupplyByLevel[_tokenLevel[tokenId]].add(amount);
	}

	function mint(address _to, uint _tokenId, uint _level, uint _count, string memory _key) external onlyMinter {
	    _mint(_to, _tokenId, _count, '');
	    _tokenLevel[_tokenId] = _level;
	}

	function setBaseURI(string memory baseURI) external onlyOwner {
		_setURI(baseURI);
	}

	/**
	* @dev allow token holders to destroy their own token
	*/
	// function burn(address account, uint256 id, uint256 value) external virtual {
	//     require(
	//         account == _msgSender() || isApprovedForAll(account, _msgSender()),
	//         "ERC1155: caller is not owner nor approved"
	//     );

	//     _burn(account, id, value);
	// }

	// function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external virtual {
	//     require(
	//         account == _msgSender() || isApprovedForAll(account, _msgSender()),
	//         "ERC1155: caller is not owner nor approved"
	//     );

	//     _burnBatch(account, ids, values);
	// }

	function addMinter(address _minter) public override onlyOwner {
		_addMinter(_minter);
	}

	function maxSupplyOf(uint _level) public view returns (uint) {
		return _maxSupplyByLevel[_level];
	}

	function currentSupplyOf(uint _level) public view returns (uint) {
		return _currentSupplyByLevel[_level];
	}

	function levelOf(uint _tokenId) public view returns (uint) {
		return _tokenLevel[_tokenId];
	}

	function tokenOf(uint32 level) public view returns (uint) {
		return _tokenOfLevel[level];
	}

	/**
		* @dev Transfers ownership of the contract to a new account (`newOwner`).
		* Can only be called by the current owner.
		*/
	function transferOwnership(address newOwner) public override onlyOwner {
		ERC1155.safeTransferFrom(owner(), newOwner, WOODEN, balanceOf(owner(), WOODEN), '');
		ERC1155.safeTransferFrom(owner(), newOwner, IRON, balanceOf(owner(), IRON), '');
		ERC1155.safeTransferFrom(owner(), newOwner, SILVER, balanceOf(owner(), SILVER), '');
		ERC1155.safeTransferFrom(owner(), newOwner, GOLD, balanceOf(owner(), GOLD), '');
		ERC1155.safeTransferFrom(owner(), newOwner, DIAMOND, balanceOf(owner(), DIAMOND), '');
		Ownable.transferOwnership(newOwner);
	}
}
