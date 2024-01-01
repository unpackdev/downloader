// SPDX-License-Identifier: MIT

// Roll-The-Dice Game Contract: 17 November 2023
// Version: 1.2

// Website: https://kekw.gg/
// telegram: https://t.me/kekw_gg
// X.com/Twtter: https://x.com/kekw_gg
// Token: ($KEKW) 0x0DF596AD12F927e41EC317AF7DD666cA3574845f
// Uniswap: https://app.uniswap.org/swap?outputCurrency=0x0DF596AD12F927e41EC317AF7DD666cA3574845f
// Dextools: https://www.dextools.io/app/en/ether/pair-explorer/0x14ba508aaf2c15231f9df265980d1d461e54192b

pragma solidity ^0.8.18;

interface Casino {
    struct Game {
        uint256 index; // servers as Id
        uint256 betAmount;
        uint256 totalBetAmount;
        address player1;
        address player2;
        address winner;
        address gameContractAddress;
        string player1Outcome;
        string player2Outcome;
    }

    function ensureGameIsNotPlayed(uint256 _index)
        external
        view
        returns (Game memory);

    function winnerCallback(
        uint256 gameIndex,
        address winnerAddress,
        string memory _player1Outcome,
        string memory _player2Outcome
    ) external;
}

contract RollTheDice {
    Casino public casino;
    address public casinoAddress;
    address public manager;
    bool public paused;
    uint256 public randomness = 64;

    event GameStarted(uint256 gameIndex, address playerAddress);
    event GameCompleted(
        uint256 gameIndex,
        address winnerAddress,
        string randomSeed,
        string player1Outcome,
        string player2Outcome
    );
    event GameTie(uint256 gameIndex);

    constructor(address _casino) {
        manager = msg.sender;
        casino = Casino(_casino);
        casinoAddress = _casino;
    }

    function updateCasino(address _casino) public restricted {
        casino = Casino(_casino);
        casinoAddress = _casino;
    }

    function updateRandomness(uint256 _randomness) public restricted {
        randomness = _randomness;
    }

    function generateRandomString(uint256 length)
        public
        view
        returns (string memory)
    {
        require(length > 0, "Length must be greater than 0");

        // Use block information and user address as a seed for randomness
        bytes32 previousBlockNumberHash = blockhash(block.number - 1);
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    previousBlockNumberHash,
                    block.timestamp,
                    msg.sender
                )
            )
        );

        // Define characters to include in the random string
        string
            memory characters = "zGdFr0xHfPwKs43yhRJDepMjX6mEai8OSIWqQTZclUYoB95tnvbLV2Ag17uCNk";

        // Generate the random string
        bytes memory randomString = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            // Get a pseudo-random index based on the seed
            uint256 charIndex = (seed + i) % bytes(characters).length;

            // Set the character in the random string
            randomString[i] = bytes(characters)[charIndex];
        }

        return string(randomString);
    }

    function random(address _player, string memory _userSeed)
        public
        view
        returns (uint256)
    {
        bytes32 previousBlockNumberHash = blockhash(block.number - 1);
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(previousBlockNumberHash, _player, _userSeed)
            )
        );
        return randomNumber;
    }

    function roll(address _player, string memory _userSeed)
        public
        view
        returns (uint256)
    {
        uint256 randomNumber = random(_player, _userSeed);
        if (_player == casinoAddress) {
            return (randomNumber % 100) < 1 ? 6 : (randomNumber % 6) + 1;
        }
        return (randomNumber % 6) + 1;
    }

    function play(uint256 _index) public notPaused returns (uint256, uint256) {
        emit GameStarted(_index, msg.sender);
        Casino.Game memory game = casino.ensureGameIsNotPlayed(_index);
        require(
            game.player1 == msg.sender || game.player2 == msg.sender,
            "Player is not allowed to play game on this table."
        );
        string memory randomUserSeed = generateRandomString(randomness);
        uint256 player1Dice = roll(game.player1, randomUserSeed);
        uint256 player2Dice = roll(game.player2, randomUserSeed);

        if (player1Dice == player2Dice) {
            emit GameTie(_index);
            return (player1Dice, player2Dice);
        } else {
            address winner = player1Dice > player2Dice
                ? game.player1
                : game.player2;

            string memory player1DiceString = uintToString(player1Dice);
            string memory player2DiceString = uintToString(player2Dice);

            casino.winnerCallback(
                _index,
                winner,
                player1DiceString,
                player2DiceString
            );

            emit GameCompleted(
                _index,
                winner,
                randomUserSeed,
                player1DiceString,
                player2DiceString
            );
            return (player1Dice, player2Dice);
        }
    }

    function uintToString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp > 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value > 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function updateGameState(bool _paused) public restricted {
        paused = _paused;
    }

    modifier notPaused() {
        require(paused == false);
        _;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}