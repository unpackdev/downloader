/*
   DiceBot Game

    .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
    | |  ________    | || |     _____    | || |     ______   | || |  _________   | || |   ______     | || |     ____     | || |  _________   | |
    | | |_   ___ `.  | || |    |_   _|   | || |   .' ___  |  | || | |_   ___  |  | || |  |_   _ \    | || |   .'    `.   | || | |  _   _  |  | |
    | |   | |   `. \ | || |      | |     | || |  / .'   \_|  | || |   | |_  \_|  | || |    | |_) |   | || |  /  .--.  \  | || | |_/ | | \_|  | |
    | |   | |    | | | || |      | |     | || |  | |         | || |   |  _|  _   | || |    |  __'.   | || |  | |    | |  | || |     | |      | |
    | |  _| |___.' / | || |     _| |_    | || |  \ `.___.'\  | || |  _| |___/ |  | || |   _| |__) |  | || |  \  `--'  /  | || |    _| |_     | |
    | | |________.'  | || |    |_____|   | || |   `._____.'  | || | |_________|  | || |  |_______/   | || |   `.____.'   | || |   |_____|    | |
    | |              | || |              | || |              | || |              | || |              | || |              | || |              | |
    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
    '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title DiceBot Game
 * @dev 
 */
contract DiceBotGame is Ownable {
    using SafeERC20 for IERC20;

    // Revenue Wallet
    address public revenueWallet;

    // The amount to take as revenue, in basis points.
    uint256 public immutable revenueBps;

    // The amount to burn forever, in basis points.
    uint256 public immutable burnBps;

    struct DiceGame {
        uint32 betSize;
        uint256 gameAmount;
        address bettingToken;
        address[] players;
        address winner;
        uint32 winnerScore;
        bool inProgress;
    }

    // Map GameID to their games.
    mapping(uint64 => DiceGame) public games;

    struct BettingToken {
        bool isBetting;
        uint256 minimumBet;
        address burnAddress;
    }
    // Map Betting Token to Bool
    mapping(address => BettingToken) public bettingToken;
    address[] public bettingTokenList;

    address private constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;

    // Stores the amount each player has bet for a game.
    event Bet(uint64 indexed gameId, address indexed bettingToken, address indexed player, uint256 amount);

    // Stores the amount each player wins for a game.
    event Win(uint64 indexed gameId, address indexed bettingToken, address indexed player);

    // Stores the amount collected by the protocol.
    event Revenue(uint64 indexed gameId, address indexed bettingToken, uint256 indexed amount);

    // Stores the amount burned by the protocol.
    event Burn(uint64 indexed gameId, address indexed bettingToken, uint256 indexed amount);

    constructor(uint256 _revenueBps, uint256 _burnBps, address _revenueWallet) Ownable(msg.sender) {
        // Update Revenue Wallet
        revenueWallet = _revenueWallet;
        // Update Revenue Bps
        revenueBps = _revenueBps;
        // Update Burn Bps
        burnBps = _burnBps;
    }

    /**
     * @dev Change Revenue Wallet
     */
    function changeRevenueWallet(address _newRevenue) public onlyOwner() {
        revenueWallet = _newRevenue;
    }

    /**
     * @dev Add betting token, only owner call it
     * @param tokenAddress New bettingToken address
     * @param minimumBet MinimumBet amount for new bettingToken
     */
    function addBettingToken(address tokenAddress, uint256 minimumBet, address burnAddress) public onlyOwner() {
        // Check Betting Token Exists
        if (!bettingToken[tokenAddress].isBetting) {
            // Update Betting Flag
            bettingToken[tokenAddress].isBetting = true;

            // Add New Betting Token
            bettingTokenList.push(tokenAddress);
        }

        // Update Betting Amount
        bettingToken[tokenAddress].minimumBet = minimumBet;

        // Update Burn Address
        bettingToken[tokenAddress].burnAddress = burnAddress;
    }

    /**
     * @dev Remove betting token
     * @param tokenAddress Removing bettingToken address
     */
    function removeBettingToken(address tokenAddress) public onlyOwner() {
        if (bettingToken[tokenAddress].isBetting) {
            // Update Betting Flag
            bettingToken[tokenAddress].isBetting = false;

            // Remove Betting Token
            uint bettingTokenListLength = bettingTokenList.length;
            for (uint i = 0; i < bettingTokenListLength; i += 1) {
                if (bettingTokenList[i] == tokenAddress) {
                    // Swap with Last ID
                    bettingTokenList[i] = bettingTokenList[bettingTokenListLength - 1];

                    // Remove Last ID
                    bettingTokenList.pop();
                }
            }
        }
    }

    /**
     * @dev Check if there is a game in progress for a Telegram group.
     * @param gameId Dice GameID
     * @return true if there is a game in progress, otherwise false
     */
    function isGameInProgress(uint64 gameId) public view returns (bool) {
        return games[gameId].inProgress;
    }

    /**
     * @dev Create a new game. Transfer funds into escrow.
     * @param _gameId Dice Bot Game ID
     * @param _betSize Number of chambers in the revolver
     * @param _bettingToken Betting Token for Dice
     * @param _gameAmount Amount of Game
     * @param _players Address list of players in game
     */
    function newGame(
        uint64 _gameId,
        address _bettingToken,
        uint32 _betSize,
        uint256 _gameAmount,
        address[] memory _players
    ) public onlyOwner {
        require(_betSize >= 2, "Bet size too small");
        require(bettingToken[_bettingToken].isBetting, "Not betting token");
        require(bettingToken[_bettingToken].minimumBet <= _gameAmount, "Game amount should be more than minimum bet.");
        require(_players.length == _betSize, "Players length mismatch");
        require(!isGameInProgress(_gameId), "This game is on progress");

        // TransferFrom Amount of Betting Token to Game Contract
        for (uint32 i = 0; i < _betSize; i += 1) {
            // Check Balance
            require(IERC20(_bettingToken).balanceOf(_players[i]) >= _gameAmount, "Not enough balance");
            // Check Allowance
            require(IERC20(_bettingToken).allowance(_players[i], address(this)) >= _gameAmount, "Not enough allowance");

            IERC20(_bettingToken).safeTransferFrom(_players[i], address(this), _gameAmount);

            emit Bet(_gameId, _bettingToken, _players[i], _gameAmount);
        }

        // Create & Update New Game
        DiceGame memory newG;

        newG.bettingToken = _bettingToken;
        newG.betSize = _betSize;
        newG.gameAmount = _gameAmount;
        newG.players = _players;
        newG.inProgress = true;

        games[_gameId] = newG;
    }

    /**
     * @dev Declare a loser of the game and pay out the winnings.
     * @param _gameId Dice Bot Game ID
     * @param _scoreList Dice Game Score per Address
     */
    function endGame(
        uint64 _gameId,
        address[] memory _addressList,
        uint32[] memory _scoreList
    ) public onlyOwner {
        // Check Game in Progress
        require(isGameInProgress(_gameId), "No game in progress for this TG Dice Game ID");

        // Get Current Game
        DiceGame storage currentGame = games[_gameId];
        // Check Game Size
        require(currentGame.betSize == _addressList.length, "Players length mismatch");
        require(currentGame.betSize == _scoreList.length, "Players length mismatch");
        // Get Betting Token
        address _bettingToken = currentGame.bettingToken;
        // Get Burn Address
        address _burnAddress = bettingToken[_bettingToken].burnAddress;

        // Update Game Status
        currentGame.inProgress = false;

        uint256 totalAmount = currentGame.gameAmount * currentGame.betSize;
        // Get Winner
        uint32 winnerId = 0;
        for (uint32 i = 1; i < currentGame.betSize; i += 1) {
            if (_scoreList[winnerId] < _scoreList[i]) {
                winnerId = i;
            }
        }
        // Calc Burn & Revenue & Winner Amount
        require(burnBps + revenueBps < 10000, "Total fees must be < 100%");
        uint256 burnAmount = totalAmount * burnBps / 10000;
        uint256 revenueAmount = totalAmount * revenueBps / 10000;
        uint256 winnerAmount = totalAmount - burnAmount - revenueAmount;

        // Transfer to Winner
        IERC20(_bettingToken).safeTransfer(_addressList[winnerId], winnerAmount);

        // Transfer to Revenue Wallet
        IERC20(_bettingToken).safeTransfer(revenueWallet, revenueAmount);

        // Burn burnAmount
        IERC20(_bettingToken).safeTransfer(_burnAddress, burnAmount);

        // Update Game Winner Address & Score
        currentGame.winner = _addressList[winnerId];
        currentGame.winnerScore = _scoreList[winnerId];

        // Emit the Events
        emit Win(_gameId, _bettingToken, _addressList[winnerId]);
        emit Revenue(_gameId,_bettingToken, revenueAmount);
        emit Burn(_gameId,_bettingToken, burnAmount);
    }

    /**
     * @dev Abort a game and refund the bets. Use in emergencies
     *      e.g. bot crash.
     * @param _gameId DiceBot Game ID
     */
    function abortGame(uint64 _gameId) public onlyOwner {
        require(isGameInProgress(_gameId), "No game in progress for this Telegram chat ID");

        DiceGame storage currentGame = games[_gameId];
        address _bettingToken = currentGame.bettingToken;

        for (uint32 i = 0; i < currentGame.betSize; i += 1) {
            IERC20(_bettingToken).safeTransfer(currentGame.players[i], currentGame.gameAmount);
        }

        currentGame.inProgress = false;
    }
}