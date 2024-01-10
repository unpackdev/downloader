// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./EnumerableSet.sol";
import "./Pausable.sol";
import "./RpSeeder.sol";

/// @title A Death Roll-inspired game for Raid Party
/// @author xanewok.eth
/// @notice The games uses $CFTI, the native Raid Party token
contract ConfettiRoll is AccessControlEnumerable, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    IERC20 public immutable confetti;
    RpSeeder public immutable seeder;
    address public immutable treasury;
    uint256 public tipAmount;
    uint256 public treasuryAmount;

    uint128 public minBet = 1e17; // 0.1 $CFTI
    uint128 public maxBet = 150e18; // 150 $CFTI
    uint128 public defaultBet = 30e18; // 30 $CFTI

    uint16 public treasuryFee = 500; // 5%
    uint16 public betTip = 50; // 0.5%
    uint16 constant FEE_PRECISION = 1e4;

    uint16 public minStartingRoll = 2;
    uint16 public maxStartingRoll = 1000;
    uint16 public defaultStartingRoll = 100;

    uint16 public defaultMaxParticipants = 10;

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    struct Game {
        address[] participants;
        uint128 poolBet;
        uint32 roundNum;
        uint16 startingRoll;
        uint16 maxParticipants;
    }

    struct GameResult {
        // In theory this should always be equal to `getSeed(game.roundNum)`;
        // however, since we depend on an external seeder, let's always remember
        // the seed for a given finalized game to make the results verifiable
        // and deterministic
        uint256 finalizedSeed;
        // The amount that every participant (except for the loser) is due,
        // after the game finishes
        uint256 prizeShare;
        address loser;
    }

    event PlayerLost(bytes32 indexed gameId, address indexed player);
    event GameCreated(bytes32 indexed gameId);
    event PlayerJoined(bytes32 indexed gameId, address indexed player);

    mapping(bytes32 => GameResult) gameResults;
    mapping(bytes32 => Game) games;

    mapping(address => EnumerableSet.Bytes32Set) pendingGames;

    constructor(
        IERC20 confetti_,
        address seeder_,
        address treasury_
    ) {
        _setupRole(TREASURY_ROLE, treasury_);

        seeder = RpSeeder(seeder_);
        treasury = treasury_;
        confetti = confetti_;
        tipAmount = 0;
        treasuryAmount = 0;
    }

    function setTreasuryFee(uint16 treasuryFee_)
        public
        onlyRole(TREASURY_ROLE)
    {
        require(treasuryFee_ <= 3000, "Let the gamblers gamble in peace");
        treasuryFee = treasuryFee_;
    }

    function withdrawTax() public onlyRole(TREASURY_ROLE) {
        require(treasuryAmount > 0, "Nothing to withdraw");
        confetti.transfer(treasury, treasuryAmount);
        treasuryAmount = 0;
    }

    function withdrawTip() public onlyOwner {
        require(tipAmount > 0, "Nothing to withdraw");
        confetti.transfer(owner(), tipAmount);
        tipAmount = 0;
    }

    function setBetTip(uint16 betTip_) public onlyOwner {
        betTip = betTip_;
    }

    function setBets(
        uint128 min,
        uint128 max,
        uint128 default_
    ) public onlyOwner {
        minBet = min;
        maxBet = max;
        defaultBet = default_;
    }

    function setStartingRolls(
        uint16 min,
        uint16 max,
        uint16 default_
    ) public onlyOwner {
        minStartingRoll = min;
        maxStartingRoll = max;
        defaultStartingRoll = default_;
    }

    function setDefaultMaxParticipants(uint16 value) public onlyOwner {
        defaultMaxParticipants = value;
    }

    /// @dev We piggyback on the RaidParty batch seeder for our game round abstraction
    function currentRound() public view returns (uint32) {
        return uint32(seeder.getBatch());
    }

    /// @notice Return generated random words for a given game round
    function getSeed(uint32 roundNum) public view returns (uint256) {
        bytes32 reqId = seeder.getReqByBatch(roundNum);
        return seeder.getRandomness(reqId);
    }

    function getGame(bytes32 gameId) public view returns (Game memory) {
        return games[gameId];
    }

    function getGameResults(bytes32 gameId)
        public
        view
        returns (GameResult memory)
    {
        return gameResults[gameId];
    }

    function isGameFinished(bytes32 gameId) public view returns (bool) {
        return gameResults[gameId].loser != address(0x0);
    }

    /// @notice Returns the order in which the players roll for a given game
    function getRollingPlayers(bytes32 gameId)
        public
        view
        returns (address[] memory)
    {
        Game memory game = games[gameId];
        uint256 seed = getSeed(game.roundNum);
        require(seed > 0, "Game not seeded yet");
        require(game.participants.length >= 2, "Need at least 2 players");

        return shuffledPlayers(game.participants, seed);
    }

    /// @notice Returns player rolls for a given game. They correspond to player order returned by `getRollingPlayers`
    function getRolls(bytes32 gameId) public view returns (uint256[] memory) {
        Game memory game = games[gameId];
        uint256 seed = getSeed(game.roundNum);
        require(seed > 0, "Game not seeded yet");
        require(game.participants.length >= 2, "Need at least 2 players");
        // NOTE: The part below is the same as `simulateGame` only with
        // remembering the roll values (which are originally not to save gas).

        // The upper bound for the number of rolls is the starting roll value
        uint256[] memory rolls = new uint256[](game.startingRoll);

        uint256 roll = game.startingRoll;
        uint256 rollCount = 0;
        while (roll > 0) {
            // NOTE: `roll` is always in the [1, game.startingRoll - 1] range
            // here, as we start if it's positive and we always use modulo,
            // starting from the `game.startingRoll`
            roll = uint256(keccak256(abi.encodePacked(rollCount, seed))) % roll;
            rolls[rollCount] = roll + 1;
            rollCount++;
        }
        // NOTE: This is meant to be executed in a read-only fashion - to get rid
        // of the extra zeroes, we just copy over the actual rolls to a new array
        uint256[] memory returnedRolls = new uint256[](rollCount);
        for (uint256 i = 0; i < returnedRolls.length; i++) {
            returnedRolls[i] = rolls[i];
        }
        return returnedRolls;
    }

    /// @notice Returns a list of outstanding games for the player
    function getPendingGames(address player)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory pendingGames_ = new bytes32[](
            pendingGames[player].length()
        );
        for (uint256 i = 0; i < pendingGames[player].length(); i++) {
            pendingGames_[i] = pendingGames[player].at(i);
        }
        return pendingGames_;
    }

    /// @notice Returns whether the player is eligible to collect a prize for a given game
    function canCollectReward(address player, bytes32 gameId)
        public
        view
        returns (bool)
    {
        return (isGameFinished(gameId) && gameResults[gameId].loser != player);
    }

    /// @notice Returns a total amount of claimable rewards by the player
    function getPendingRewards(address player) public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < pendingGames[player].length(); i++) {
            bytes32 gameId = pendingGames[player].at(i);
            if (canCollectReward(player, gameId)) {
                sum += gameResults[gameId].prizeShare;
            }
        }
        return sum;
    }

    /// @notice Process and clear every outstanding game, collecting the rewards
    function withdrawRewards() public whenNotPaused returns (uint256) {
        address player = msg.sender;
        uint256 rewards = 0;

        for (uint256 i = 0; i < pendingGames[player].length(); ) {
            bytes32 gameId = pendingGames[player].at(i);
            if (canCollectReward(player, gameId)) {
                rewards += gameResults[gameId].prizeShare;
            }
            // NOTE: This is the main function that is responsible for clearing
            // up pending games (e.g. for UI reasons), so make sure to clear up
            // pending *lost* games as well, even if we didn't collect a prize
            if (isGameFinished(gameId)) {
                pendingGames[player].remove(gameId);
                // Deleting an element might've shifted the order of the elements
                // and since we're deleting while iterating (a Bad Idea^TM),
                // simply start iterating from the start to be safe
                i = 0;
            } else {
                i++;
            }
        }

        confetti.transfer(msg.sender, rewards);
        return rewards;
    }

    /// @notice Calculates the game identifier for a given game initializer and roundNum
    /// The game initializer can be either the address of the contract if we're
    /// creating a "global" game or the address of the callee
    function calcGameId(address initializer, uint256 roundNum)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(initializer, roundNum));
    }

    /// @notice Returns a game identifier for the currently running, global game
    function currentGlobalGameId() public view returns (bytes32) {
        return calcGameId(address(this), currentRound());
    }

    // Anyone can join the game for the current round where either they are the
    // initializer and they can set a custom bet or they can create a global
    // game per round with a default bet amount
    /// @notice Create a new game
    /// @param initializer needs to be an address of the contract or the sender
    /// @param poolBet The amount of money that the player enters with. Use 18 decimals, just like for $CFTI
    /// @param maxParticipants The maximum number of players that can join the game
    /// @param startingRoll The upper roll that the game begins with
    /// @param roundNum The round when the game will be played. Must be bigger than the current round
    function createGame(
        address initializer,
        uint128 poolBet,
        uint16 startingRoll,
        uint16 maxParticipants,
        uint32 roundNum
    ) public whenNotPaused returns (bytes32) {
        if (startingRoll == 0) {
            startingRoll = defaultStartingRoll;
        }
        if (poolBet == 0) {
            poolBet = defaultBet;
        }
        if (maxParticipants < 2) {
            maxParticipants = defaultMaxParticipants;
        }
        uint256 seed = getSeed(roundNum);
        require(seed == 0, "Game already seeded");
        require(
            roundNum >= currentRound(),
            "Can't create games in the past"
        );
        require(
            poolBet >= minBet && poolBet <= maxBet,
            "Bet outside legal range"
        );
        require(
            startingRoll >= minStartingRoll && startingRoll <= maxStartingRoll,
            "Start roll outside legal range"
        );
        // Allow for creating a custom game with the sender as initializer or
        // a "global" (per round) one that needs to have default values set
        require(
            initializer == msg.sender ||
                (initializer == address(this) &&
                    poolBet == defaultBet &&
                    startingRoll == defaultStartingRoll &&
                    maxParticipants == defaultMaxParticipants)
        );
        bytes32 gameId = calcGameId(initializer, roundNum);
        require(!isGameFinished(gameId), "Game already finished");

        games[gameId].poolBet = poolBet;
        games[gameId].roundNum = roundNum;
        games[gameId].startingRoll = startingRoll;
        games[gameId].maxParticipants = maxParticipants;

        emit GameCreated(gameId);
        return gameId;
    }

    /// @notice Join the given game. Needs $CFTI approval as the player needs to deposit the pool bet in order to play.
    function joinGame(bytes32 gameId) public whenNotPaused {
        Game memory game = games[gameId];
        require(game.startingRoll > 0, "Game doesn't exist yet");
        require(!isGameFinished(gameId), "Game already finished");
        // Mitigate possible front-running - close the game sign-ups about a minute
        // before the seeder can request randomness. The RP seeder is pre-configured
        // to require 3 block confirmations, so 60 seconds makes sense (< 3 * 14s)
        uint256 seed = getSeed(game.roundNum);
        require(seed == 0, "Game already seeded");
        require(
            seeder.getNextAvailableBatch() > (block.timestamp + 60),
            "Seed imminent; sign-up is closed"
        );
        require(!pendingGames[msg.sender].contains(gameId), "Already joined");
        require(
            games[gameId].participants.length < game.maxParticipants &&
                games[gameId].participants.length <= (FEE_PRECISION / betTip),
            "Too many players"
        );

        uint256 tip = (game.poolBet * betTip) / FEE_PRECISION;
        tipAmount += tip;
        confetti.transferFrom(msg.sender, address(this), game.poolBet);

        games[gameId].participants.push(msg.sender);
        pendingGames[msg.sender].add(gameId);
        emit PlayerJoined(gameId, msg.sender);
    }

    /// @notice A convenient method to join the currently running global game
    function joinGlobalGame() public whenNotPaused returns (bytes32) {
        bytes32 globalGameId = currentGlobalGameId();
        // Lazily create a global game if there isn't one already
        if (games[globalGameId].startingRoll == 0) {
            createGame(
                address(this),
                defaultBet,
                defaultStartingRoll,
                defaultMaxParticipants,
                currentRound()
            );
        }
        joinGame(globalGameId);
        return globalGameId;
    }

    /// @return Shuffled randomly players from the given ones, using supplied seed
    function shuffledPlayers(address[] memory players, uint256 seed)
        public
        pure
        returns (address[] memory)
    {
        address[] memory shuffled = players;

        address temp;
        uint256 pick;
        for (uint256 i = 0; i < players.length; i++) {
            // Randomly pick a value from i (incl.) till the end of the array
            // To further increase randomness entropy, add the current player address
            pick =
                uint256(keccak256(abi.encodePacked(players[i], seed))) %
                (players.length - i);
            temp = shuffled[i];
            // Save the randomly picked number as the i-th address in the sequence
            shuffled[i] = shuffled[i + pick];
            // Return the original value to the pool that we pick from
            shuffled[i + pick] = temp;
        }

        return shuffled;
    }

    /// @dev Given an unitialized yet game, simulate the game and commit the results to the storage
    function simulateGame(bytes32 gameId)
        internal
        whenNotPaused
        returns (GameResult storage)
    {
        require(!isGameFinished(gameId), "Game already finished");
        Game memory game = games[gameId];

        uint256 seed = getSeed(game.roundNum);
        require(seed > 0, "Game not seeded yet");
        require(game.participants.length >= 2, "Need at least 2 players");
        // To remove any bias from the order that players registered with, make
        // sure to shuffle them before starting the actual game
        // NOTE: This is the same as `getRollingPlayers`
        address[] memory players = shuffledPlayers(game.participants, seed);

        // NOTE: This is the same as `getRolls`, however we don't use that as
        // we'd spend too much gas on remembering the rolls - we're interested
        // only in the outcome itself, which is the losing player
        uint256 roll = game.startingRoll;
        uint256 rollCount = 0;
        while (roll > 0) {
            // NOTE: `roll` is always in the [1, game.startingRoll - 1] range
            // here, as we start if it's positive and we always use modulo,
            // starting from the `game.startingRoll`
            unchecked {
                roll =
                    uint256(keccak256(abi.encodePacked(rollCount, seed))) %
                    roll;
                rollCount++;
            }
        }

        // The last to roll is the one who lost
        address loser = players[(rollCount - 1) % players.length];
        gameResults[gameId].loser = loser;
        // Saved for bookkeeping
        gameResults[gameId].finalizedSeed = seed;

        return gameResults[gameId];
    }

    /// @notice Simulates a given game, assuming it's been seeded since its creation
    function commenceGame(bytes32 gameId) public whenNotPaused {
        Game memory game = games[gameId];

        require(game.participants.length > 0, "No players in the game");
        if (game.participants.length == 1) {
            // Not much of a game if we have a single participant, return the bet
            confetti.transfer(game.participants[0], game.poolBet);
            pendingGames[game.participants[0]].remove(gameId);
            return;
        }

        GameResult storage results = simulateGame(gameId);
        require(isGameFinished(gameId), "Game not finished after simul.");
        require(results.loser != address(0), "Finished game has no loser");

        emit PlayerLost(gameId, results.loser);

        // Tax the prize money for the treasury
        uint256 collectedBetTip = (game.poolBet * betTip) / FEE_PRECISION;
        uint256 payableBet = game.poolBet - collectedBetTip;
        uint256 treasuryShare = (payableBet * treasuryFee) / FEE_PRECISION;
        treasuryAmount += treasuryShare;

        // Split the remaining prize pool among the winners; they need to collect
        // them themselves to amortize gas cost of the game simulation
        results.prizeShare =
            // Original bet
            payableBet +
            // Taxed prize pool that's split among everyone
            (payableBet - treasuryShare) /
            (game.participants.length - 1);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
