// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

enum Stage {
    PENDING,
    COMMIT,
    REVEAL,
    SETTLE,
    DRAW,
    SUCCESS
}

enum Choice {
    NONE,
    HIDDEN,
    BLOCK,
    PAPER,
    SCISSORS
}

struct Game {
    Player p1;
    Player p2;
    Stage stage;
    uint8 totalRounds;
    uint8 currentRound;
    uint72 pot;
    address winner;
    mapping(uint8 => Round) rounds;
}

struct Round {
    Choice p1Choice;
    Choice p2Choice;
    uint40 commitBlock;
    uint40 revealBlock;
    address winner;
}

struct Player {
    address player;
    uint96 wins;
    bytes32 commitment;
}

/// @title Interface for Roshambo contract
interface IRoshambo {
    error AlreadyCommitted();
    error AlreadyRevealed();
    error InsufficientBalance();
    error InsufficientWager();
    error InvalidChoice();
    error InvalidGame();
    error InvalidPlayer();
    error InvalidReveal();
    error InvalidRounds();
    error InvalidStage();
    error InvalidWager();
    error TimeElapsed();
    error TransferFailed();

    event NewGame(
        uint40 indexed _gameId,
        uint8 indexed _rounds,
        address indexed _player1,
        uint72 _wager
    );
    event JoinGame(uint40 indexed _gameId, address indexed _player2, uint72 indexed _pot);
    event Commit(
        uint40 indexed _gameId,
        uint8 indexed _round,
        address indexed _player,
        bytes32 _commitment,
        Stage _stage
    );
    event Reveal(
        uint40 indexed _gameId,
        uint8 indexed _round,
        address indexed _player,
        Choice _choice,
        Stage _stage
    );
    event ResetRound(uint40 indexed _gameId, uint8 indexed _round, uint40 indexed _commitBlock);
    event NextRound(uint40 indexed _gameId, uint8 indexed _round, uint40 indexed _commitBlock);
    event CurrentRound(uint40 indexed _gameId, uint8 indexed _round, uint40 indexed _revealBlock);
    event Settle(
        uint40 indexed _gameId,
        uint8 indexed _round,
        Stage indexed _stage,
        address _winner,
        address _player1,
        Choice _choice1,
        uint96 _p1Wins,
        address _player2,
        Choice _choice2,
        uint96 _p2Wins
    );
    event Cancel(uint40 indexed _gameId, address indexed _player1, uint72 indexed _wager);
    event Withdraw(address indexed _sender, address indexed _to, uint256 indexed _balance);

    function BLOCK_DURATION() external view returns (uint256);

    function MIN_WAGER() external view returns (uint256);

    function balances(address) external view returns (uint256);

    function beneficiary() external view returns (address);

    function cancel(uint40 _gameId) external;

    function commit(uint40 _gameId, bytes32 _commit) external;

    function currentId() external view returns (uint40);

    function getCommit(
        address _player,
        Choice _choice,
        string calldata _secret
    ) external pure returns (bytes32);

    function getUsageRate(
        address _player,
        Choice _choice
    ) external view returns (uint256, uint256, uint256);

    function getWinRate(address _player) external view returns (uint256, uint256, uint256, uint256);

    function getProfitMargin(address _player) external view returns (uint256, uint256, uint256);

    function getRound(
        uint40 _gameId,
        uint8 _round
    )
        external
        view
        returns (
            Choice player1Choice,
            Choice player2Choice,
            uint40 commitBlock,
            uint40 revealBlock,
            address winner
        );

    function joinGame(uint40 _gameId, bytes32 _commitment) external payable;

    function newGame(uint8 _rounds, bytes32 _commitment) external payable returns (uint40);

    function pause() external payable;

    function rake() external view returns (uint16);

    function reveal(uint40 _gameId, Choice _choice, string calldata _secret) external;

    function setBeneficiary(address _beneficiary) external payable;

    function setRake(uint16 _rake) external payable;

    function settle(uint40 _gameId) external;

    function totalSupply() external view returns (uint40);

    function unpause() external payable;

    function withdraw(address _to) external;
}
