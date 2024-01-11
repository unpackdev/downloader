//"SPDX-License-Identifier: GPL-3.0

/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/

 a homage to math, geometry and cryptography.

********************************************/

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IPolys.sol";

contract PolysPlay is Ownable {

    struct Game {
        uint16 playNumber;
        uint16 lastPolyPlayed;
        uint8 compositionStreak;
        uint8 paletteStreak;
        uint8 doublingStreak;
        bool isWildcard;
    }

    // Parameters
    // -------------------------------------------
    // The duration of a game
    uint public gameDuration = 1 days;

    // The minimum amount of time left in the game after a play is made
    uint public timeBuffer;

    // Percentage that goes to charity from 0 to 100
    uint public charityShare;

    // Percentage that goes to development from 0 to 100
    uint public devShare;

    // Minimum amount to play a card
    uint public minEntry = 0.015 ether;

    // When the contract is paused the current game can end, but you can't start a new one.
    // We will probably pause the contract if we release a new version of the game.
    bool public isPaused = true;

    // If set to true this contract will create wildcard games where the rules have two changes:
    // 1) Polys with joker as the composition can always be played (jokers are the wildcard)
    // 2) Placing a circled Poly forces the next poly to match the *palette* (instead of forcing a composition match)
    bool public spawnWildcardGames;

    // Entry fee doubles every time the streak increases by ´streakDoubling´
    uint8 public spawnDoublingStreak;

    // State Variables
    // -------------------------------------------
    // The end time for the current game. If endTime = 0, no game is being played.
    uint public endTime;

    uint public currentGameId;

    mapping (uint => Game) public gameIdToGame;
    mapping (uint => mapping(uint16 => uint16)) public gameIdToBoard;

    // Constants and Immutables
    // -------------------------------------------
    IPolys immutable private _polys;
    address constant private _charityWallet = 0xE00327f0f5f5F55d01C2FC6a87ddA1B8E292Ac79;

    // Events
    // -------------------------------------------
    event GameStarted(uint gameId, address player, uint16 polyId, uint minEntry);
    event GameEnded(uint gameId, address winner, uint prize, uint charityDonation);
    event PolyPlayed(uint gameId, uint16 playNumber, address player, uint16 polyId, bool extended);
    event GameExtended(uint gameId, uint endTime);

    event NewDoublingStreak(uint8 doublingStreak);
    event NewWildcardFlag(bool isWildCardGame);

    constructor(address polys, uint _timeBuffer, uint _charityShare, uint _devShare, uint8 _doublingStreak) {
        _polys = IPolys(polys);
        timeBuffer = _timeBuffer;
        charityShare = _charityShare;
        devShare = _devShare;
        spawnDoublingStreak = _doublingStreak;
    }

    function newGame(uint16 polyId) payable external {
        require(endTime == 0, "1");
        require(msg.value >= minEntry, "2");
        require(_polys.ownerOf(polyId) == msg.sender, "3");
        require(!isPaused, "11");
        _newGame(polyId);
    }

    function playPoly(uint16 polyId) payable external {
        require(block.timestamp < endTime, "4");
        require(_polys.ownerOf(polyId) == msg.sender, "3");
        require(gameIdToBoard[currentGameId][polyId] == 0, "5");
        require(tx.origin == msg.sender, "10");
        Game memory game = gameIdToGame[currentGameId];
        require(msg.value == _getEntryFee(game), "2");

        uint compositionId = _propertyOf(polyId, true);
        bool sameComposition = compositionId == _propertyOf(game.lastPolyPlayed, true);
        bool samePalette = _propertyOf(polyId, false) == _propertyOf(game.lastPolyPlayed, false);

        if (game.isWildcard) {
            if (compositionId != 38) { // if it doesn't have the composition of the joker
                if (game.lastPolyPlayed < 101) {
                    require(sameComposition, "8");
                } else if (game.lastPolyPlayed < 201) {
                    require(samePalette, "8");
                } else {
                    require(sameComposition || samePalette, "8");
                }
            }
        } else {
            if (game.lastPolyPlayed < 201) {
                require(sameComposition, "8");
            } else {
                require(sameComposition || samePalette, "8");
            }
        }

        // Extend the game if the play was received within `timeBuffer` of the game endTime
        bool extended = endTime - block.timestamp < timeBuffer;
        if (extended) {
            endTime = block.timestamp + timeBuffer;
            emit GameExtended(currentGameId, endTime);
        }

        gameIdToBoard[currentGameId][polyId] = game.lastPolyPlayed;
        game.compositionStreak = sameComposition ? game.compositionStreak + 1 : 1;
        game.paletteStreak = samePalette ? game.paletteStreak + 1 : 1;
        game.lastPolyPlayed = polyId;
        game.playNumber++;
        gameIdToGame[currentGameId] = game;

        emit PolyPlayed(currentGameId, game.playNumber, msg.sender, polyId, extended);
    }

    function endGame() external {
        require(endTime != 0, "6");
        require(block.timestamp > endTime, "7");
        require(tx.origin == msg.sender, "10");

        endTime = 0;
        bool startNewGame = !isPaused && address(this).balance > 3 * minEntry;

        Game memory currentGame = gameIdToGame[currentGameId];
        address payable winner = payable(_polys.ownerOf(currentGame.lastPolyPlayed));

        uint prize = getPrize();
        uint charityDonation = prize * charityShare / (100 - charityShare - devShare);
        uint devPayment = prize * devShare / (100 - charityShare - devShare);

        // Make payments
        (bool success1,) = winner.call{value: prize}('');
        (bool success2,) = _charityWallet.call{value: charityDonation}('');
        (bool success3,) = owner().call{value: devPayment}('');
        require(success1 && success2 && success3, "9");

        emit GameEnded(currentGameId, winner, prize, charityDonation);
        if (startNewGame) {
            _newGame(currentGame.lastPolyPlayed);
        }
    }

    // Getters functions
    // -------------------------------------------
    function getPrize() public view returns (uint) {
        return _getPrize(address(this).balance);
    }

    function getPrizeForNextPlay() public view returns (uint) {
        return _getPrize(address(this).balance + getEntryFeeCurrentGame());
    }

    function getCharityDonation() public view returns (uint) {
        return getPrize() * charityShare / (100 - charityShare - devShare);
    }

    function getEntryFeeCurrentGame() public view returns (uint) {
        if (endTime == 0)
            return minEntry;
        Game memory currentGame = gameIdToGame[currentGameId];
        return _getEntryFee(currentGame);
    }

    // Internal functions
    // -------------------------------------------
    function _getPrize(uint balance) internal view returns (uint) {
        if (!isPaused && balance > 3 * minEntry) {
            // reserve fee entry to start the next game
            balance -= minEntry;
        }
        return balance * (100 - charityShare - devShare)/100;
    }

    function _newGame(uint16 polyId) internal {
        endTime = block.timestamp + gameDuration;

        currentGameId++;
        gameIdToGame[currentGameId] = Game(1, polyId, 1, 1, spawnDoublingStreak, spawnWildcardGames);
        gameIdToBoard[currentGameId][polyId] = 2000;

        emit GameStarted(currentGameId, _polys.ownerOf(polyId), polyId, minEntry);
    }

    function _getEntryFee(Game memory game) internal view returns (uint) {
        uint maxStreak = game.paletteStreak > game.compositionStreak
        ? game.paletteStreak : game.compositionStreak;
        return minEntry << (maxStreak / game.doublingStreak);
    }

    function _propertyOf(uint16 polyId, bool isComposition) internal view returns (uint8) {
        // If poly is Original
        if (polyId < 101) {
            return uint8(polyId);
        } else if (polyId < 201) { // If poly is Circle
            return uint8(polyId - 100);
        } else { // If poly is Mixed
            (uint polyA, uint polyB) = _polys.parentsOfMix(polyId);
            if (isComposition){
                return uint8(polyA);
            } else{
                return uint8(polyB);
            }
        }
    }

    // Setter functions
    // -------------------------------------------
    function setWildCardFlag(bool _isWildCardGame) external onlyOwner {
        spawnWildcardGames = _isWildCardGame;
        emit NewWildcardFlag(_isWildCardGame);
    }

    function setStreakDoubling(uint8 _doublingStreak) external onlyOwner {
        spawnDoublingStreak = _doublingStreak;
        emit NewDoublingStreak(spawnDoublingStreak);
    }

    function setMinEntry(uint _minEntry) external onlyOwner {
        require(endTime == 0); // The game rules can't change in the middle of a game
        minEntry = _minEntry;
    }

    function setGameDuration(uint _gameDuration) external onlyOwner {
        gameDuration = _gameDuration;
    }

    function setTimeBuffer(uint _timeBuffer) external onlyOwner {
        timeBuffer = _timeBuffer;
    }

    function setCharityWalletShare(uint _charityShare) external onlyOwner {
        require(endTime == 0); // The game rules can't change in the middle of a game
        charityShare = _charityShare;
    }

    function setDevShare(uint _devShare) external onlyOwner {
        require(endTime == 0); // The game rules can't change in the middle of a game
        devShare = _devShare;
    }

    function setPause(bool _pause) external onlyOwner {
        isPaused = _pause;
    }
}

// Errors:
// 1: You can't start a new game before ending the previous
// 2: The eth amount is not correct
// 3: You don't own that polys
// 4: This game is over
// 5: That polys was already played
// 6: Game hasn't started
// 7: Game hasn't finished
// 8: This is not a valid play
// 9: Payment failed
// 10: Only users can play
// 11: Can't start a new game when the contract is paused