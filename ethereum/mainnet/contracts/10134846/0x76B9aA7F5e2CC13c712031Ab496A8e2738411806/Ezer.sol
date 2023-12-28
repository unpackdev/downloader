// File: contracts/SafeMath.sol

pragma solidity ^0.5.17;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Ezer.sol

pragma solidity ^0.5.17;

pragma experimental ABIEncoderV2;



contract Ezer {
    using SafeMath for uint256;

    uint256 public MIN_STAKE = 0.1 ether;
    uint8 public CONTRACT_FEE_PERCENT = 1;
    uint8 public ORACLE_FEE_PERCENT = 9;
    uint8 public constant MAX_OUTCOMES_COUNT = 5;
    uint16 public constant MAX_TITLE_LENGTH = 96;
    uint16 public constant MAX_DESCRIPTION_LENGTH = 96;

    uint8 public constant POOL_SIZE = 15;
    uint8 public constant MIN_SUCCESS_COUNT = 9;
    uint8 public constant CATEGORIES_COUNT = 8;
    uint8 public constant HISTORY_SIZE = 15;
    uint8 public constant MAX_PLAYERS = 50;

    enum EventState {open, closed, canceled}

    enum PoolState {open, closed, canceled}

    struct Pool {
        uint256[CATEGORIES_COUNT] banks;
        uint256 bank;
        uint256 jackpot;
        uint256 maxWinning;
        address payable[] players;
        string[POOL_SIZE] titles;
        string[POOL_SIZE] descriptions;
        uint64[POOL_SIZE] expiries;
        uint8 outcomes;
        uint8[CATEGORIES_COUNT] percents;
        uint32 id;
        PoolState state;
        uint8 jackpotPercent;
        int8[POOL_SIZE] results;
        EventState[POOL_SIZE] states;
    }

    struct Ticket {
        uint256 stake;
        uint256 winning;
        bytes15 outcomes;
        uint8 categories;
        bool jackpot;
    }

    enum Categories {
        success9,
        success10,
        success11,
        success12,
        success13,
        success14,
        success15,
        losing
    }

    event logNewPool(uint32 _id, string _firstEvent);

    event logPayment(
        address indexed _player,
        uint32 indexed _poolId,
        uint256 _winning,
        bool indexed _isJackpot
    );

    event logFailedPayment(
        address indexed _player,
        uint32 indexed _poolId,
        uint256 _winning,
        bool indexed _isJackpot
    );

    address payable public owner;
    address payable public oracle;
    uint256 public contractFee;
    uint256 public jackpot;
    uint256 public newJackpot;

    uint32[] poolIds;
    mapping(uint32 => Pool) pools;
    mapping(address => uint32[]) playerPools;
    mapping(uint32 => mapping(address => Ticket)) tickets; // poolId => player => ticket

    constructor() public {
        owner = msg.sender;
        createOracle(owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOracle() {
        require(
            msg.sender == oracle || msg.sender == owner,
            "Sender is not oracle"
        );
        _;
    }

    /// Withdraw jackpot and contract fee to owner
    function kill() external onlyOwner {
        if (jackpot > 0) withdrawJackpot(owner, jackpot);
        if (contractFee > 0) withdrawContractFee(owner, contractFee);
        selfdestruct(owner);
    }

    /// Change minimum stake
    /// @param minStake Minimum stake
    function changeMinStake(uint256 minStake) external onlyOwner {
        require(minStake > 0, "Incorrect minimum stake amount");
        MIN_STAKE = minStake;
    }

    /// Change contract fee percent of the stake
    /// @param contractFeePercent Contract fee percent
    function changeContractFeePercent(uint8 contractFeePercent)
        external
        onlyOwner
    {
        require(contractFeePercent < 100, "Incorrect percent value");
        CONTRACT_FEE_PERCENT = contractFeePercent;
    }

    /// Change oracle fee percent of the stake
    /// @param oracleFeePercent Oracle fee percent
    function changeOracleFeePercent(uint8 oracleFeePercent) external onlyOwner {
        require(oracleFeePercent < 100, "Incorrect percent value");
        ORACLE_FEE_PERCENT = oracleFeePercent;
    }

    /// Create new pool bets
    /// @dev Id of the new pool saved in emitted event
    /// @notice Events must be sorted by expiries
    /// @param titles Array of event titles
    /// @param descriptions Array of event descriptions
    /// @param expiries Array of event expiries
    /// @param outcomes Count of outcomes
    function createPool(
        string[POOL_SIZE] calldata titles,
        string[POOL_SIZE] calldata descriptions,
        uint64[POOL_SIZE] calldata expiries,
        uint8 outcomes
    ) external onlyOracle {
        uint32 poolId = uint32(poolIds.length + 1);
        Pool storage pool = pools[poolId];

        for (uint256 i = 0; i < POOL_SIZE; i++) {
            require(expiries[i] > now, "Expiry must be in the future");
            require(outcomes > 1 && outcomes < 4, "Incorrect outcomes");
            // Check event title and description
            validateString(titles[i], MAX_TITLE_LENGTH);
            validateString(descriptions[i], MAX_DESCRIPTION_LENGTH);

            pool.titles[i] = titles[i];
            pool.descriptions[i] = descriptions[i];
            pool.expiries[i] = expiries[i];
            pool.outcomes = outcomes;
        }

        setDefaultPercents(pool);
        pool.id = poolId;
        poolIds.push(pool.id);

        emit logNewPool(pool.id, titles[0]);
    }

    /// Close event of the `poolId` pool with the result
    /// @param poolId Id of the pool
    /// @param eventIdx Index of the event in a pool
    /// @param result Index of the result outcome
    function closeEvent(uint32 poolId, uint8 eventIdx, int8 result)
        external
        onlyOracle
    {
        Pool storage pool = pools[poolId];
        require(isPoolExist(pool), "The pool does not exist");
        require(eventIdx < POOL_SIZE, "The event does not exist");
        require(int8(pool.outcomes) > result, "The outcome does not exist");
        require(
            pool.states[eventIdx] == EventState.open,
            "The event is already closed"
        );

        if (result < 0) pool.states[eventIdx] = EventState.canceled;
        else pool.states[eventIdx] = EventState.closed;

        pool.results[eventIdx] = result;
    }

    /// Place ticket in `poolId`
    /// @param poolId Id of the pool
    /// @param outcomes Bytes of outcomes. Bits in bytes are selected indexes of outcomes
    function placeTicket(uint32 poolId, bytes15 outcomes) external payable {
        require(msg.value >= MIN_STAKE, "Stake is too small");
        Pool storage pool = pools[poolId];
        require(isPoolExist(pool), "The pool does not exist");
        Ticket storage ticket = tickets[poolId][msg.sender];

        require(pool.expiries[0] >= now, "The pool is already expired");

        require(pool.state == PoolState.open, "The pool is already closed");

        if (ticket.stake == 0) {
            require(
                pool.players.length < MAX_PLAYERS,
                "The pool is full of players"
            );
            pool.players.push(msg.sender);
            playerPools[msg.sender].push(poolId);
        }

        ticket.outcomes |= outcomes;

        uint256 variants = 1;

        for (uint256 i = 0; i < POOL_SIZE; i++) {
            variants = variants.mul(
                uint256(countBits(uint32(uint8(ticket.outcomes[i]))))
            );
        }

        require(variants > 0, "Incorrect outcomes");

        ticket.stake = ticket.stake.add(msg.value);

        require(ticket.stake >= variants.mul(MIN_STAKE), "Stake is too small");

        pool.bank = pool.bank.add(msg.value);
    }

    /// Get pool by it's id
    /// @param poolId Pool id
    /// @return Pool instance
    function getPool(uint32 poolId) external view returns (Pool memory) {
        Pool storage poolOrigin = pools[poolId];
        Pool memory poolRead = poolOrigin;

        if (poolOrigin.state == PoolState.open) poolRead.jackpot = jackpot;

        return poolRead;
    }

    /// Get last pools
    /// @return Array of pool ids
    function getPoolsHistory()
        external
        view
        returns (uint32[HISTORY_SIZE] memory)
    {
        uint32[HISTORY_SIZE] memory history;

        for (uint256 i = 0; i < HISTORY_SIZE && i < poolIds.length; i++) {
            history[i] = poolIds[poolIds.length - 1 - i];
        }

        return history;
    }

    /// Get player's `player` pool ids
    /// @param player Address of the player
    /// @return Array of pool ids
    function getPlayerHistory(address player)
        external
        view
        returns (uint32[HISTORY_SIZE] memory)
    {
        uint32[HISTORY_SIZE] memory history;
        uint32[] storage _playerPools = playerPools[player];

        for (uint256 i = 0; i < HISTORY_SIZE && i < _playerPools.length; i++) {
            history[i] = _playerPools[_playerPools.length - 1 - i];
        }

        return history;
    }

    /// Get ticket instance
    /// @param poolId Id of the pool
    /// @param player Address of the player
    /// @return Ticket instance
    function getTicket(uint32 poolId, address player)
        external
        view
        returns (Ticket memory)
    {
        return tickets[poolId][player];
    }

    /// Close pool
    /// @param poolId Pool id
    function closePool(uint32 poolId) public onlyOracle {
        Pool storage pool = pools[poolId];
        require(isPoolExist(pool), "The pool does not exist");
        require(pool.state == PoolState.open, "The pool is already closed");

        pool.state = PoolState.closed;

        if (pool.bank != 0) {
            processFailedEvents(pool, getFailedEvents(pool));

            distributeFees(pool);

            categorizePlayers(pool);

            distributeWinnings(pool);

            sendWinnings(pool);

            updateJackpot(pool);
        }

        deletePool(poolId);
    }

    /// Cancel pool
    /// @param poolId Pool id
    function cancelPool(uint32 poolId) public onlyOracle {
        Pool storage pool = pools[poolId];
        require(isPoolExist(pool), "The pool does not exist");

        if (pool.state == PoolState.open) {
            pool.state = PoolState.canceled;
            sendWinnings(pool);
            deletePool(poolId);
        }
    }

    /// Increace jackpot value
    function increaseJackpot() public payable {
        jackpot = jackpot.add(msg.value);
    }

    /// Withdraw contract fee
    /// @param to Destination address
    /// @param amount Withdraw amount
    function withdrawContractFee(address payable to, uint256 amount)
        public
        onlyOwner
    {
        require(
            amount <= contractFee && amount <= address(this).balance,
            "Amount is too big"
        );
        contractFee = contractFee.sub(amount);
        to.transfer(amount);
    }

    /// Withdraw jackpot
    /// @param to Destination address
    /// @param amount Withdraw amount
    function withdrawJackpot(address payable to, uint256 amount)
        public
        onlyOwner
    {
        require(
            amount <= jackpot && amount <= address(this).balance,
            "Amount is too big"
        );
        jackpot = jackpot.sub(amount);
        to.transfer(amount);
    }

    /// Create oracle
    /// @param _oracle Oracle address
    function createOracle(address payable _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function sendPayment(
        address payable to,
        uint32 poolId,
        uint256 amount,
        bool _isJackpot
    ) private {
        (bool success, ) = to.call.value(amount)("");
        if (success) emit logPayment(to, poolId, amount, _isJackpot);
        else emit logFailedPayment(to, poolId, amount, _isJackpot);
    }

    function countBits(uint32 number) private pure returns (uint32) {
        uint32 i = number;
        i = i - ((i >> 1) & 0x55555555);
        i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
        return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
    }

    function deletePool(uint32 poolId) private {
        if (poolId >= HISTORY_SIZE + 1) {
            uint32 removingIdx = poolId - HISTORY_SIZE;
            Pool storage removingPool = pools[removingIdx];

            for (
                uint256 i = 0;
                i < removingPool.players.length && i < MAX_PLAYERS;
                i++
            ) {
                address player = removingPool.players[i];
                delete tickets[removingIdx][player];
                for (uint256 j = 0; j < playerPools[player].length; j++) {
                    uint32[] storage playersPools = playerPools[player];
                    if (
                        playersPools[playersPools.length - 1 - j] == removingIdx
                    ) {
                        delete playersPools[playersPools.length - 1 - j];
                        break;
                    }
                }
            }

            delete poolIds[removingIdx - 1];
            delete pools[removingIdx];
        }
    }

    function distributeFees(Pool storage pool) private {
        if (pool.state == PoolState.canceled) return;

        if (pool.bank > 0) {
            uint256 poolContractFee = percentFrom(
                pool.bank,
                CONTRACT_FEE_PERCENT
            );
            contractFee = contractFee.add(poolContractFee);

            uint256 poolOracleFee = percentFrom(pool.bank, ORACLE_FEE_PERCENT);

            uint256 allFees = poolContractFee.add(poolOracleFee);
            assert(pool.bank > allFees);
            pool.bank = pool.bank.sub(allFees);

            sendPayment(oracle, pool.id, poolOracleFee, false);
        }
    }

    function percentFrom(uint256 value, uint8 percent)
        private
        pure
        returns (uint256)
    {
        require(percent <= 100, "Incorrect percent value");
        if (percent == 0) return 0;
        return value.mul(percent).div(100);
    }

    function updateJackpot(Pool storage pool) private {
        if (pool.state != PoolState.canceled && newJackpot > 0)
            jackpot = jackpot.add(newJackpot);
    }

    function sendWinnings(Pool storage pool) private {
        for (uint256 i = 0; i < pool.players.length && i < MAX_PLAYERS; i++) {
            address payable player = pool.players[i];
            Ticket storage ticket = tickets[pool.id][player];

            if (pool.state == PoolState.canceled)
                sendPayment(player, pool.id, ticket.stake, false);
            else if (ticket.winning != 0) {
                sendPayment(player, pool.id, ticket.winning, ticket.jackpot);
            }
        }
    }

    function distributeWinnings(Pool storage pool) private {
        if (pool.state == PoolState.canceled) {
            return;
        }

        uint256 localNewJackpot = pool.bank;
        uint256 tmpJackpot = jackpot;
        uint256 maxWinning;

        if (jackpot != 0 && pool.jackpotPercent != 0) {
            pool.jackpot = percentFrom(jackpot, pool.jackpotPercent);
        }

        for (uint8 i = 0; i < CATEGORIES_COUNT; i++) {
            uint256 categoryBank = pool.banks[i];
            uint8 categoryPercent = uint8(pool.percents[i]);

            if (categoryPercent != 0 && categoryBank != 0) {
                uint256 categoryWinnings = percentFrom(
                    pool.bank,
                    categoryPercent
                );

                assert(categoryWinnings <= localNewJackpot);

                localNewJackpot = localNewJackpot.sub(categoryWinnings);

                for (
                    uint256 j = 0;
                    j < pool.players.length && i < MAX_PLAYERS;
                    j++
                ) {
                    Ticket storage ticket = tickets[pool.id][pool.players[j]];
                    if ((ticket.categories & (uint8(1) << i)) != 0) {
                        uint256 ticketWinning = categoryWinnings
                            .mul(ticket.stake)
                            .div(categoryBank);

                        if (
                            i == uint8(Categories.success15) &&
                            pool.jackpot != 0
                        ) {
                            uint256 jackpotWinning = pool
                                .jackpot
                                .mul(ticket.stake)
                                .div(categoryBank);
                            ticketWinning = ticketWinning.add(jackpotWinning);
                            ticket.jackpot = true;
                            tmpJackpot = tmpJackpot.sub(jackpotWinning);
                        }

                        ticket.winning = ticket.winning.add(ticketWinning);

                        maxWinning = max(maxWinning, ticket.winning);
                    }
                }
            }
        }

        newJackpot = localNewJackpot;
        jackpot = tmpJackpot;
        pool.maxWinning = maxWinning;
    }

    function categorizePlayers(Pool storage pool) private {
        if (pool.state == PoolState.canceled) {
            return;
        }

        uint256[CATEGORIES_COUNT] memory banks;

        for (uint256 i = 0; i < pool.players.length && i < MAX_PLAYERS; i++) {
            Ticket storage ticket = tickets[pool.id][pool.players[i]];
            uint256 successVariants = 0;

            for (uint256 j = 0; j < POOL_SIZE; j++) {
                if (
                    pool.states[j] == EventState.canceled ||
                    (uint8(ticket.outcomes[j]) &
                        (uint8(1) << uint8(pool.results[j]))) !=
                    0
                ) {
                    successVariants++;
                }
            }

            Categories playerCategory = getSuccessCategory(successVariants);

            assert(uint8(playerCategory) < 8);

            if (playerCategory == Categories.losing) {
                banks[uint256(playerCategory)] = banks[uint256(playerCategory)]
                    .add(ticket.stake);
                ticket.categories |= (uint8(1) << uint8(playerCategory));
            } else {
                assert(successVariants >= MIN_SUCCESS_COUNT);
                for (uint256 j = successVariants; j >= MIN_SUCCESS_COUNT; j--) {
                    playerCategory = getSuccessCategory(j);
                    banks[uint256(playerCategory)] = banks[uint256(
                        playerCategory
                    )]
                        .add(ticket.stake);
                    ticket.categories |= (uint8(1) << uint8(playerCategory));
                }
            }
        }

        pool.banks = banks;
    }

    function processFailedEvents(Pool storage pool, uint256 _canceledEvents)
        private
    {
        if (_canceledEvents == 1) {
            pool.jackpotPercent = 35;
        } else if (_canceledEvents == 2) {
            pool.jackpotPercent = 20;
        } else if (_canceledEvents == 3) {
            pool.jackpotPercent = 10;
            set3FailedPercents(pool);
        } else if (_canceledEvents == 4) {
            pool.jackpotPercent = 5;
            set4FailedPercents(pool);
        } else if (_canceledEvents >= 5) {
            pool.jackpotPercent = 0;
            pool.state = PoolState.canceled;
        }
    }

    function setDefaultPercents(Pool storage pool) private {
        pool.percents[uint256(Categories.success9)] = 32;
        pool.percents[uint256(Categories.success10)] = 18;
        pool.percents[uint256(Categories.success11)] = 10;
        pool.percents[uint256(Categories.success12)] = 10;
        pool.percents[uint256(Categories.success13)] = 10;
        pool.percents[uint256(Categories.success14)] = 10;
        pool.percents[uint256(Categories.success15)] = 10;
        pool.percents[uint256(Categories.losing)] = 0;
        pool.jackpotPercent = 100;
    }

    function set3FailedPercents(Pool storage pool) private {
        pool.percents[uint256(Categories.success9)] = 0;
        pool.percents[uint256(Categories.success10)] = 40;
        pool.percents[uint256(Categories.success11)] = 20;
        pool.percents[uint256(Categories.success12)] = 15;
        pool.percents[uint256(Categories.success13)] = 10;
        pool.percents[uint256(Categories.success14)] = 10;
        pool.percents[uint256(Categories.success15)] = 5;
    }

    function set4FailedPercents(Pool storage pool) private {
        pool.percents[uint256(Categories.success9)] = 0;
        pool.percents[uint256(Categories.success10)] = 0;
        pool.percents[uint256(Categories.success11)] = 45;
        pool.percents[uint256(Categories.success12)] = 25;
        pool.percents[uint256(Categories.success13)] = 15;
        pool.percents[uint256(Categories.success14)] = 10;
        pool.percents[uint256(Categories.success15)] = 5;
    }

    function getFailedEvents(Pool storage pool) private view returns (uint256) {
        uint256 canceledEvents = 0;

        for (uint256 i = 0; i < POOL_SIZE; i++) {
            require(
                pool.states[i] != EventState.open,
                "One of the events is not closed"
            );
            if (pool.states[i] == EventState.canceled) canceledEvents++;
        }

        return canceledEvents;
    }

    function isPoolExist(Pool storage pool) private view returns (bool) {
        return pool.id != 0;
    }

    function getSuccessCategory(uint256 successCount)
        private
        pure
        returns (Categories)
    {
        if (successCount < MIN_SUCCESS_COUNT) return Categories.losing;
        return Categories(successCount - MIN_SUCCESS_COUNT);
    }

    function validateString(string memory _string, uint256 limit) private pure {
        uint256 length = bytes(_string).length;
        require(0 < length && length <= limit, "Incorrect string length");
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}