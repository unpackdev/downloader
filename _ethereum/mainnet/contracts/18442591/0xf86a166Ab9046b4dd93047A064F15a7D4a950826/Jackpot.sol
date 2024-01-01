// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "./IERC20.sol";

contract Jackpot {
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

    mapping(uint256 => mapping(uint256 => Bet)) public bets;
    mapping(address => mapping(uint256 => uint256)) public totalVolume;
    mapping(address => mapping(uint256 => bool)) public isInGame;
    mapping(uint256 => uint256) public totalBets;

    IERC20 public token;

    // Current game number.
    uint public game;

    // All-time game jackpot.
    uint public allTimeJackpot = 0;
    // All-time game players count
    uint public allTimePlayers = 0;

    // Store game jackpot.
    mapping(uint => uint) jackpot;
    // Store game players.
    mapping(uint => address[]) public players;
    // Store total tickets for each game
    mapping(uint => uint) tickets;
    // Store game start block number.
    mapping(uint => uint) public gamestartblock;

    address payable public owner;
    address payable taxWallet;

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

    /**
     * @dev Start the new game.
     */
    function start() public onlyOwner {
        if (players[game].length > 0) {
            pickTheWinners();
        }
        startGame();
    }

    /**
     * @dev Stop the game.
     */
    function end() public onlyOwner {
        selfdestruct(payable(msg.sender));
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
    event Entry(address indexed from, uint indexed game);

    function deposit(address from, uint amount) public {
        require(
            msg.sender == address(token),
            "Stake by sending token to this contract"
        );

        totalVolume[from][game] += amount;

        uint newtotalstr = totalBets[game];
        bets[game][newtotalstr].addr = address(from);
        bets[game][newtotalstr].ticketstart = tickets[game] + 1;
        bets[game][newtotalstr].ticketend =
            ((tickets[game] + 1) + (amount / (100_000 * 10 ** 9))) -
            1;

        totalBets[game] += 1;
        jackpot[game] += amount;
        tickets[game] += (amount / (100_000 * 10 ** 9));

        if (!isInGame[from][game]) {
            players[game].push(from);
            isInGame[from][game] = true;
            emit Entry(from, game);
        }
    }

    /**
     * @dev Start the new game.
     * @dev Checks game status changes, if exists request for changing game status game status
     * @dev will be changed.
     */
    function startGame() internal {
        game += 1;
        gamestartblock[game] = block.timestamp;
        emit Game(game, block.timestamp);
    }

    function checkIfWinnerDuplicate(
        address[] memory list,
        address winner
    ) internal pure returns (bool) {
        uint i;
        for (i = 0; i < list.length; i++) {
            if (list[i] == winner) return true;
        }
        return false;
    }

    /**
     * @dev Pick the winner using random number provably fair function.
     */
    function pickTheWinner() internal returns (address) {
        uint winner = randomNumber(tickets[game]); //winning ticket
        uint256 lookingforticket = winner;
        address ticketwinner;
        for (uint8 i = 0; i <= totalBets[game]; i++) {
            address addr = bets[game][i].addr;
            uint256 ticketstart = bets[game][i].ticketstart;
            uint256 ticketend = bets[game][i].ticketend;
            if (
                lookingforticket >= ticketstart && lookingforticket <= ticketend
            ) {
                ticketwinner = addr; //finding winner address
            }
        }
        return ticketwinner;
    }

    function pickTheWinners() internal {
        address[] memory winners;
        uint toPlayer = address(this).balance;
        uint reward;
        uint i;
        uint j;

        if (players[game].length <= 5) {
            winners = players[game];
        } else {
            winners = new address[](5);
            for (i = 0; i < 50; i++) {
                address winner = pickTheWinner();
                if (checkIfWinnerDuplicate(winners, winner)) continue;
                winners[j] = winner;
                j = j + 1;
                if (j >= 5) {
                    break;
                }
            }
        }

        reward = toPlayer / winners.length;
        for (i = 0; i < winners.length; i++) {
            if (winners[i] != address(0)) {
                payable(winners[i]).transfer(reward);
            }
        }

        allTimeJackpot += toPlayer;
        allTimePlayers += players[game].length;
    }

    function recover() external onlyOwner {
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {}

    fallback() external payable {}
}
