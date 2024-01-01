// bet.etf.live

pragma solidity 0.8.21;

// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ETFVAULTS is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public betToken; // $ETF to be used for betting
    address public bonusToken; // bonus rewards token

    EnumerableSet.UintSet private activeBets;
    EnumerableSet.UintSet private settledBets;
    mapping(address => uint256) public amountWonByAccount;
    mapping(address => EnumerableSet.UintSet) private accountBetsPending;
    mapping(uint256 => BetInfo) private betInformation;
    mapping(address => EnumerableSet.UintSet) private accountBets;

    address public feeReceiver;
    uint256 public feePercent = 420; // accounting for 4.2% transfer tax, to be removed at later date

    uint256 public totalPaidOut;

    struct Player {
        uint256 outcomeSelected;
        uint256 amountBet;
        uint256 winnings;
    }

    struct BetInfo {
        string description;
        uint256 deadline;
        uint256 outcomeABets;
        uint256 outcomeBBets;
        mapping(address => Player) players;
        uint256 totalPayout;
        uint256 outcome;
        bool active;
    }

    event BetCreated(
        uint256 indexed betId,
        uint256 indexed deadline
    );

    event PlayerBet(
        uint256 indexed betId,
        address indexed walletAddress,
        uint256 indexed outcome,
        uint256 amount
    );

    event DeadlineUpdated(
        uint256 indexed betID,
        uint256 indexed deadline
    );

    event DescriptionUpdated(
        uint256 indexed betID,
        string indexed description
    );

    event BetSettled(
        uint256 indexed betId,
        uint256 indexed outcome
    );

    event PaidOutTokens(address token, address indexed player, uint256 amount);

    constructor() {
        feeReceiver = msg.sender;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }
    
    function setBetToken(address _betToken) external onlyOwner {
        betToken = _betToken;
    }
    function setBonusToken(address _bonusToken) external onlyOwner {
        bonusToken = _bonusToken;
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee < 1000, "Cannot be more than 10%");
        feePercent = newFee;
    }

    function placeBet(uint256 betId, uint256 outcomeSelection, uint256 amount) external nonReentrant {
        require(msg.sender == tx.origin, "Contracts cannot play");
        require(IERC20(betToken).balanceOf(msg.sender) >= amount, "You don't have enough tokens");
        BetInfo storage betInfo = betInformation[betId];
        require(amount >= 0 ether, "Cannot bet 0");
        require(
            betInfo.deadline > block.timestamp,
            "betting closed"
        );
        Player storage player = betInfo.players[msg.sender];
        require(
            player.outcomeSelected == 0,
            "Can only bet once per pool"
        );
        require(
            outcomeSelection <= 2 && outcomeSelection != 0,
            "Can only select outcome 1 or 2"
        );
 
        uint256 amountForBet = amount;

        // handle fees
        if (feePercent > 0) {
            uint256 amountForFee = (amount * feePercent) / 10000;
            IERC20(betToken).transferFrom(msg.sender, feeReceiver, amountForFee);
            amountForBet -= amountForFee;
        }

        IERC20(betToken).transferFrom(msg.sender, address(this), amountForBet);

        player.outcomeSelected = outcomeSelection;
        player.amountBet = amountForBet;
        accountBetsPending[msg.sender].add(betId);
        accountBets[msg.sender].add(betId);
        betInfo.totalPayout += amountForBet;

        if (outcomeSelection == 1) {
            betInfo.outcomeABets += amountForBet;
        } else if (outcomeSelection == 2) {
            betInfo.outcomeBBets += amountForBet;
        }
        emit PlayerBet(betId, msg.sender, outcomeSelection, amountForBet);
    }

    function createPool(
        uint256 betId, 
        uint256 deadline,
        string memory betDescription
        ) external onlyOwner {
        require(!activeBets.contains(betId), "pool already created");
        require(deadline > block.timestamp, "deadline must be in future");
        activeBets.add(betId);
        BetInfo storage betInfo = betInformation[betId];
        betInfo.active = true;
        betInfo.deadline = deadline;
        betInfo.description = betDescription;
        emit BetCreated(betId, deadline);
    }

    function updateDescription(uint256 betId, string memory newDescription) external onlyOwner {
        require(activeBets.contains(betId), "not an active pool");     
        BetInfo storage betInfo = betInformation[betId];

        betInfo.description = newDescription;
        emit DescriptionUpdated(betId, newDescription);
    }

    function updateDeadline(uint256 betId, uint256 newDeadline) external onlyOwner {
        require(activeBets.contains(betId), "not an active pool");
        require(newDeadline > block.timestamp, "deadline must be in future");       
        BetInfo storage betInfo = betInformation[betId];

        betInfo.deadline = newDeadline;
        emit DeadlineUpdated(betId, newDeadline);
    }

    function setOutcome(uint256 betId, uint256 outcome) external onlyOwner {
        BetInfo storage betInfo = betInformation[betId];
        require(activeBets.contains(betId), "outcome already set");
        require(
            outcome <= 3 && outcome != 0,
            "Can only select outcome A or B, or cancelled"
        );

        betInfo.outcome = outcome;

        uint256 shares;
        if (betInfo.outcome == 1) {
            shares = betInfo.outcomeABets;
        } else if (betInfo.outcome == 2) {
            shares = betInfo.outcomeBBets;
        } else if (betInfo.outcome == 3) {
            shares = betInfo.totalPayout;
        }

        activeBets.remove(betId);
        settledBets.add(betId);
        betInfo.active = false;
        emit BetSettled(betId, outcome);
    }

    function claimWinnings(uint256 betId) external nonReentrant {
        require(msg.sender == tx.origin, "Contracts cannot play");
        BetInfo storage betInfo = betInformation[betId];
        Player storage player = betInfo.players[msg.sender];
        if (
            settledBets.contains(betId) &&
            accountBetsPending[msg.sender].contains(betId)
        ) {
            accountBetsPending[msg.sender].remove(betId);

            if (player.outcomeSelected == betInfo.outcome) {
                uint256 shares;
                if (betInfo.outcome == 1) {
                    shares = betInfo.outcomeABets;
                } else if (betInfo.outcome == 2) {
                    shares = betInfo.outcomeBBets;
                } 
                uint256 amountForPayout = (player.amountBet *
                    betInfo.totalPayout) / shares;
                
                if (amountForPayout > 0) {
                    IERC20(betToken).transfer(msg.sender, amountForPayout);                    
                    amountWonByAccount[msg.sender] += amountForPayout;
                    totalPaidOut = totalPaidOut.add(amountForPayout);
                    player.winnings = amountForPayout;
                    emit PaidOutTokens(betToken, msg.sender, amountForPayout);
                    uint256 bonusRewardsBalance = IERC20(bonusToken).balanceOf(address(this));
                    if (bonusRewardsBalance > 0) {
                        uint256 bonusShares = (amountForPayout * bonusRewardsBalance) / betInfo.totalPayout;
                        IERC20(bonusToken).transfer(msg.sender, bonusShares);
                    }
                }

            } else if (betInfo.outcome == 3 && player.amountBet > 0) {
                IERC20(betToken).transfer(msg.sender, player.amountBet);
                amountWonByAccount[msg.sender] += player.amountBet;
            }
        }   
    }

    function getAmountClaimableByBetId(uint256 betId, address account) public view returns (uint256) {
        BetInfo storage betInfo = betInformation[betId];
        Player storage player = betInfo.players[account];
        uint256 amountForPayout;
        if (
            settledBets.contains(betId) &&
            accountBetsPending[account].contains(betId)
        ) {
            uint256 shares;

            if (betInfo.outcome == 1) {
                shares = betInfo.outcomeABets;
            } else if (betInfo.outcome == 2) {
                shares = betInfo.outcomeBBets;
            }
            if (player.outcomeSelected == betInfo.outcome) {
                amountForPayout = (player.amountBet *
                    betInfo.totalPayout) / shares;
            } else if (betInfo.outcome == 3) {
                amountForPayout = player.amountBet;
            }
        }
        return amountForPayout;
    }

    function getAmountTotalClaimable(address account) public view returns (uint256) {
        uint256[] memory betIds = accountBetsPending[account].values();
        uint256 amountForPayout;
        for (uint256 i = 0; i < betIds.length; i++) {
            BetInfo storage betInfo = betInformation[betIds[i]];
            Player storage player = betInfo.players[account];
            if (
                settledBets.contains(betIds[i]) &&
                accountBetsPending[account].contains(betIds[i])
            ) {
                uint256 shares;

                if (betInfo.outcome == 1) {
                    shares = betInfo.outcomeABets;
                } else if (betInfo.outcome == 2) {
                    shares = betInfo.outcomeBBets;
                } 
                if (player.outcomeSelected == betInfo.outcome) {
                    amountForPayout +=
                        (player.amountBet * betInfo.totalPayout) /
                        shares;
                } else if (betInfo.outcome == 3) {
                    amountForPayout += player.amountBet;
                }
            }
        }
        return amountForPayout;
    }

    function getBetInfo(uint256 betId)
        external
        view
        returns (
            string memory description,
            uint256 deadline,
            uint256 outcomeA,
            uint256 outcomeB,
            uint256 totalPayout,
            bool active,
            uint256 outcome
        )
    {
        BetInfo storage betInfo = betInformation[betId];

        description = betInfo.description;
        deadline = betInfo.deadline;
        outcomeA = betInfo.outcomeABets;
        outcomeB = betInfo.outcomeBBets;
        totalPayout = betInfo.totalPayout;
        active = betInfo.active;
        outcome = betInfo.outcome;
    }

    function getPlayerInfoByBetId(uint256 betId, address account)
        external
        view
        returns (uint256 amountBet, uint256 outcomeSelected, uint256 winnings)
    {
        BetInfo storage betInfo = betInformation[betId];
        Player storage player = betInfo.players[account];
        amountBet = player.amountBet;
        outcomeSelected = player.outcomeSelected;
        winnings = player.winnings;
    }

    function getActiveBets() external view returns (uint256[] memory) {
        return activeBets.values();
    }

    function getInactiveBets() external view returns (uint256[] memory) {
        return settledBets.values();
    }

    function getAccountBetsPending(address account)
        external
        view
        returns (uint256[] memory)
    {
        return accountBetsPending[account].values();
    }

    function getAccountBets(address account)
        external
        view
        returns (uint256[] memory)
    {
        return accountBets[account].values();
    }

    function withdrawStuckTokens(uint256 amountToWithdraw, address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, amountToWithdraw);
    }

    function withdrawEth() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
        payable(msg.sender).transfer(ethBalance);
        }
    }
}