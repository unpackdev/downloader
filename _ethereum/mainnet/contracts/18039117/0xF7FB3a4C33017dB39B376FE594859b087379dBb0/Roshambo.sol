// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//   ██████╗░░█████╗░░██████╗██╗░░██╗░█████╗░███╗░░░███╗██████╗░░█████╗░   //
//   ██╔══██╗██╔══██╗██╔════╝██║░░██║██╔══██╗████╗░████║██╔══██╗██╔══██╗   //
//   ██████╔╝██║░░██║╚█████╗░███████║███████║██╔████╔██║██████╦╝██║░░██║   //
//   ██╔══██╗██║░░██║░╚═══██╗██╔══██║██╔══██║██║╚██╔╝██║██╔══██╗██║░░██║   //
//   ██║░░██║╚█████╔╝██████╔╝██║░░██║██║░░██║██║░╚═╝░██║██████╦╝╚█████╔╝   //
//   ╚═╝░░╚═╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═════╝░░╚════╝░   //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

import "./Base64.sol";
import "./ERC721.sol";
import "./Multicall.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Recorder.sol";
import "./Renderer.sol";
import "./Strings.sol";

import "./IERC4906.sol";
import "./IRoshambo.sol";

/// @title Roshambo
/// @author swaHili (swa.eth)
/// @notice Just a friendly onchain game of Block Paper Scissors
contract Roshambo is IRoshambo, IERC4906, ERC721, Multicall, Ownable, Pausable {
    using Strings for uint8;
    using Strings for uint72;
    using Strings for uint160;
    using Strings for uint256;
    /// @notice Address of Recorder contract used for recording player stats
    Recorder public immutable recorder;
    /// @notice Address of Renderer contract used for renderering svg metadata
    Renderer public immutable renderer;
    /// @notice Duration of block time used as time-constraint for commit and reveal actions
    uint256 public constant BLOCK_DURATION = 6969;
    /// @notice Minimum wager amount required to play
    uint256 public constant MIN_WAGER = 0.01 ether;
    /// @notice Address of beneficiary for collecting game fees
    address public beneficiary;
    /// @notice Dynamic rake percentage used to calculate game fee
    uint16 public rake;
    /// @notice Current ID of most recently created game
    uint40 public currentId;
    /// @notice Total supply of game NFTs
    uint40 public totalSupply;
    /// @notice Mapping of game ID to game struct
    mapping(uint40 => Game) public games;
    /// @notice Mapping of player address to balance available for withdrawal
    mapping(address => uint256) public balances;

    /// @dev Deploys new Recorder contract, initializes Renderer contract and sets beneficiary address
    constructor(Renderer _renderer, address _beneficiary) payable ERC721("Roshambo", "ROSHAMBO") {
        recorder = new Recorder();
        renderer = _renderer;
        beneficiary = _beneficiary;
    }

    /// @notice Creates new game with given wager and executes first throw
    /// @dev Player choice will change from None (0) to Hidden (1)
    /// @dev Game remains in Pending (0) stage until another player joins
    /// @param _rounds Maximum number of rounds to be played
    /// @param _commitment Generated hash of player address, choice, and secret
    /// @return currentId ID of the game just now created
    function newGame(
        uint8 _rounds,
        bytes32 _commitment
    ) external payable whenNotPaused returns (uint40) {
        // Reverts if rounds is an even value
        if (_rounds % 2 == 0) revert InvalidRounds();
        // Reverts if wager amount is less than the minimum
        if (msg.value < MIN_WAGER) revert InsufficientWager();

        // Initializes new game info and sets caller as player1
        Game storage game = games[++currentId];
        game.p1.player = msg.sender;
        game.pot = uint72(msg.value);
        game.totalRounds = _rounds;
        game.currentRound++;

        // Emits event for creating new game
        emit NewGame(currentId, _rounds, msg.sender, uint72(msg.value));

        // Commits player's first choice for the current round
        Round storage round = game.rounds[game.currentRound];
        _commit(currentId, game, round, _commitment);

        return currentId;
    }

    /// @notice Joins pending game by matching wager amount and executes first throw
    /// @dev Player choice will change from None (0) to Hidden (1)
    /// @dev Game skips the Commit (1) stage and moves directly into the Reveal (2) stage
    /// @param _gameId ID of the game being joined
    /// @param _commitment Generated hash of player address, choice, and secret
    function joinGame(uint40 _gameId, bytes32 _commitment) external payable whenNotPaused {
        Game storage game = _verify(_gameId);
        // Reverts if game is not in Pending stage
        if (game.stage != Stage.PENDING) revert InvalidStage();
        // Reverts if caller is player1
        if (msg.sender == game.p1.player) revert InvalidPlayer();
        // Reverts if wager amount does not match current game pot
        if (msg.value != game.pot) revert InvalidWager();

        // Updates game pot and sets caller as player2
        game.p2.player = msg.sender;
        game.pot += uint72(msg.value);

        // Emits event for joining game
        emit JoinGame(_gameId, msg.sender, game.pot);

        // Mints new game NFT to contract and increments supply
        _mint(address(this), _gameId);
        totalSupply++;

        // Commits player's first choice for the current round
        Round storage round = game.rounds[game.currentRound];
        _commit(_gameId, game, round, _commitment);
    }

    /// @notice Commits new choice for current round of game
    /// @dev Player choice will change from None (0) to Hidden (1)
    /// @dev Game moves into Reveal stage only once both players have committed their choice
    /// @param _gameId ID of the game being joined
    /// @param _commitment Generated hash of player address, choice, and secret
    function commit(uint40 _gameId, bytes32 _commitment) external {
        Game storage game = _verify(_gameId);
        Round storage round = game.rounds[game.currentRound];
        // Reverts if game is not in Commit stage
        if (game.stage != Stage.COMMIT) revert InvalidStage();
        // Reverts if current block number is passed the block number set for committing choices
        if (block.number > round.commitBlock) revert TimeElapsed();

        // Commits player choice for the current round
        _commit(_gameId, game, round, _commitment);
    }

    /// @notice Reveals previously committed choice for current round of game
    /// @dev Call will revert if either choice or secret are incorrect
    /// @dev Player choice will change from Hidden (1) to one of the three game choices
    /// @dev Game moves into Settle (3) stage only once both players have revealed their choice
    /// @param _gameId ID of the game being joined
    /// @param _choice Enum value of choice: Block (2) Paper (3) Scissors (4)
    /// @param _secret Unique password used to ultimately reproduce commitment hash
    function reveal(uint40 _gameId, Choice _choice, string calldata _secret) external {
        Game storage game = _verify(_gameId);
        Round storage round = game.rounds[game.currentRound];
        // Reverts if game is not in Reveal stage
        if (game.stage != Stage.REVEAL) revert InvalidStage();
        // Reverts if current block number is passed the block number set for revealing choices
        if (block.number > round.revealBlock) revert TimeElapsed();

        Player storage p1 = game.p1;
        Player storage p2 = game.p2;

        // Checks if caller is either player1 or player2
        if (p1.player == msg.sender) {
            // Reverts if player1 has already revealed their choice
            if (round.p1Choice != Choice.HIDDEN) revert AlreadyRevealed();
            // Verifies reveal for player1 by reproducing commitment hash
            _reveal(msg.sender, _choice, _secret, p1.commitment);
            round.p1Choice = _choice;
        } else if (p2.player == msg.sender) {
            // Reverts if player2 has already revealed their choice
            if (round.p2Choice != Choice.HIDDEN) revert AlreadyRevealed();
            // Verifies reveal for player2 by reproducing commitment hash
            _reveal(msg.sender, _choice, _secret, p2.commitment);
            round.p2Choice = _choice;
        } else {
            // Reverts if caller is NOT player1 or player2
            revert InvalidPlayer();
        }

        // Checks if both players have revealed their choices
        if (round.p1Choice != Choice.HIDDEN && round.p2Choice != Choice.HIDDEN) {
            // Moves game into Settle stage
            game.stage = Stage.SETTLE;
            // Emits event for second player to reveal their choice
            emit Reveal(_gameId, game.currentRound, msg.sender, _choice, game.stage);
            // Settles current round
            settle(_gameId);
        } else {
            // Emits event for first player to reveal their choice
            emit Reveal(_gameId, game.currentRound, msg.sender, _choice, game.stage);
            // Emits event for marketplaces to refresh metadata due to state update
            emit MetadataUpdate(_gameId);
        }
    }

    /// @notice Cancels pending game and transfers wager amount back to caller
    /// @param _gameId ID of the game being canceled
    function cancel(uint40 _gameId) external {
        Game storage game = _verify(_gameId);
        // Reverts if game is not in Pending stage
        if (game.stage != Stage.PENDING) revert InvalidStage();
        // Reverts if caller is not player1
        if (msg.sender != game.p1.player) revert InvalidPlayer();

        // Deletes game
        uint72 pot = game.pot;
        delete games[_gameId];

        // Transfers wager amount back to caller
        (bool success, ) = msg.sender.call{value: pot}("");
        if (!success) revert TransferFailed();

        // Emits event for canceling game
        emit Cancel(_gameId, msg.sender, pot);
    }

    /// @notice Withdraws pending balance amount to given account
    /// @param _to Address receiving ether
    function withdraw(address _to) external {
        uint256 balance = balances[_to];
        // Reverts if account balance is zero
        if (balance == 0) revert InsufficientBalance();

        // Resets account balance
        balances[_to] = 0;

        // Transfers balance to given account
        (bool success, ) = _to.call{value: balance}("");
        if (!success) revert TransferFailed();

        // Emits event for withdrawing balance
        emit Withdraw(msg.sender, _to, balance);
    }

    /// @dev Sets contract beneficiary for receiving game fees
    function setBeneficiary(address _beneficiary) external payable onlyOwner {
        beneficiary = _beneficiary;
    }

    /// @dev Sets dynamic rake percentage for calculating game fees
    function setRake(uint16 _rake) external payable onlyOwner {
        rake = _rake;
    }

    /// @dev Pauses executions for all pausable functions
    function pause() external payable onlyOwner {
        _pause();
    }

    /// @dev Unpauses executions for all pausable functions
    function unpause() external payable onlyOwner {
        _unpause();
    }

    /// @notice Gets total choice usage of player from all finished games
    /// @param _player Address of the player
    /// @param _choice Enum value of choice: Block (2) Paper (3) Scissors (4)
    function getUsageRate(
        address _player,
        Choice _choice
    ) external view returns (uint256 usage, uint256 totalGames, uint256 totalRounds) {
        uint40[] memory gameIds = recorder.getGameIds(_player);
        totalGames = gameIds.length;
        unchecked {
            for (uint40 i; i < totalGames; ++i) {
                Game storage game = games[gameIds[i]];
                totalRounds += game.currentRound;
                for (uint8 j = 1; j <= game.currentRound; ++j) {
                    if (
                        (_player == game.p1.player && _choice == game.rounds[j].p1Choice) ||
                        (_player == game.p2.player && _choice == game.rounds[j].p2Choice)
                    ) usage++;
                }
            }
        }
    }

    /// @notice Gets total series and rounds wins of player from all finished games
    /// @param _player Address of the player
    function getWinRate(
        address _player
    )
        external
        view
        returns (uint256 gamesWon, uint256 roundsWon, uint256 totalGames, uint256 totalRounds)
    {
        uint40[] memory gameIds = recorder.getGameIds(_player);
        totalGames = gameIds.length;
        unchecked {
            for (uint40 i; i < totalGames; ++i) {
                Game storage game = games[gameIds[i]];
                totalRounds += game.currentRound;
                if (game.winner == _player) gamesWon++;
                for (uint8 j = 1; j <= game.currentRound; ++j) {
                    if (_player == game.rounds[j].winner) roundsWon++;
                }
            }
        }
    }

    /// @notice Gets total wages and profits of player from all finished games
    /// @param _player Address of the player
    function getProfitMargin(
        address _player
    ) external view returns (uint256 profits, uint256 wages, uint256 totalGames) {
        uint40[] memory gameIds = recorder.getGameIds(_player);
        totalGames = gameIds.length;
        unchecked {
            for (uint40 i; i < totalGames; ++i) {
                Game storage game = games[gameIds[i]];
                uint256 wager = game.pot / 2;
                wages += wager;
                if (_player == game.winner) profits += wager;
            }
        }
    }

    /// @notice Gets current state of game for given round
    /// @param _gameId ID of the game
    /// @param _round Value of the round
    function getRound(
        uint40 _gameId,
        uint8 _round
    )
        external
        view
        returns (
            Choice p1Choice,
            Choice p2Choice,
            uint40 commitBlock,
            uint40 revealBlock,
            address winner
        )
    {
        Game storage game = games[_gameId];
        Round memory round = game.rounds[_round];
        p1Choice = round.p1Choice;
        p2Choice = round.p2Choice;
        commitBlock = round.commitBlock;
        revealBlock = round.revealBlock;
        winner = round.winner;
    }

    /// @notice Generates commitment hash required for committing choice
    /// @param _player Address of the player
    /// @param _choice Enum value of valid choice: Block (2) Paper (3) Scissors (4)
    /// @param _secret Unique password used to ultimately reproduce commitment hash
    function getCommit(
        address _player,
        Choice _choice,
        string calldata _secret
    ) external pure returns (bytes32) {
        if (_choice == Choice.NONE || _choice == Choice.HIDDEN) revert InvalidChoice();
        return keccak256(abi.encodePacked(_player, _choice, _secret));
    }

    /// @notice Settles current round and determines winner for round or game
    /// @dev Round either repeats if there's a tie OR determines winner and moves on to next round
    /// @dev Series ends in a draw if still in first round AND if either player fails to commit OR if both players fail to reveal
    /// @dev Game either moves back to Commit (1) stage or finishes in Draw (4) OR Success (5) stage
    /// @param _gameId ID of the game
    function settle(uint40 _gameId) public {
        Game storage game = _verify(_gameId);
        Round storage round = game.rounds[game.currentRound];
        // Sets game to Settle stage if block number is past commit or reveal block
        if (
            (game.stage == Stage.COMMIT && block.number > round.commitBlock) ||
            (game.stage == Stage.REVEAL && block.number > round.revealBlock)
        ) {
            game.stage = Stage.SETTLE;
        }
        // Reverts if game is not in Settle stage
        if (game.stage != Stage.SETTLE) revert InvalidStage();

        // Initializes game values
        Player storage p1 = game.p1;
        Player storage p2 = game.p2;
        Choice choice1 = round.p1Choice;
        Choice choice2 = round.p2Choice;
        address player1 = p1.player;
        address player2 = p2.player;

        // Determines outcome of current round and possibly the game
        if (
            game.currentRound == 1 &&
            ((choice1 == Choice.NONE || choice2 == Choice.NONE) ||
                (choice1 == Choice.HIDDEN && choice2 == Choice.HIDDEN))
        ) {
            // Finalizes game as a draw if it never moves to the Reveal stage
            _draw(_gameId, game, player1, choice1, player2, choice2);
        } else {
            if (
                (choice1 == Choice.BLOCK && choice2 == Choice.SCISSORS) ||
                (choice1 == Choice.PAPER && choice2 == Choice.BLOCK) ||
                (choice1 == Choice.SCISSORS && choice2 == Choice.PAPER) ||
                (choice1 == Choice.HIDDEN && choice2 == Choice.NONE) ||
                (choice1 != Choice.NONE && choice1 != Choice.HIDDEN && choice2 == Choice.HIDDEN)
            ) {
                // Settles player1 as winner of current round and possibly the game
                _settle(_gameId, game, round, p1, p2);
            } else if (
                (choice2 == Choice.BLOCK && choice1 == Choice.SCISSORS) ||
                (choice2 == Choice.PAPER && choice1 == Choice.BLOCK) ||
                (choice2 == Choice.SCISSORS && choice1 == Choice.PAPER) ||
                (choice2 == Choice.HIDDEN && choice1 == Choice.NONE) ||
                (choice2 != Choice.NONE && choice2 != Choice.HIDDEN && choice1 == Choice.HIDDEN)
            ) {
                // Settles player2 as winner of current round and possibly the game
                _settle(_gameId, game, round, p2, p1);
            } else {
                // Emits event for settling round or the game
                emit Settle(
                    _gameId,
                    game.currentRound,
                    Stage.COMMIT,
                    round.winner,
                    player1,
                    choice1,
                    p1.wins,
                    player2,
                    choice2,
                    p2.wins
                );

                // Resets the current round due to a tie
                _reset(_gameId, game, round, p1, p2);
            }
        }

        // Emits event for marketplaces to refresh metadata due to state update
        emit MetadataUpdate(_gameId);
    }

    /// @notice Generates metadata of game attributes and renders svg of NFT
    /// @param _tokenId ID of the game
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        Game storage game = games[uint40(_tokenId)];
        Round memory round = game.rounds[game.currentRound];
        Player memory p1 = game.p1;
        Player memory p2 = game.p2;
        string memory name = string.concat("Block Paper Scissors #", _tokenId.toString());
        string memory description = "Just a friendly onchain game of Block Paper Scissors. Shoot!";
        string memory gameTraits = _generateGameTraits(game, p1, p2);
        string memory playerTraits = _generatePlayerTraits(p1.player, p2.player, round);
        string memory image = Base64.encode(
            abi.encodePacked(
                renderer.generateImage(
                    _tokenId,
                    game.pot,
                    p1.player,
                    round.p1Choice,
                    p2.player,
                    round.p2Choice
                )
            )
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '{"name":"',
                            name,
                            '",',
                            '"description":"',
                            description,
                            '",',
                            '"image": "data:image/svg+xml;base64,',
                            image,
                            '",',
                            '"attributes": [',
                            playerTraits,
                            gameTraits,
                            "]}"
                        )
                    )
                )
            );
    }

    /// @dev Executes commitment of player choice for current round
    /// @param _gameId ID of the game
    /// @param _game Storage value of game info
    /// @param _round Storage value of current round info
    /// @param _commitment Generated hash of player address, choice, and secret
    function _commit(
        uint40 _gameId,
        Game storage _game,
        Round storage _round,
        bytes32 _commitment
    ) internal {
        Player storage p1 = _game.p1;
        Player storage p2 = _game.p2;

        // Checks if caller is player1 or player2
        if (p1.player == msg.sender) {
            // Reverts if player1 has already committed their choice
            if (p1.commitment != bytes32(0)) revert AlreadyCommitted();
            // Stores commitment of player1 and sets their choice to Hidden
            p1.commitment = _commitment;
            _round.p1Choice = Choice.HIDDEN;
        } else if (p2.player == msg.sender) {
            // Reverts if player2 has already committed their choice
            if (p2.commitment != bytes32(0)) revert AlreadyCommitted();
            // Stores commitment of player2 and sets their choice to Hidden
            p2.commitment = _commitment;
            _round.p2Choice = Choice.HIDDEN;
        } else {
            // Reverts if caller is not either player1 or player2
            revert InvalidPlayer();
        }

        // Checks if both players have committed their choice
        if (p1.commitment != bytes32(0) && p2.commitment != bytes32(0)) {
            // Moves game into the Reveal stage
            _game.stage = Stage.REVEAL;
            // Emits event for second player to commit their choice
            emit Commit(_gameId, _game.currentRound, msg.sender, _commitment, _game.stage);

            // Initializes reveal block using block duration
            _round.revealBlock = uint40(block.number + BLOCK_DURATION);
            // Emits event for the current round with a new reveal block
            emit CurrentRound(_gameId, _game.currentRound, _round.revealBlock);
        } else {
            // Emits event for first player to commit their choice
            emit Commit(_gameId, _game.currentRound, msg.sender, _commitment, _game.stage);
        }

        // Emits event for marketplaces to refresh metadata due to state update
        emit MetadataUpdate(_gameId);
    }

    /// @dev Resets the current round due to a tie
    /// @param _gameId ID of the game
    /// @param _game Storage value of game info
    /// @param _round Storage value of current round info
    /// @param _p1 Storage value of player1 info
    /// @param _p2 Storage value of player2 info
    function _reset(
        uint40 _gameId,
        Game storage _game,
        Round storage _round,
        Player storage _p1,
        Player storage _p2
    ) internal {
        // Resets the game, round and player info
        _game.stage = Stage.COMMIT;
        _p1.commitment = bytes32(0);
        _p2.commitment = bytes32(0);
        _round.p1Choice = Choice.NONE;
        _round.p2Choice = Choice.NONE;
        // Updates the commit block for the current round using block duration
        _round.commitBlock = uint40(block.number + BLOCK_DURATION);

        // Emits event for resetting the current round with a new commit block
        emit ResetRound(_gameId, _game.currentRound, _round.commitBlock);
    }

    /// @dev Begins the next round of the game
    /// @param _gameId ID of the game
    /// @param _game Storage value of game info
    /// @param _round Storage value of current round info
    /// @param _p1 Storage value of player1 info
    /// @param _p2 Storage value of player2 info
    function _next(
        uint40 _gameId,
        Game storage _game,
        Round storage _round,
        Player storage _p1,
        Player storage _p2
    ) internal {
        // Initializes the game and player info
        _game.stage = Stage.COMMIT;
        _p1.commitment = bytes32(0);
        _p2.commitment = bytes32(0);
        // Initializes the commit block of the new round using block duration
        _round.commitBlock = uint40(block.number + BLOCK_DURATION);

        // Emits event for moving game into the next round with a new commit block
        emit NextRound(_gameId, _game.currentRound, _round.commitBlock);
    }

    /// @dev Finalizes the game as a draw due to inactivity by either or both players
    /// @param _gameId ID of the game
    /// @param _game Storage value of game info
    /// @param _player1 Address of player1
    /// @param _choice1 Choice  of player1
    /// @param _player2 Address of player2
    /// @param _choice2 Choice  of player2
    function _draw(
        uint40 _gameId,
        Game storage _game,
        address _player1,
        Choice _choice1,
        address _player2,
        Choice _choice2
    ) internal {
        // Moves game into the Draw stage
        _game.stage = Stage.DRAW;
        // Calculates wager amount and updates balances of both players
        uint72 wager = _game.pot / 2;
        balances[_player1] += wager;
        balances[_player2] += wager;

        // Emits event for settling the game in a draw
        emit Settle(
            _gameId,
            _game.currentRound,
            _game.stage,
            _game.winner,
            _player1,
            _choice1,
            _game.p1.wins,
            _player2,
            _choice2,
            _game.p2.wins
        );
    }

    /// @dev Settles the round or game with a winner
    /// @param _gameId ID of the game
    /// @param _game Storage value of game info
    /// @param _round Storage value of current round info
    /// @param _winner Storage value of winner info
    /// @param _loser Storage value of loser info
    function _settle(
        uint40 _gameId,
        Game storage _game,
        Round storage _round,
        Player storage _winner,
        Player storage _loser
    ) internal {
        // Increments player wins and sets them as round winner
        _winner.wins++;
        _round.winner = _winner.player;

        // Checks if winner of round has also won more than half the total possible games
        if (_winner.wins > _game.totalRounds / 2) {
            // Finalizes winner of game
            _success(_gameId, _game, _round, _round.winner, _game.pot);
            // Records both player stats on Recorder contract
            recorder.setRecord(
                _gameId,
                _game.pot,
                _game.totalRounds,
                _game.currentRound,
                _winner.player,
                _loser.player
            );
        } else {
            // Emits settle event for round winner
            emit Settle(
                _gameId,
                _game.currentRound,
                Stage.COMMIT,
                _round.winner,
                _game.p1.player,
                _round.p1Choice,
                _game.p1.wins,
                _game.p2.player,
                _round.p2Choice,
                _game.p2.wins
            );

            // Increments round and moves game into the next round
            _round = _game.rounds[++_game.currentRound];
            _next(_gameId, _game, _round, _winner, _loser);
        }
    }

    /// @dev Finalizes game with a winner
    /// @param _gameId ID of the game
    /// @param _game Storage value of game info
    /// @param _round Storage value of current round info
    /// @param _winner Address of game winner
    /// @param _pot Ether amount of game pot
    function _success(
        uint40 _gameId,
        Game storage _game,
        Round storage _round,
        address _winner,
        uint72 _pot
    ) internal {
        // Moves game into the Success stage and sets winner
        _game.stage = Stage.SUCCESS;
        _game.winner = _winner;

        // Emits events for settling game with a winner
        emit Settle(
            _gameId,
            _game.currentRound,
            _game.stage,
            _winner,
            _game.p1.player,
            _round.p1Choice,
            _game.p1.wins,
            _game.p2.player,
            _round.p2Choice,
            _game.p2.wins
        );

        // Checks if rake has been set
        if (rake > 0) {
            // Adjusts rake percentage base on pot size and calculates game fee accordingly
            uint256 adjusted = recorder.adjustRake(_pot, rake);
            uint256 fee = (uint256(_pot) * adjusted) / 10_000;
            // Updates balance of winner minus fee amount
            balances[_winner] += (_pot - fee);
            balances[beneficiary] += fee;
        } else {
            // Updates balance of winner with entire game pot
            balances[_winner] += _pot;
        }

        // Mints NFT to winner
        _burn(_gameId);
        _mint(_winner, _gameId);
    }

    /// @dev Verifies that the game exists
    /// @param _gameId ID of the game
    /// @return game Storage value of game info
    function _verify(uint40 _gameId) internal view returns (Game storage game) {
        game = games[_gameId];
        // Reverts if game does not exist due to invalid ID or canceled game
        if (_gameId == 0 || _gameId > currentId || game.p1.player == address(0))
            revert InvalidGame();
    }

    /// @dev Verifies player reveal matches commitment hash
    /// @param _player Address of player revealing choice
    /// @param _choice Choice provided by player
    /// @param _secret Secret password provided by player
    /// @param _commitment Generated hash of player choice stored during Commit stage
    function _reveal(
        address _player,
        Choice _choice,
        string memory _secret,
        bytes32 _commitment
    ) internal pure {
        if (keccak256(abi.encodePacked(_player, _choice, _secret)) != _commitment)
            revert InvalidReveal();
    }

    /// @dev Generates game attributes of the game
    /// @param _game Storage value of game info
    /// @param _p1 Player1 info
    /// @param _p2 Player2 info
    /// @return JSON value of game traits
    function _generateGameTraits(
        Game storage _game,
        Player memory _p1,
        Player memory _p2
    ) internal view returns (string memory) {
        string memory pot = string.concat(unicode"Ξ ", recorder.weiToEth(_game.pot));
        string memory total = _game.totalRounds.toString();
        string memory current = _game.currentRound.toString();
        string memory round = string.concat(current, " of ", total);
        string memory stage = renderer.getStage(_game.stage);
        string memory winner = uint160(_game.winner).toHexString(20);
        if (_p1.wins > _p2.wins) {
            winner = uint160(_p1.player).toHexString(20);
        } else if (_p2.wins > _p1.wins) {
            winner = uint160(_p2.player).toHexString(20);
        }

        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Pot", "value":"',
                    pot,
                    '"},',
                    '{"trait_type":"Round", "value":"',
                    round,
                    '"},',
                    '{"trait_type":"Stage", "value":"',
                    stage,
                    '"},',
                    '{"trait_type":"Winner", "value":"',
                    winner,
                    '"}'
                )
            );
    }

    /// @dev Generates player attributes of the game
    /// @param _player1 Address of player1
    /// @param _player2 Address of player2
    /// @param _round Round info
    /// @return JSON value of player traits
    function _generatePlayerTraits(
        address _player1,
        address _player2,
        Round memory _round
    ) internal view returns (string memory) {
        string memory player1 = uint160(_player1).toHexString(20);
        string memory player2 = uint160(_player2).toHexString(20);
        string memory choice1 = renderer.getChoice(_round.p1Choice);
        string memory choice2 = renderer.getChoice(_round.p2Choice);

        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    choice1,
                    '", "value":"',
                    player1,
                    '"},',
                    '{"trait_type":"',
                    choice2,
                    '", "value":"',
                    player2,
                    '"},'
                )
            );
    }
}
