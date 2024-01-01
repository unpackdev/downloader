// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BLACKHOLEGAME {
    struct Round {
        uint32 isOpen;
        uint32 additionalTime;
        uint32 startTime;
        address lastPlayer;
        uint256 entryTokens;
    }

    Round[] public Rounds;

    uint256 public entryTokens;
    uint256 public additionalTime;

    address public owner;

    IERC20 public blackholeToken;

    event NewEntry(uint256 indexed roundNumber, address indexed account);

    event RoundEnded(uint256 indexed roundNumber, address indexed account, uint256 totalPot);

    event RoundSkipped(address indexed account, uint256 totalPot);

    event NewRound(uint256 roundNumber);
    
    event BLACKHOLE();

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor () {
        owner = msg.sender;

        Rounds.push(Round(0, 100, 0, address(0xdead), 100 * 10 ** 18));
    }

    function play() external {
        require(msg.sender == tx.origin, "No bots allowed");

        uint256 roundNumber = Rounds.length - 1;
        Round storage round = Rounds[roundNumber];

        require(round.isOpen == 1, "Game has not started yet!");

        if (round.startTime + round.additionalTime > block.timestamp) {
            try blackholeToken.transferFrom(msg.sender, address(this), round.entryTokens) {
                round.startTime = uint32(block.timestamp);
                round.lastPlayer = msg.sender;

                emit NewEntry(roundNumber, msg.sender);
            }
            catch {
                revert("Please approve the usage of BLACKHOLE to the game contract to play and check if you have enough tokens");
            }
        }
        else {
            uint256 gameBalance = blackholeToken.balanceOf(address(this));

            blackholeToken.transfer(round.lastPlayer, gameBalance * 50 / 100);
            blackholeToken.transfer(address(0xdead), gameBalance * 20 / 100);

            emit RoundEnded(roundNumber, round.lastPlayer, gameBalance);

            Rounds.push(Round(1, uint32(additionalTime), uint32(block.timestamp), msg.sender, entryTokens));

            emit NewRound(roundNumber + 1);

            if (round.startTime + round.additionalTime + additionalTime < block.timestamp) {
                /*
                    this is the case when 2x additionalTime has passed since the end of the first round
                    meaning that while there was no tx to renew the round, the next round time has actually already passed
                    so the passed round will be skipped but the participant will receive some reward
                */

                gameBalance = blackholeToken.balanceOf(address(this));

                blackholeToken.transfer(msg.sender, gameBalance * 5 / 100);

                emit RoundSkipped(msg.sender, gameBalance);
            }
        }
    }

    function startTheGame() external onlyOwner {
        require(Rounds[0].isOpen == 0);
        Rounds[0].isOpen = 1;

        require(additionalTime > 0 && entryTokens > 0);
        Rounds[0].additionalTime = uint32(additionalTime);
        Rounds[0].startTime = uint32(block.timestamp);
        Rounds[0].entryTokens = entryTokens;

        require(blackholeToken.balanceOf(address(this)) > 0);

        emit BLACKHOLE();
    }

    function setBlackholeAddress(address blackholeAddress) external onlyOwner {
        require(address(blackholeToken) == address(0));

        blackholeToken = IERC20(blackholeAddress);
    }

    function changeNextRoundAdditionalTime(uint32 newAdditionalTime) external onlyOwner {
        require(newAdditionalTime <= 1 hours);

        additionalTime = newAdditionalTime;
    }

    function changeNextRoundEntryTokens(uint256 newEntryTokens) external onlyOwner {
        require(newEntryTokens <= 100);

        // apply 18 decimals here
        entryTokens = newEntryTokens * 10 ** 18;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    // view functions for dapp //
    //////////////////////////////////////////////////////////////////////////////////////

    function getData() external view returns(Round memory, uint256, uint256, uint256, uint256) {
        uint256 roundNumber = Rounds.length - 1;
        Round memory round = Rounds[roundNumber];

        uint256 endTime = round.startTime + round.additionalTime;
        uint256 remainingTime;
        if (endTime > block.timestamp) {
            remainingTime = endTime - block.timestamp;
        }
        else {
            remainingTime = 0;
        }

        return (round, roundNumber, remainingTime, block.timestamp, blackholeToken.balanceOf(address(this)));
    }

    function getDataForAccount(address account) external view returns(Round memory, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 roundNumber = Rounds.length - 1;
        Round memory round = Rounds[roundNumber];

        uint256 endTime = round.startTime + round.additionalTime;
        uint256 remainingTime;
        if (endTime > block.timestamp) {
            remainingTime = endTime - block.timestamp;
        }
        else {
            remainingTime = 0;
        }

        uint256 balance = blackholeToken.balanceOf(account);
        uint256 allowance = blackholeToken.allowance(account, address(this));

        return (round, roundNumber, remainingTime, block.timestamp, blackholeToken.balanceOf(address(this)), balance, allowance);
    }
}