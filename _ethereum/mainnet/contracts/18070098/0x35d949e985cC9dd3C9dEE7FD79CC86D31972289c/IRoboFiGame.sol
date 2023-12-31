// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IConfigurator.sol";
import "./IDABotManager.sol";


enum RoundState { NotFinished, RoundClosed, Finished }

struct Ticket {
    uint32 ticketId;
    uint112 lower;
    uint112 upper;
}

struct RoundData {
    uint64 startTime;           // time for game start (in seconds)
    uint64 commitPhaseDuration; // time for commit period (in seconds)
    uint64 revealPhaseDuration; // time for reveal period (in seconds)
    uint8 state;                // 0 - not finished, 1 - finished
    bool noWinnerAllowed;
    uint8 numberWinners;
    uint secretHash;            // hash of the random secret number by backend to generate randseed
    uint randSeed;              // current randseed value
    uint prize;
}

struct GameRound {
    RoundData data;
    mapping(address => uint) committedHashes;
}

struct GameSetting {
    bool noWinnerAllowed;
    uint8 numberWinners;
    uint64 commitPhaseDuration;
    uint64 revealPhaseDuration;
    uint112 lastTicketNumber;
    uint32 lastTicketId;
}

interface IRoboFiGameEvent {
    event GenerateTicket(address indexed bot, address indexed account, uint32 ticketId, uint112 lower, uint112 upper);
    event DeleteTicket(address indexed bot, address indexed account, uint32 ticketId);
    event UpdateTicket(address indexed bot, address indexed account, uint32 ticketId, uint112 newLower);
    event StartRound(address indexed bot, uint roundId, uint64 startTime, uint64 commitPhaseDuration,
                     uint64 revealPhaseDuration, uint prizePool);
    event Submit(address indexed bot, address indexed account, uint roundId, uint secretHash);
    event Reveal(address indexed bot, address indexed account, uint roundId);
    event CloseRound(address indexed bot, uint roundId, uint randSeed);
    event RoundWinner(address indexed bot, uint roundId, address[] winners, uint112[] wonNumbers,
                      uint32[] wonNumberOffsets, uint32[] wonTicketLocalIndexes, uint32[] ticketIds,
                      uint112 lastTicketNumber);
}

interface IRoboFiGame is IRoboFiGameEvent {
    function getUserTickets(address bot, address account) external view returns(Ticket[] memory);
    function randSeed(address bot, uint roundId) external view returns (uint);
    function getCurrentRoundId(address bot) external view returns(int);
    function getRoundDetails(address bot, uint roundId) external view returns (RoundData memory);
    function getBotGameSettings(address bot) external view returns (GameSetting memory);
    function getLastTicketNumber(address bot) external view returns(uint);
    function getBotPrize(address bot) external view returns(uint);

    function initialize(IDABotManager manager, IBotVaultManager botVault, IConfigurator config) external;
    function setBotManager(IDABotManager manager) external;
    function setVaultManager(IBotVaultManager botVault) external;
    function setConfigurator(IConfigurator config) external;
    function generateTicket(address bot, address account, address botToken, uint112 amount) external;
    function deleteTicket(address bot, address account, address botToken, uint112 amount) external;
    function startRound(address bot, uint secretHash) external;
    function submit(address bot, uint secretHash) external;
    function reveal(address bot, uint secretNumber) external;
    function submitAndReveal(address bot, uint secretNumber) external;
    function closeRound(address bot, uint secretNumber) external;
    function submitWinners(address bot, address[] memory winners, uint32[] memory wonNumberOffsets,
                           uint32[] memory wonTicketLocalIndexes) external;
    function updateGameSettings(address bot, bool noWinnerAllowed, uint8 numberWinners,
                                uint64 commitPhaseDuration, uint64 revealPhaseDuration) external;
}
