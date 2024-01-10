// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Royalty.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./TicTacDaoGovernor.sol";
import "./IGameLogicProvider.sol";
import "./IMetadataProvider.sol";
import "./GameUtils.sol";
import "./TicTacDaoErrors.sol";

/// @title TicTacDao
contract TicTacDao is ERC721Royalty, TicTacDaoGovernor, IERC721Enumerable {

	/// Event emitted when a game is restarted
	/// @param player The wallet that restarted the game
	/// @param tokenId The token id of the restarted game
	event GameRestarted(address indexed player, uint256 tokenId);

	/// Event emitted when a move is performed
	/// @param player The wallet that performed the move
	/// @param tokenId The token id of the game
	/// @param gameState The resulting status of the game
	/// @param position The position of the move made by the player
	event MovePerformed(address indexed player, uint256 indexed tokenId, uint256 indexed gameState, uint256 position);

	/// @dev Maximum quantity of games that can be minted at once (which includes wallet balance)
	uint256 public constant MAX_MINT_QUANTITY = 3;

	/// @dev Price per move
	uint256 public constant MOVE_PRICE = 0.025 ether;

	/// @dev Refund if a token owner wins the game (equals 4 moves)
	uint256 public constant REFUND_FOR_WIN = MOVE_PRICE * 4;

	/// @dev the IGameLogicProvider to support gameplay
	IGameLogicProvider private _gameLogicProvider;

	/// @dev the IMetadataProvider to support ERC-721 methods
	IMetadataProvider private _metadataProvider;

	/// @dev Checks for re-entrancy
	uint256 private _reentrancyStatus;

	/// @dev Amount released to creator
	uint256 private _released;

	/// @dev Total moves made
	uint256 private _totalMoves;

	/// @dev Game ON!
	/// @param gameLogicProvider The address of the `IGameLogicProvider` contract
	/// @param metadataProvider The address of the `IMetadataProvider` contract
	/// @param initialProposalThreshold The threshold of votes a wallet needs to propose something
	/// @param initialVotingDelay The delay, in blocks, before voting can begin. 1 day is roughly ~6545 blocks
	/// @param initialVotingPeriod The voting period in blocks. 1 week is roughly ~45818 blocks
	/// @param quorumReachedExtension The additional delay, in blocks, of the vote once quorum is reached
	constructor(address gameLogicProvider, address metadataProvider, uint256 initialProposalThreshold, uint256 initialVotingDelay, uint256 initialVotingPeriod, uint64 quorumReachedExtension)
		ERC721("TicTacDao", "TTD")
		TicTacDaoGovernor("TicTacDao", initialVotingDelay, initialVotingPeriod, initialProposalThreshold, 67, quorumReachedExtension) {
		// At the very least, the first vote requires just over 2/3 of the voting power to weigh in
		_gameLogicProvider = IGameLogicProvider(gameLogicProvider);
		_metadataProvider = IMetadataProvider(metadataProvider);
		_setDefaultRoyalty(owner(), 400); // 4%
	}

	/// Returns the current community pot
	function communityPot() external view returns (uint256) {
		uint256 balance = address(this).balance;
		uint256 reserved = _reservedBalance();
		if (balance <= reserved) return 0;
		return balance - reserved;
	}

	/// Starts a new game with the first move randomly made by the contract
	/// @notice Mints a new TicTacDao NFT. Your move...
	/// @param quantity The desired quantity, which takes into account your existing balance of TicTacDao tokens
	/// @dev While the mint is free, the dev wishes to spread minting across as many wallets as possible that are able to participate
	function createGames(uint256 quantity) external nonReentrant {
		uint256 totalQuantity = ERC721.balanceOf(_msgSender()) + quantity;
		if (quantity == 0 || totalQuantity > MAX_MINT_QUANTITY) revert InvalidQuantity();
		if (_msgSender().balance < totalQuantity * 3 * MOVE_PRICE) revert FundsTooLowForGameplay();
		uint256 startingGameId = _gameLogicProvider.createGames(quantity);
		for (uint256 i = startingGameId; i < startingGameId + quantity; i++) {
			_safeMint(_msgSender(), i, "");
		}
	}

	/// @notice For easy import into MetaMask and other wallets
	function decimals() external pure returns (uint8) {
		return 0;
	}

	/// Donates a portion of the community ot to a destination address
	/// @dev The spirit of this function is to do good, or pay for development to update the
	/// @param destination The destination address for the funds
	/// @param amount The amount to donate, which must be less than or equal to the community pot
	function donateCommunityPot(address payable destination, uint256 amount) public onlyGovernance nonReentrant {
		if (amount > this.communityPot()) revert CallNotAllowed();
		Address.sendValue(destination, amount);
	}

	/// Makes a move on the board denoted by `tokenId` using the provided `position`
	/// @dev The underlying code will ensure the tokenId is valid
	/// @param tokenId The token id of the game
	/// @param position The position of the player's next move
	function makeMove(uint256 tokenId, uint256 position) external payable {
		if (_reentrancyStatus > 0) revert NoReentrancy();
		if (_msgSender() != ownerOf(tokenId)) revert GameNotOwned();
		if (msg.value < MOVE_PRICE) revert InvalidPriceSent();
		_totalMoves++;
		ITicTacToe.GameState resultingState = _gameLogicProvider.processMove(tokenId, position);
		if (resultingState == ITicTacToe.GameState.OwnerWon) {
			_reentrancyStatus = 1;
			_transferVotingUnits(address(0), _msgSender(), 1);
			Address.sendValue(payable(_msgSender()), REFUND_FOR_WIN);
			_reentrancyStatus = 0;
		}
		emit MovePerformed(_msgSender(), tokenId, uint256(resultingState), position);
	}

	/// @inheritdoc ERC721
	function name() public view override(ERC721, Governor) returns (string memory) {
		return super.name();
	}

	/// Ensures the function only continues if not already entered
	modifier nonReentrant() {
		if (_reentrancyStatus > 0) revert NoReentrancy();
		_reentrancyStatus = 1;
		_;
		_reentrancyStatus = 0;
	}

	/// Replaces the `IGameLogicProvider` if the community votes for it
	/// @dev The spirit of this function is to improve gameplay if the community decides
	/// @param gameLogicProvider The new instance of an IGameLogicProvider (or the old if reverting)
	function replaceGameLogicProvider(address gameLogicProvider) public onlyGovernance nonReentrant {
		if (gameLogicProvider == address(0) || !IGameLogicProvider(gameLogicProvider).supportsInterface(type(IGameLogicProvider).interfaceId)) revert CallNotAllowed();
		// Let's make sure the replacement's game storage matches the original (i.e. the replacement should access the original data)
		uint256 existingGameCount = _gameLogicProvider.totalGames();
		if (IGameLogicProvider(gameLogicProvider).totalGames() != existingGameCount) revert CallNotAllowed();
		uint256 randomSelection = _randomSelection(existingGameCount);
		if (keccak256(abi.encode(_gameLogicProvider.ticTacToeGame(randomSelection))) !=
			keccak256(abi.encode(IGameLogicProvider(gameLogicProvider).ticTacToeGame(randomSelection)))) revert CallNotAllowed();
		// Now we're good to replace
		_gameLogicProvider = IGameLogicProvider(gameLogicProvider);
	}

	/// Replaces the `IMetadataProvider` if the community votes for it
	/// @dev The spirit of this function is to improve the look of the NFT if the community decides
	/// @param metadataProvider The new instance of an IMetadataProvider (or an old if reverting)
	function replaceMetadataProvider(address metadataProvider) public onlyGovernance nonReentrant {
		// Let's test some basic functions of the interface to make sure it doesn't crash
		if (metadataProvider == address(0) ||
			!IMetadataProvider(metadataProvider).supportsInterface(type(IMetadataProvider).interfaceId) ||
			bytes(IMetadataProvider(metadataProvider).contractSymbol()).length == 0 ||
			bytes(IMetadataProvider(metadataProvider).ownerSymbol()).length == 0) revert CallNotAllowed();
		// Let's test a game to make sure it doesn't crash (yes, this will be expensive -- but this is important)
		uint256 randomSelection = _randomSelection(_gameLogicProvider.totalGames());
		if (bytes(IMetadataProvider(metadataProvider)
			.metadata(_gameLogicProvider.ticTacToeGame(randomSelection), randomSelection)).length < 1024) revert CallNotAllowed();
		// Now we're good to replace
		_metadataProvider = IMetadataProvider(metadataProvider);
	}

	/// Restarts a game
	/// @dev The underlying code will ensure the tokenId is valid
	/// @param tokenId The token id of the game to restart
	function restartGame(uint256 tokenId) external {
		if (_msgSender() != ownerOf(tokenId)) revert GameNotOwned();
		_gameLogicProvider.restartGame(tokenId);
		emit GameRestarted(_msgSender(), tokenId);
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721Royalty, Governor) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	/// Returns the `ITicTacToe.Game` info for the specified `tokenId`
	/// @dev The underlying code will ensure the tokenId is valid
	/// @param tokenId The token id of the game
	function ticTacToeGame(uint256 tokenId) external view returns (ITicTacToe.Game memory) {
		return _gameLogicProvider.ticTacToeGame(tokenId);
	}

	/// @inheritdoc IERC721Enumerable
	function tokenByIndex(uint256 index) external view returns (uint256) {
		if (index >= totalSupply()) revert IndexOutOfBounds();
		return index; // Burning is not exposed by this contract so we can simply return the index
	}

	/// @inheritdoc IERC721Enumerable
	/// @dev This implementation is for the benefit of web3 sites -- it is extremely expensive for contracts to call on-chain
	function tokenOfOwnerByIndex(address owner_, uint256 index) external view returns (uint256 tokenId) {
		if (index >= balanceOf(owner_)) revert IndexOutOfBounds();
		uint totalGames = totalSupply();
		for (uint tokenIndex = 0; tokenIndex < totalGames; tokenIndex++) {
			// Use _exists() to avoid a possible revert when accessing OpenZeppelin's ownerOf(), despite not exposing _burn()
			if (_exists(tokenIndex) && ownerOf(tokenIndex) == owner_) {
				if (index == 0) {
					tokenId = tokenIndex;
					break;
				}
				index--;
			}
		}
	}

	/// @dev See {IERC721Metadata-tokenURI}.
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		return _metadataProvider.metadata(_gameLogicProvider.ticTacToeGame(tokenId), tokenId);
	}

	/// @inheritdoc IERC721Enumerable
	function totalSupply() public view returns (uint256) {
		return _gameLogicProvider.totalGames();
	}

	/// Updates the default royalty information
	/// @param receiver The receiver of royalties
	/// @param feeNumerator The numerator in basis-points
	function updateDefaultRoyalty(address payable receiver, uint96 feeNumerator) external onlyOwner {
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	/// @dev Withdraws royalties for the creator
	function withdraw() external onlyOwner {
		_payoutRoyalties();
	}

	/// @inheritdoc Governor
	function execute(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) public payable override returns (uint256) {
		_payoutRoyalties();
		return super.execute(targets, values, calldatas, descriptionHash);
	}

	/// May emit a {Votes-DelegateVotesChanged} event
	/// @dev Registers new wallets for self-delegation (to simplify the voting process later)
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
		if (balanceOf(to) == 0) {
			_delegate(to, to); // Go ahead and configure voting for the new owner
		}
		if (from != address(0)) {
			uint256 votingUnits = _gameLogicProvider.ticTacToeGame(tokenId).history.wins;
			if (votingUnits > 0) {
				_transferVotingUnits(from, to, votingUnits);
			}
		}
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _payoutRoyalties() private nonReentrant {
		uint256 balance = address(this).balance;
		uint256 royalties = _reservedBalance();
		if (royalties == 0 || balance == 0) return;
		royalties = balance < royalties ? balance : royalties;
		_released += royalties;
		Address.sendValue(payable(owner()), royalties);
	}

	/// Supports the upgrade functions by providing a random selection
	function _randomSelection(uint256 maxValue) private view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(block.number, _released, _totalMoves))) % maxValue;
	}

	function _reservedBalance() private view returns (uint256) {
		return (_totalMoves * 0.01 ether) - _released;
	}
}
