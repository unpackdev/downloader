// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract ETHPotJackpot {
    /**
     * @dev Write to log info about the new game.
     *
     * @param _game Game number.
     * @param _time Time when game stated.
     
     */
    event Game(uint _game, uint indexed _time);

    struct Bet {
        address addr;
        uint256 ticketstart;
        uint256 ticketend;
    }
    struct StakingInfo {
        uint depositTime;
        uint balance;
    }

    mapping(uint256 => mapping(uint256 => Bet)) public bets;
    mapping(address => StakingInfo) public stakeInfo;
    mapping(uint256 => uint256) public totalBets;

    //winning tickets history
    mapping(uint256 => uint256) public ticketHistory;

    //winning address history
    mapping(uint256 => address) public winnerHistory;

    IERC20 public token;

    // Game fee.
    uint8 public fee = 10;
    // Current game number.
    uint public game;
    // Min token deposit jackpot
    uint public minethjoin = 100 * 10 ** 9;

    // Game status
    // 0 = running
    // 1 = stop to show winners animation

    uint public gamestatus = 0;

    // All-time game jackpot.
    uint public allTimeJackpot = 0;
    // All-time game players count
    uint public allTimePlayers = 0;

    // Game status.
    bool public isActive = true;
    // The variable that indicates game status switching.
    bool public toogleStatus = false;
    // The array of all games
    uint[] public games;

    // Store game jackpot.
    mapping(uint => uint) jackpot;
    // Store game players.
    mapping(uint => address[]) players;
    // Store total tickets for each game
    mapping(uint => uint) tickets;
    // Store bonus pool jackpot.
    mapping(uint => uint) bonuspool;
    // Store game start block number.
    mapping(uint => uint) gamestartblock;

    address payable public owner;

    uint counter = 1;

    /**
     * @dev Check sender address and compare it to an owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    /**
     * @dev Initialize game.
     * @dev Create ownable and stats aggregator instances,
     * @dev set funds distributor contract address.
     *
     */

    constructor() {
        owner = payable(msg.sender);
        startGame();
    }

    /**
     * @dev The method that allows buying tickets by directly sending ether to the contract.
     */

    function setToken(address _address) external onlyOwner {
        require(address(token) == address(0));
        token = IERC20(_address);
    }

    function addBonus() public payable {
        bonuspool[game] += msg.value;
    }

    function playerticketstart(
        uint _gameid,
        uint _pid
    ) public view returns (uint256) {
        return bets[_gameid][_pid].ticketstart;
    }

    function playerticketend(
        uint _gameid,
        uint _pid
    ) public view returns (uint256) {
        return bets[_gameid][_pid].ticketend;
    }

    function totaltickets(uint _uint) public view returns (uint256) {
        return tickets[_uint];
    }

    function playeraddr(uint _gameid, uint _pid) public view returns (address) {
        return bets[_gameid][_pid].addr;
    }

    /**
     * @dev Returns current game players.
     */
    function getPlayedGamePlayers() public view returns (uint) {
        return getPlayersInGame(game);
    }

    /**
     * @dev Get players by game.
     *
     * @param playedGame Game number.
     */
    function getPlayersInGame(uint playedGame) public view returns (uint) {
        return players[playedGame].length;
    }

    /**
     * @dev Returns current game jackpot.
     */
    function getPlayedGameJackpot() public view returns (uint) {
        return getGameJackpot(game);
    }

    /**
     * @dev Get jackpot by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getGameJackpot(uint playedGame) public view returns (uint) {
        return jackpot[playedGame] + bonuspool[playedGame];
    }

    /**
     * @dev Get bonus pool by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getBonusPool(uint playedGame) public view returns (uint) {
        return bonuspool[playedGame];
    }

    /**
     * @dev Get game start block by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getGamestartblock(uint playedGame) public view returns (uint) {
        return gamestartblock[playedGame];
    }

    /**
     * @dev Get total ticket for game
     */
    function getGameTotalTickets(uint playedGame) public view returns (uint) {
        return tickets[playedGame];
    }

    /**
     * @dev Start the new game.
     */
    function start() public onlyOwner {
        if (players[game].length > 0) {
            pickTheWinner();
        } else {
            bonuspool[game + 1] = bonuspool[game];
        }
        startGame();
    }

    /**
     * @dev Start the new game.
     */
    function setGamestatusZero() public onlyOwner {
        gamestatus = 0;
    }

    /**
     * @dev Get random number. It cant be influenced by anyone
     * @dev Random number calculation depends on block timestamp,
     * @dev difficulty, counter and jackpot players length.
     *
     */
    function randomNumber(uint number) internal returns (uint) {
        counter++;
        uint random = uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    counter,
                    players[game].length,
                    gasleft()
                )
            )
        ) % number;
        return random + 1;
    }

    /**
     * @dev adds the player to the jackpot game.
     */

    function deposit(address from, uint amount) public {
        require(
            msg.sender == address(token),
            "Stake by sending token to this contract"
        );
        require(isActive);
        require(gamestatus == 0);
        require(amount >= minethjoin, "Amount must be greater than 100 token");

        stakeInfo[from].depositTime = block.timestamp;
        stakeInfo[from].balance += amount;

        uint newtotalstr = totalBets[game];
        bets[game][newtotalstr].addr = address(from);
        bets[game][newtotalstr].ticketstart = tickets[game] + 1;
        bets[game][newtotalstr].ticketend =
            ((tickets[game] + 1) + (amount / (100 * 10 ** 9))) -
            1;

        totalBets[game] += 1;
        jackpot[game] += amount;
        tickets[game] += (amount / (100 * 10 ** 9));

        players[game].push(from);
    }

    /**
     * @dev Withdraw token
     */
    function withdraw() public {
        require(stakeInfo[msg.sender].balance > 0, "Your balance is zero");
        require(
            block.timestamp > stakeInfo[msg.sender].depositTime + 1 days,
            "Withdraw is not available"
        );
        token.transfer(msg.sender, stakeInfo[msg.sender].balance);
        stakeInfo[msg.sender].balance = 0;
    }

    /**
     * @dev Start the new game.
     * @dev Checks game status changes, if exists request for changing game status game status
     * @dev will be changed.
     */
    function startGame() internal {
        require(isActive);

        game += 1;
        if (toogleStatus) {
            isActive = !isActive;
            toogleStatus = false;
        }
        gamestartblock[game] = block.timestamp;
        emit Game(game, block.timestamp);
    }

    /**
     * @dev Pick the winner using random number provably fair function.
     */
    function pickTheWinner() internal {
        uint winner;
        uint toPlayer = address(this).balance;
        if (players[game].length == 1) {
            payable(players[game][0]).transfer(toPlayer);
            winner = 0;
            ticketHistory[game] = 1;
            winnerHistory[game] = players[game][0];
        } else {
            winner = randomNumber(tickets[game]); //winning ticket
            uint256 lookingforticket = winner;
            address ticketwinner;
            for (uint8 i = 0; i <= totalBets[game]; i++) {
                address addr = bets[game][i].addr;
                uint256 ticketstart = bets[game][i].ticketstart;
                uint256 ticketend = bets[game][i].ticketend;
                if (
                    lookingforticket >= ticketstart &&
                    lookingforticket <= ticketend
                ) {
                    ticketwinner = addr; //finding winner address
                }
            }

            ticketHistory[game] = lookingforticket;
            winnerHistory[game] = ticketwinner;

            payable(ticketwinner).transfer(toPlayer); //send prize to winner
        }

        allTimeJackpot += toPlayer;
        allTimePlayers += players[game].length;
    }

    function updatePrice(uint new_price) external onlyOwner {
        minethjoin = new_price;
    }

    function recover_ETH() external {
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {}

    fallback() external payable {}
}