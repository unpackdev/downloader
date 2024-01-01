// SPDX-License-Identifier: MIT

// KEKW Casino Contract: 10 November 2023
// Version: 1.0

// Website: https://kekw.gg/
// telegram: https://t.me/kekw_gg
// X.com/Twtter: https://x.com/kekw_gg
// Token: ($KEKW) 0x0DF596AD12F927e41EC317AF7DD666cA3574845f
// Uniswap: https://app.uniswap.org/swap?outputCurrency=0x0DF596AD12F927e41EC317AF7DD666cA3574845f
// Dextools: https://www.dextools.io/app/en/ether/pair-explorer/0x14ba508aaf2c15231f9df265980d1d461e54192b

pragma solidity ^0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

error BetTooHigh(uint256 maximumBet);

contract KEKW_Casino {
    IERC20 public token;
    address public manager;
    mapping(address => uint256) public casinoBalances;
    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

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

    Game[] public games;
    address[] public gameContracts;
    uint256 public winnerPercentage = 95;
    uint256 public casinoPercentage = 3;
    uint256 public devPercentage = 100 - winnerPercentage - casinoPercentage;

    event GameCreated(uint256 gameIndex, uint256 betAmount);
    event GameJoined(uint256 gameIndex, address playerAddress);
    event GameCanceled(uint256 gameIndex);
    event GameLeft(uint256 gameIndex, address playerAddress);

    constructor(address _token) {
        manager = msg.sender;
        token = IERC20(_token);
    }

    function addNewGameContrtact(address _gameContract) public restricted {
        gameContracts.push(_gameContract);
    }

    function removeGameContract(uint256 _gameContractIndex) public restricted {
        if (_gameContractIndex >= gameContracts.length) return;

        for (
            uint256 i = _gameContractIndex;
            i < gameContracts.length - 1;
            i++
        ) {
            gameContracts[i] = gameContracts[i + 1];
        }
        gameContracts.pop();
    }

    function updateFees(
        uint256 _winnerFees,
        uint256 _casinoFees,
        uint256 _devFees
    ) public restricted {
        require(
            (_winnerFees + _devFees + _casinoFees) == 100,
            "Total should be 100."
        );
        winnerPercentage = _winnerFees;
        devPercentage = _devFees;
        casinoPercentage = _casinoFees;
    }

    function getSmartContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPlayersCasinoBalanace(address playerAddress)
        external
        view
        returns (uint256)
    {
        return casinoBalances[playerAddress];
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Minimum Amount should be greater than 0.");
        token.transferFrom(msg.sender, address(this), _amount);
        casinoBalances[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) public {
        require(
            casinoBalances[msg.sender] >= _amount,
            "You can't withdraw more than your balance."
        );
        token.transferFrom(address(this), msg.sender, _amount);
        casinoBalances[msg.sender] -= _amount;
    }

    function donate(uint256 _amount) public {
        require(_amount > 0, "Minimum Amount should be greater than 0.");
        token.transferFrom(msg.sender, address(this), _amount);
        casinoBalances[address(this)] += _amount;
    }

    function houseWithdraw(uint256 _amount) public restricted {
        require(
            casinoBalances[address(this)] >= _amount,
            "You can't withdraw more than your balance."
        );
        token.transferFrom(address(this), manager, _amount);
        casinoBalances[address(this)] -= _amount;
    }

    function createGame(uint256 _betAmount, address _gameContractAddress)
        public
    {
        require(_betAmount > 0, "Bet Amount should be greater than 0.");
        require(
            existingGameContract(_gameContractAddress),
            "Invalid Game contract."
        );
        Game storage game = games.push();
        uint256 _index = games.length - 1;

        game.index = _index;
        game.betAmount = _betAmount;
        game.gameContractAddress = _gameContractAddress;
        game.player1 = msg.sender;
        casinoBalances[msg.sender] -= _betAmount;
        game.totalBetAmount += _betAmount;
        emit GameCreated(_index, _betAmount);
    }

    function cancelGame(uint256 _index) public {
        require(_index >= 0, "Index should be greater than 0.");
        Game storage game = games[_index];
        require(game.winner == address(0), "Game already Played.");
        require(
            game.player1 == msg.sender,
            "Game creator can only cancel the game."
        );
        require(
            game.totalBetAmount > 0,
            "total bet amount should not be zero."
        );
        require(game.betAmount > 0, "bet amount should not be zero.");
        if (game.player2 != address(0)) {
            game.totalBetAmount -= game.betAmount;
            casinoBalances[game.player2] += game.betAmount;
        }
        game.totalBetAmount -= game.betAmount;
        casinoBalances[game.player1] += game.betAmount;
        game.player1 = address(0);
        game.player2 = address(0);
        emit GameCanceled(_index);
    }

    function ensureGameIsNotPlayed(uint256 _index)
        public
        view
        returns (Game memory)
    {
        require(_index >= 0, "Index should be greater than 0.");
        Game memory game = games[_index];
        require(game.betAmount > 0, "Bet is played or canceled.");
        require(game.totalBetAmount > 0, "Bet is played or canceled.");
        require(game.winner == address(0), "Game already Played.");
        require(game.player1 != address(0), "Player1 shuld join the game.");
        require(game.player2 != address(0), "Player2 shuld join the game.");
        return game;
    }

    function getUnplayedGames() public view returns (Game[] memory) {
        Game[] memory unPlayedGames = new Game[](games.length);

        uint256 count = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (
                games[i].betAmount > 0 &&
                games[i].totalBetAmount > 0 &&
                games[i].winner == address(0) &&
                games[i].player2 == address(0) &&
                games[i].player1 != address(0)
            ) {
                unPlayedGames[count] = games[i];
                count++;
            }
        }

        // Resize the array to remove any empty slots
        assembly {
            mstore(unPlayedGames, count)
        }

        return unPlayedGames;
    }

    function joinGame(uint256 _index) public {
        require(_index >= 0, "Index should be greater than 0.");
        Game storage game = games[_index];
        require(game.winner == address(0), "Game has ended.");
        require(game.player2 == address(0), "Game is full now.");
        require(
            casinoBalances[msg.sender] >= game.betAmount,
            "You do not have enough balance to join game."
        );
        casinoBalances[msg.sender] -= game.betAmount;
        game.player2 = msg.sender;
        game.totalBetAmount += game.betAmount;
        emit GameJoined(_index, msg.sender);
    }

    function leaveGame(uint256 _index) public {
        require(_index >= 0, "Index should be greater than 0.");
        Game storage game = games[_index];
        require(game.totalBetAmount > 0, "Bet is reset.");
        require(game.betAmount > 0, "Bet is reset.");
        require(game.winner == address(0), "Game has ended.");
        require(game.player2 == msg.sender, "You haven't joined this game.");
        game.player2 = address(0);
        game.totalBetAmount -= game.betAmount;
        casinoBalances[msg.sender] += game.betAmount;
        emit GameLeft(_index, msg.sender);
    }

    function inviteHouse(uint256 _index) public {
        require(_index >= 0, "Index should be greater than 0.");
        Game storage game = games[_index];
        require(
            game.player1 == msg.sender,
            "Game creator can only invite house to play."
        );
        require(game.winner == address(0), "Game has ended.");
        require(game.player2 == address(0), "Game is full now.");
        require(
            casinoBalances[address(this)] >= game.betAmount,
            "House does not have enough balance to join game."
        );
        uint256 maximumBet = (casinoBalances[address(this)] * 1) / 100;
        if (game.betAmount > maximumBet) {
            // https://soliditylang.org/blog/2021/04/21/custom-errors/
            revert BetTooHigh({maximumBet: maximumBet});
        }
        casinoBalances[address(this)] -= game.betAmount;
        game.player2 = address(this);
        game.totalBetAmount += game.betAmount;
        emit GameJoined(_index, address(this));
    }

    function existingGameContract(address _gameContract)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < gameContracts.length; i++) {
            if (gameContracts[i] == _gameContract) {
                return true;
            }
        }

        return false;
    }

    function winnerCallback(
        uint256 gameIndex,
        address winnerAddress,
        string memory _player1Outcome,
        string memory _player2Outcome
    ) public {
        require(
            existingGameContract(msg.sender),
            "You are not Authorized Game Contract Address."
        );
        require(gameIndex >= 0, "Invalid Game.");
        Game storage game = games[gameIndex];
        require(game.player1 != address(0), "Player1 shuld join the game.");
        require(game.player2 != address(0), "Player2 shuld join the game.");
        require(game.winner == address(0), "Game already Played.");
        require(
            game.gameContractAddress == msg.sender,
            "Game type is not correct."
        );
        game.player1Outcome = _player1Outcome;
        game.player2Outcome = _player2Outcome;

        casinoBalances[manager] += (game.totalBetAmount * devPercentage) / 100;
        casinoBalances[address(this)] +=
            (game.totalBetAmount * casinoPercentage) /
            100;

        game.winner = winnerAddress;

        casinoBalances[winnerAddress] += ((game.totalBetAmount *
            winnerPercentage) / 100);

        game.totalBetAmount = 0;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}