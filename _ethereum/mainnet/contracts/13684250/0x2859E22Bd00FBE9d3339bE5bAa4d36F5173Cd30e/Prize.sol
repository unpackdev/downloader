// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Prize is ERC1155, Ownable {
	uint256 public constant CURRENT_FIRST = 1;
	uint256 public constant CURRENT_SECOND = 2;
	uint256 public constant CURRENT_THIRD = 3;
	uint256 public constant HALL_OF_FAME_FIRST = 4;
	uint256 public constant PARTICIPANT = 5;

	string public constant name = "PAY.GAME";
	string public constant symbol = "PAY";

	address public game;
	string private _contractURI;

	constructor(string memory tokenURI, string memory myContractURI) ERC1155(tokenURI) {
		_contractURI = myContractURI;
	}

	// https://docs.opensea.io/docs/contract-level-metadata
	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	// Set game contract. Cannot be changed once set
	function setGame(address _game) public onlyOwner {
		require(game == address(0), "Game is already set");

		game = _game;
	}

	function setTokenURI(string memory tokenURI) public onlyOwner {
		_setURI(tokenURI);
	}

	function setContractURI(string memory myContractURI) public onlyOwner {
		_contractURI = myContractURI;
	}

	// Only the game is allowed to mint tokens
	function mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	)
	public onlyGame
	{
		_mint(to, id, amount, data);
	}

	// Only the game is allowed to mint tokens
	function mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	)
	public onlyGame
	{
		_mintBatch(to, ids, amounts, data);
	}

	// Game is always approved to transfer tokens
	function isApprovedForAll(
		address account,
		address operator
	)
	public view virtual override returns (bool)
	{
		return _msgSender() == game || super.isApprovedForAll(account, operator);
	}

	// Only the game is allowed to transfer CURRENT tokens
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	)
	internal override(ERC1155)
	{
		if(_msgSender() != game) {
			// Verify we're not trying to transfer a non-transferable token
			for (uint256 i = 0; i < ids.length; ++i) {
				uint256 id = ids[i];
				require(id != CURRENT_FIRST, "Cannot transfer #1 place token");
				require(id != CURRENT_SECOND, "Cannot transfer #2 place token");
				require(id != CURRENT_THIRD, "Cannot transfer #3 place token");
			}
		}

		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	modifier onlyGame() {
		require(_msgSender() == game, "Caller is not the game");
		_;
	}
}
