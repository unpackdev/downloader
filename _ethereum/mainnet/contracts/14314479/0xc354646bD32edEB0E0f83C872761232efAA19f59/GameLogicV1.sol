// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./Randomization.sol";
import "./IGameLogicProvider.sol";
import "./GameConnector.sol";

/// @title GameLogicV1
contract GameLogicV1 is GameConnector, VRFConsumerBaseV2, IGameLogicProvider {

	/// @dev Event emitted when a random number request happens to fail (probably misconfiguration)
	event RandomRequestFailed(uint64 indexed subscriptionId);

	/// @dev Event emitted when the VRF subscription is updated
	event VRFSubscriptionUpdated(uint64 indexed subscriptionId, bytes32 keyHash, uint32 callbackGasLimit);

	/// @dev Maximum games that will exist on the blockchain
	uint256 public constant MAX_GAMES = 999;

	/// @dev Seed for randomness
	uint256 private _seed;

	/// @dev Array of GameIds to GameInfo structs
	GameUtils.GameInfo[] private _gameIdsToGameInfo;

	/// @dev The interface to the VRFCoordinator so that requests can be made
	VRFCoordinatorV2Interface private immutable _coordinator;

	/// @dev Stores outstanding VRF requests
	mapping(uint256 => bool) private _outstandingRequests;

	/// @dev The gaslimit needed to fulfill the Chainlink VRF callback
	uint32 private _callbackGasLimit;

	/// @dev The number of confirmations before VRF requests are fulfilled (default minimum is 3)
	uint16 private _requestConfirmations;

	/// @dev The keyHash of the "gas lane" used by Chainlink
	bytes32 private _keyHash;

	/// @dev The configured VRF subscription id
	uint64 private _subscriptionId;

	/// @dev Can devs do something?
	constructor(uint256 seed, address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
		_seed = seed;
		_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
	}

	/// Configures a chainlink VRF2 subscription for random number generation
	/// @dev Only the contract owner may call this
	/// @param keyHash The keyHash of the "gas lane" used by Chainlink
	/// @param subscriptionId The subscription id
	/// @param requestConfirmations The number of confirmations before requests are fulfilled (default minimum is 3)
	/// @param callbackGasLimit The gaslimit needed to fulfill the callback
	function configureVrfSubscription(bytes32 keyHash, uint64 subscriptionId, uint16 requestConfirmations, uint32 callbackGasLimit) external onlyOwner {
		_keyHash = keyHash;
		_subscriptionId = subscriptionId;
		_requestConfirmations = requestConfirmations;
		_callbackGasLimit = callbackGasLimit;
		emit VRFSubscriptionUpdated(subscriptionId, keyHash, callbackGasLimit);
	}

	/// @inheritdoc IGameLogicProvider
	function createGames(uint256 quantity) external onlyAllowedCallers returns (uint256 startingGameId) {
		startingGameId = _gameIdsToGameInfo.length;
		if (startingGameId + quantity > MAX_GAMES) revert SoldOut();
		ITicTacToe.GameHistory memory history = ITicTacToe.GameHistory(0, 0, 0, 0);
		uint256 seed = Randomization.randomSeed(_seed);
		for (uint i = 0; i < quantity; i++) {
			_gameIdsToGameInfo.push(GameUtils.initializeGame(history, seed >> i, 0));
		}
		_seed = seed;
	}

	/// @inheritdoc VRFConsumerBaseV2
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		if (!_outstandingRequests[requestId]) return;
		delete _outstandingRequests[requestId];
		if (randomWords.length == 0 || randomWords[0] == 0) return;
		_seed = randomWords[0];
	}

	/// Provides the internal GameUtils.GameInfo memory struct to an allowed caller
	function gameInfoStruct(uint256 gameId) external view onlyAllowedCallers onlyWhenExists(gameId) returns (GameUtils.GameInfo memory) {
		return _gameIdsToGameInfo[gameId];
	}

	/// Ensures the function only continues if the token exists
	modifier onlyWhenExists(uint256 gameId) {
		if (gameId >= _gameIdsToGameInfo.length) revert NonexistentGame();
		_;
	}

	/// @inheritdoc IGameLogicProvider
	function processMove(uint256 gameId, uint256 position) external onlyAllowedCallers onlyWhenExists(gameId) returns (ITicTacToe.GameState resultingState) {
		uint256 seed = Randomization.randomSeed(_seed);
		GameUtils.GameInfo memory gameInfo = GameUtils.processMove(_gameIdsToGameInfo[gameId], position, seed);
		_gameIdsToGameInfo[gameId] = gameInfo;
		_seed = seed;
		resultingState = gameInfo.state;
		if (resultingState == ITicTacToe.GameState.OwnerWon && _subscriptionId != 0 && gameInfo.history.wins % 5 == 0) {
			// If configured, we should occasionally re-seed randomness when somebody wins
			try _coordinator.requestRandomWords(_keyHash, _subscriptionId, _requestConfirmations, _callbackGasLimit, 1) returns (uint256 requestId) {
				_outstandingRequests[requestId] = true;
			} catch {
				emit RandomRequestFailed(_subscriptionId);
			}
		}
	}

	/// @inheritdoc IGameLogicProvider
	function restartGame(uint256 gameId) external onlyAllowedCallers onlyWhenExists(gameId) {
		GameUtils.GameInfo memory gameInfo = _gameIdsToGameInfo[gameId];
		if (gameInfo.state == ITicTacToe.GameState.InPlay) {
			gameInfo.history.restarts += 1;
		}
		uint256 seed = Randomization.randomSeed(_seed);
		_gameIdsToGameInfo[gameId] = GameUtils.initializeGame(gameInfo.history, seed, block.number);
		_seed = seed;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure override(GameConnector, IERC165) returns (bool) {
		return interfaceId == type(IGameLogicProvider).interfaceId || super.supportsInterface(interfaceId);
	}

	/// @inheritdoc IGameLogicProvider
	function ticTacToeGame(uint256 gameId) external view onlyAllowedCallers onlyWhenExists(gameId) returns (ITicTacToe.Game memory) {
		return GameUtils.gameFromGameInfo(_gameIdsToGameInfo[gameId]);
	}

	/// @inheritdoc IGameLogicProvider
	function totalGames() external view returns (uint256) {
		return _gameIdsToGameInfo.length;
	}
}
