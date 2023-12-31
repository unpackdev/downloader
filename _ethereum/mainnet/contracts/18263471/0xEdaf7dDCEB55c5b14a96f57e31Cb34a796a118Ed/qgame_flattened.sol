// SPDX-License-Identifier: MIT

// https://playquiz.xyz

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @looksrare/contracts-libs/contracts/interfaces/IReentrancyGuard.sol


pragma solidity ^0.8.17;

/**
 * @title IReentrancyGuard
 * @author LooksRare protocol team (👀,💎)
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}

// File: @looksrare/contracts-libs/contracts/ReentrancyGuard.sol


pragma solidity ^0.8.17;

// Interfaces


/**
 * @title ReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 private _status;

    /**
     * @notice Modifier to wrap functions to prevent reentrancy calls.
     */
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrancyFail();
        }

        _status = 2;
        _;
        _status = 1;
    }

    constructor() {
        _status = 1;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/qgame.sol


/*
    https://playquiz.xyz
*/
pragma solidity ^0.8.0;






contract QuizGame is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20 public gameToken;

    // 80% of the pot that is shared between winners
    // 20% goes to the treasury to account for fees and promotions
    uint256 public prizePercentage = 80;

    // Time before startDate to start blocking new users joining the game
    uint256 public joinGameDeadline = 2 minutes;
    uint256 public maxPlayers = 1000;
    uint256 public currentRoundId = 0;

    mapping(uint256 => Game) public games;

    // The total each address can withdraw
    mapping(address => uint256) public unclaimedPrizes;

    // The total each address has of free play credits
    // This is used for promotional purposes.
    // This amount cannot be withdrawn, it can only be used
    // to play games for free.
    mapping(address => uint256) public freePlayCredits;

    // Total unclaimed balance summing all of unclaimedPrizes
    uint256 unclaimedTotal = 0;

    // Total free play credits summing all of freePlayCredits
    uint256 freePlayCreditsTotal = 0;

    // Allow claiming/withdrawing prizes
    // Clam will be disabled during our
    // pre-launch free games
    // Then after the token launch it will open
    bool public claimEnabled = false;

    // Allow users to play with free play credits
    bool public freePlayCreditsEnabled = true;

    struct Player {
        bool joined;
        uint256 score;
    }

    struct Game {
        uint256 roundId;
        uint256 entryPrice;
        uint256 totalPot;
        uint256 prizePerWinner;
        uint256 playerCount;
        uint256 numQuestions;
        uint256 startDate;
        bool settled;
        mapping(address => Player) players;
        address[] playerList;
        mapping(uint256 => address[]) scoreToWallet;
    }

    event NewRoundOpen(uint256 roundId, uint256 startDate);
    event AdditionalFundsAddedToRound(uint256 roundId, uint256 value);
    event PlayerJoined(uint256 roundId, address player, uint256 entryPrice);
    event RoundSettled(uint256 roundId, uint256 totalPrize, uint256 prizePerWinner, address[] winners);
    event ClaimedPrize(address winner, uint256 prize);
    event FreePlayCreditsGiven(address[] players, uint256 credits);
    event FreePlayCreditsRemoved(address[] players, uint256 totalRemoved);

    event StartDateUpdated(uint256 roundId, uint256 startDate);

    modifier lastRoundSettled() {
        require(games[currentRoundId].settled, "Current round not settled yet");
        _;
    }

    constructor(
        address _gameTokenAdd,
        uint256 _maxPlayers,
        uint256 _prizePercentage
    ) {
        gameToken = IERC20(_gameTokenAdd);
        maxPlayers = _maxPlayers;
        prizePercentage = _prizePercentage;

        // Create an empty round id = 0, settled = true
        Game storage g = games[currentRoundId];
        g.roundId = currentRoundId;
        g.entryPrice = 0;
        g.settled = true;
    }

    /**
        Allows users to claim their available prizes.
        Function requires claimEnabled to be set true
        and that the user balance of unclaimed prizes
        is greater than 0.

        The user unclaimed prize balance is stored in
        `unclaimedPrizes` and the contract's total
        unclaimed balance is stores in `unclaimedTotal`
        After successfully sending the tokens to the user,
        this function will zero the user's unclaimed balance
        and subtract this amount from the contrac't unclaimed
        total.
    */

    function claimPrize() external nonReentrant {
        require(claimEnabled, "Withdrawing not enabled yet.");
        uint256 playerPrize = unclaimedPrizes[msg.sender];
        require(playerPrize > 0, "No prize to claim");

        bool claimed = gameToken.transfer(
            msg.sender,
            playerPrize
        );

        require(claimed, "Failed to claim prize");

        unclaimedTotal = unclaimedTotal.sub(playerPrize);
        unclaimedPrizes[msg.sender] = 0;
        emit ClaimedPrize(msg.sender, playerPrize);
    }

    function startNewRound(
        uint256 _roundId,
        uint256 _entryPrice,
        uint256 _startDate,
        uint256 _numQuestions
    ) external onlyOwner nonReentrant lastRoundSettled {

        require(_roundId > currentRoundId, "Use incremental roundId numbers");

        currentRoundId = _roundId;

        Game storage g = games[currentRoundId];
        g.roundId = _roundId;
        g.entryPrice = _entryPrice;
        g.startDate = _startDate;
        g.numQuestions = _numQuestions;

        emit NewRoundOpen(_roundId, _startDate);
    }

    function joinGame() external payable nonReentrant {
        Game storage g = games[currentRoundId];

        require(g.settled == false, "Game has settled");
        require(block.timestamp < (g.startDate - joinGameDeadline), "Game not available to join");
        require(g.playerCount < maxPlayers, "Max players reached");
        require(
            g.players[msg.sender].joined == false,
            "User already joined"
        );
        bool paid = false;
        //uint256 storage unclaimedPlayerBalance = unclaimedPrizes[msg.sender];
        //uint256 storage playerFreePlayCredits = freePlayCredits[msg.sender];

        // Free game, don't charge
        if (g.entryPrice == 0) {
            paid = true;
        }

            // If the player has free credits balance, then use it instead of
            // using unclaimed balance or transferring tokens
        else if (freePlayCreditsEnabled && freePlayCreditsTotal >= g.entryPrice) {
            freePlayCredits[msg.sender] = freePlayCredits[msg.sender].sub(g.entryPrice);
            freePlayCreditsTotal = freePlayCreditsTotal.sub(g.entryPrice);
            paid = true;
        }

            // If the player has unclaimed balance, then use it instead of
            // transferring tokens
        else if (unclaimedPrizes[msg.sender] >= g.entryPrice) {
            unclaimedPrizes[msg.sender] = unclaimedPrizes[msg.sender].sub(g.entryPrice);
            unclaimedTotal = unclaimedTotal.sub(g.entryPrice);
            paid = true;
        }
            // The game is not free and the player does not have
            // free credits or unclaimed prizes, then transfer tokens
        else {
            require(
                gameToken.allowance(msg.sender, address(this)) >= g.entryPrice,
                "Not enough allowance"
            );
            paid = gameToken.transferFrom(
                msg.sender,
                address(this),
                g.entryPrice
            );
        }

        require(paid, "Failed to pay the entry price");

        Player memory p;
        p.joined = true;
        p.score = 0;

        g.players[msg.sender] = p;
        g.playerList.push(msg.sender);
        g.totalPot = g.totalPot.add(g.entryPrice);
        ++g.playerCount;

        emit PlayerJoined(currentRoundId, msg.sender, g.entryPrice);
    }

    function forceSettleRound() external onlyOwner nonReentrant {
        Game storage g = games[currentRoundId];
        g.settled = true;
    }

    function settleRound(uint256[] memory correctAnswers, address[] memory winnersAddresses, uint256 maxScore) external onlyOwner nonReentrant {
        Game storage g = games[currentRoundId];
        require(!g.settled, "Game has already been settled");
        require(correctAnswers.length == g.numQuestions, "Incorrect answers length");
        require(winnersAddresses.length <= g.playerCount, "Mismatch between contract joined players and answers array");

        uint256 totalPrize = 0;
        uint256 prizePerWinner = 0;

        // Store winners only if maxScore is > 0
        // If nobody makes any point, then it is not considered a win
        if(maxScore > 0) {
            // Save scores
            for (uint256 i = 0; i < winnersAddresses.length; i++) {
                require(
                    g.players[winnersAddresses[i]].joined == true,
                    "Sent answer address has not joined in current game"
                );
                g.players[winnersAddresses[i]].score = maxScore;
                g.scoreToWallet[maxScore].push(winnersAddresses[i]);
            }

            // Compute prize
            totalPrize = g.totalPot.mul(prizePercentage).div(100);
            // Divide the prize by the total number of winners
            prizePerWinner = totalPrize.div(g.scoreToWallet[maxScore].length);

            g.prizePerWinner = prizePerWinner;
            for (uint256 i = 0; i < g.scoreToWallet[maxScore].length; i++) {
                unclaimedPrizes[g.scoreToWallet[maxScore][i]] = unclaimedPrizes[g.scoreToWallet[maxScore][i]].add(prizePerWinner);
            }
            unclaimedTotal = unclaimedTotal.add(totalPrize);
        }

        g.settled = true;

        emit RoundSettled(
            g.roundId,
            totalPrize,
            prizePerWinner,
            g.scoreToWallet[maxScore]
        );
    }

    function setGameToken(address _tokenAddress) external onlyOwner nonReentrant {
        gameToken = IERC20(_tokenAddress);
    }

    // Add funds from the Contract to the current game's total pot
    // This will be used for promotions and free games where
    // funds from the treasury will be used as prizes
    function addContractFundsToRound(uint256 value) external payable onlyOwner nonReentrant {
        Game storage g = games[currentRoundId];
        require(g.settled == false, "Game has settled");
        require(
            getAvailableContractBalance() >= value,
            "Not enough balance in the contract"
        );

        g.totalPot = g.totalPot.add(value);
        emit AdditionalFundsAddedToRound(currentRoundId, value);
    }

    function setMaxPlayers(uint256 _maxPlayers) external onlyOwner {
        maxPlayers = _maxPlayers;
    }

    function getPlayerScore(uint256 _gameId, address _player) public view returns (uint256) {
        return games[_gameId].players[_player].score;
    }

    function getPlayerList(uint256 _gameId) public view returns (address[] memory){
        Game storage g = games[_gameId];
        address[] memory addresses = new address[](g.playerCount);
        for (uint i = 0; i < g.playerCount; i++) {
            addresses[i] = g.playerList[i];
        }
        return addresses;
    }

    function getEntryPrice(uint256 _gameId) public view returns (uint256){
        return games[_gameId].entryPrice;
    }

    function getTotalPot(uint256 _gameId) public view returns (uint256){
        return games[_gameId].totalPot;
    }

    function getPrizePerWinner(uint256 _gameId) public view returns (uint256){
        return games[_gameId].prizePerWinner;
    }

    function getPlayerCount(uint256 _gameId) public view returns (uint256){
        return games[_gameId].playerCount;
    }

    function getNumQuestions(uint256 _gameId) public view returns (uint256){
        return games[_gameId].numQuestions;
    }

    function getStartDate(uint256 _gameId) public view returns (uint256){
        return games[_gameId].startDate;
    }

    function isGameSettled(uint256 _gameId) public view returns (bool){
        return games[_gameId].settled;
    }

    function getUnclaimedTotal() external view returns (uint256) {
        return unclaimedTotal;
    }

    function getFreePlayCreditsTotal() external view returns (uint256) {
        return freePlayCreditsTotal;
    }

    function getAvailableContractBalance() public view returns (uint256) {
        return gameToken.balanceOf(address(this))
        .sub(unclaimedTotal)
        .sub(games[currentRoundId].settled ? 0 : games[currentRoundId].totalPot)
        .sub(freePlayCreditsTotal);
    }

    function getPlayerUnclaimedPrize(address _player) public view returns (uint256) {
        return unclaimedPrizes[_player];
    }

    function getPlayerFreeCredits(address _player) public view returns (uint256) {
        return freePlayCredits[_player];
    }

    function withdrawAvailableBalance(address to) external onlyOwner nonReentrant {
        uint256 value = getAvailableContractBalance();
        gameToken.transfer(to, value);
    }

    function withdrawBalance(address to, uint256 value) external onlyOwner nonReentrant {
        require(getAvailableContractBalance() >= value, "Not enough balance");
        gameToken.transfer(to, value);
    }

    function setCurrentRoundStartDate(uint256 _startDate) external onlyOwner nonReentrant {
        games[currentRoundId].startDate = _startDate;
        emit StartDateUpdated(currentRoundId, _startDate);
    }

    function setJoinGameDeadline(uint256 _joinGameDeadline) external onlyOwner {
        joinGameDeadline = _joinGameDeadline;
    }

    function setClaimEnabled(bool _claimEnabled) external onlyOwner nonReentrant {
        claimEnabled = _claimEnabled;
    }

    function setFreePlayCreditsEnabled(bool _freePlayCreditsEnabled) external onlyOwner nonReentrant {
        freePlayCreditsEnabled = _freePlayCreditsEnabled;
    }

    function setPrizePercentage(uint256 _prizePercentage) external onlyOwner {
        prizePercentage = _prizePercentage;
    }

    function giveFreeCredits(address[] memory players, uint256 credits) external onlyOwner nonReentrant {
        require(credits > 0, "credits should be greater than 0");
        require(players.length > 0, "There should be at least one player");

        uint256 total = players.length.mul(credits);
        require(total < getAvailableContractBalance(), "Not enough contract balance");

        for (uint256 i = 0; i < players.length; i++) {
            freePlayCredits[players[i]] = freePlayCredits[players[i]].add(credits);
        }
        freePlayCreditsTotal = freePlayCreditsTotal.add(total);
        emit FreePlayCreditsGiven(players, credits);
    }

    function removeFreeCredits(address[] memory players) external onlyOwner nonReentrant {
        require(players.length > 0, "There should be at least one player");

        uint256 totalRemoved = 0;

        for (uint256 i = 0; i < players.length; i++) {
            totalRemoved = totalRemoved.add(freePlayCredits[players[i]]);
            freePlayCredits[players[i]] = 0;
        }
        freePlayCreditsTotal = freePlayCreditsTotal.sub(totalRemoved);
        emit FreePlayCreditsRemoved(players, totalRemoved);
    }

    function emergencyWithdrawToken(address tokenAddress, address to) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw");

        token.transfer(to, tokenBalance);
    }

    function emergencyWithdrawEther(address payable to) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");

        (bool success, ) = to.call{value: contractBalance}("");
        require(success, "Withdraw failed");
    }

    function withdrawExcessFunds(address payable to) external onlyOwner nonReentrant {
        payable(to).transfer(address(this).balance);
    }
}
