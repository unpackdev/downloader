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

// File: bet.sol


pragma solidity ^0.8.0;


contract BettingContractEth {
    using SafeMath for uint256;
    address public admin;
    uint256 public totalEventsAmount;
    uint256 public numberOfEvents;
    address private adminTax = 0x6D725170dd10eA1b282939e1041e18f1640a4dA4;

    struct Pools {
        uint256 homeBalances;
        uint256 awayBalances;
        uint256 drawBalances;
        uint256 homeBettors;
        uint256 awayBettors;
        uint256 drawBettors;
        uint256 numberOfPools;
        bool isBettingOpen;
        uint256 winningPool;
        uint256 totalBetAmount;
    }

    struct BettorData {
        uint256 oddType;
        uint256 amount;
    }
    //which event
    //which oddType
    //amount
    mapping(uint256 => Pools) public BettingPools;
    mapping(address => mapping(uint256 => BettorData)) public userBets;

    event BetPlaced(
        address indexed user,
        uint256 pool,
        uint256 amount,
        uint256 eventId
    );
    event BettingClosed(uint256 winningPool);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier bettingOpen(uint256 _eventId) {
        Pools memory Bettingpool = BettingPools[_eventId];
        require(Bettingpool.winningPool == 0, "Betting Has ended");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Function to place bets with ERC20 tokens
    function placeBet(
        uint256 pool,
        uint256 eventId
    ) external payable bettingOpen(eventId) {
        uint256 amount = msg.value;
        require(pool > 0 && pool <= 3, "Invalid pool number");
        require(eventId > 0, "Invalid Events number");
        require(amount > 0, "Bet amount must be greater than 0");

        totalEventsAmount += amount;
        Pools storage Bettingpool = BettingPools[eventId];
        Bettingpool.totalBetAmount += amount;
        BettorData storage bettor = userBets[msg.sender][eventId];
        if (bettor.oddType > 0) {
            bettor.amount += amount;
            if (pool == 1) {
                Bettingpool.awayBalances += amount;
                Bettingpool.numberOfPools = 3;
            }
            if (pool == 2) {
                Bettingpool.drawBalances += amount;
                Bettingpool.numberOfPools = 3;
            }
            if (pool == 3) {
                Bettingpool.homeBalances += amount;
                Bettingpool.numberOfPools = 3;
            }
        } else {
            bettor.oddType = pool;
            bettor.amount += amount;
            if (pool == 1) {
                Bettingpool.awayBalances += amount;
                Bettingpool.awayBettors += 1;
                Bettingpool.numberOfPools = 3;
            }
            if (pool == 2) {
                Bettingpool.drawBalances += amount;
                Bettingpool.drawBettors += 1;
                Bettingpool.numberOfPools = 3;
            }
            if (pool == 3) {
                Bettingpool.homeBalances += amount;
                Bettingpool.homeBettors += 1;
                Bettingpool.numberOfPools = 3;
            }
        }

        emit BetPlaced(msg.sender, pool, amount, eventId);
    }

    function GetPoolBettors(
        uint256 _eventId
    ) public view returns (Pools memory) {
        return BettingPools[_eventId];
    }

    function closeBetting(
        uint256 _winningPool,
        uint256 _eventId
    ) external onlyAdmin bettingOpen(_eventId) {
        Pools storage Bettingpool = BettingPools[_eventId];
        require(_winningPool > 0 && _winningPool <= 3, "Invalid pool number");

        Bettingpool.isBettingOpen = false;
        Bettingpool.winningPool = _winningPool;

        emit BettingClosed(_winningPool);
    }

    function withdraw(uint256 _eventId) external {
        Pools storage Bettingpool = BettingPools[_eventId];
        BettorData storage bettor = userBets[msg.sender][_eventId];
        require(
            !Bettingpool.isBettingOpen,
            "Cannot withdraw while betting is still open"
        );
        require(Bettingpool.winningPool > 0, "Winning pool is not set yet");
        require(
            bettor.oddType == Bettingpool.winningPool,
            "You did not bet on the winning pool"
        );
        uint256 winningPoolBalance;
        if (Bettingpool.winningPool == 1) {
            winningPoolBalance = Bettingpool.awayBalances;
        }
        if (Bettingpool.winningPool == 2) {
            winningPoolBalance = Bettingpool.drawBalances;
        }
        if (Bettingpool.winningPool == 3) {
            winningPoolBalance = Bettingpool.homeBalances;
        }

        uint256 userWinningBet = bettor.amount;

        // uint256 totalWinningPoolBalance = winningPoolBalance + totalLosingPoolBalances();
        uint256 userShareFromWinningPool = (userWinningBet.mul(1000)).div(
            winningPoolBalance
        );

        uint256 totalLosingPoolBalance = totalLosingPoolBalances(_eventId);
        uint256 userShareFromLosingPools = (
            userShareFromWinningPool.mul(totalLosingPoolBalance)
        ).div(1000);

        // Calculate the total share to be transferred to the user
        uint256 totalUserShare = userWinningBet + userShareFromLosingPools;

        // Transfer the user's share of ERC20 tokens
        if (totalUserShare > 0) {
            uint256 fivePercent = (totalUserShare.div(100)).mul(5);
            payable(adminTax).transfer(fivePercent);
            payable(msg.sender).transfer(totalUserShare.sub(fivePercent));
        }

        // Reset user's bet on the winning pool
        bettor.amount = 0;
    }

    function totalLosingPoolBalances(
        uint256 _eventId
    ) internal view returns (uint256 total) {
        Pools memory Bettingpool = BettingPools[_eventId];
        if (Bettingpool.winningPool == 1) {
            total = Bettingpool.drawBalances + Bettingpool.homeBalances;
        }
        if (Bettingpool.winningPool == 2) {
            total = Bettingpool.awayBalances + Bettingpool.homeBalances;
        }
        if (Bettingpool.winningPool == 3) {
            total = Bettingpool.drawBalances + Bettingpool.awayBalances;
        }
    }

    function totalFundsInOtherPools(
        uint256 _poolId,
        uint256 _eventId
    ) internal view returns (uint256 total) {
        Pools memory Bettingpool = BettingPools[_eventId];
        if (_poolId == 1) {
            total = Bettingpool.drawBalances + Bettingpool.homeBalances;
        }
        if (_poolId == 2) {
            total = Bettingpool.awayBalances + Bettingpool.homeBalances;
        }
        if (_poolId == 3) {
            total = Bettingpool.drawBalances + Bettingpool.awayBalances;
        }
    }

    function getPoolBalanace(
        uint256 _poolId,
        uint256 _eventId
    ) public view returns (uint256) {
        uint256 total;
        Pools memory Bettingpool = BettingPools[_eventId];
        if (_poolId == 1) {
            total = Bettingpool.awayBalances;
        }
        if (_poolId == 2) {
            total = Bettingpool.drawBalances;
        }
        if (_poolId == 3) {
            total = Bettingpool.homeBalances;
        }

        return total;
    }

    function calculateOddsForSpecificPoolsForUser(
        uint256 _poolId,
        uint256 _eventId
    ) public view returns (uint256) {
        BettorData memory bettor = userBets[msg.sender][_eventId];
        uint256 totalUserShare;
        uint256 userWinningBet = bettor.amount;

        uint256 winningPoolBalance = getPoolBalanace(_poolId, _eventId);
        uint256 totalOtherPoolsBalance = totalFundsInOtherPools(
            _poolId,
            _eventId
        );
        if (winningPoolBalance > 0) {
            uint256 userShareFromWinningPool = (userWinningBet.mul(1000)).div(
                winningPoolBalance
            );

            uint256 userPossibleReward = (
                userShareFromWinningPool.mul(totalOtherPoolsBalance)
            ).div(1000);

            totalUserShare = userWinningBet + userPossibleReward;

            return totalUserShare / userWinningBet;
        } else {
            return totalUserShare = userWinningBet / userWinningBet;
        }
    }

    function calculateOddsForSpecificPools(
        uint256 _poolId,
        uint256 amount,
        uint256 _eventId
    ) public view returns (uint256) {
        uint256 userWinningBet = amount;
        uint256 totalUserShare;
        uint256 winningPoolBalance = getPoolBalanace(_poolId, _eventId) +
            amount;
        uint256 totalOtherPoolsBalance = totalFundsInOtherPools(
            _poolId,
            _eventId
        );
        uint256 userShareFromWinningPool = (userWinningBet.mul(1000)).div(
            winningPoolBalance
        );
        uint256 userPossibleReward = (
            userShareFromWinningPool.mul(totalOtherPoolsBalance)
        ).div(1000);

        totalUserShare = userWinningBet + userPossibleReward;

        return totalUserShare / amount;
    }
}