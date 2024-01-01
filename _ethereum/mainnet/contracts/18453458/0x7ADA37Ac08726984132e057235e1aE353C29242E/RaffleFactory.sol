// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.8.0;

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

// File: contracts/watch raffle.sol/raffle.sol


pragma solidity ^0.8.19;



contract Raffle {
    using SafeMath for uint256;
    address public manager;
    IERC20 public usdtAddress;

    struct RaffleInfo {
        string name;
        string image;
        string detailPageImage;
        uint256 marketValue;
        uint256 startTime;
        uint256 endTime;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 maxTicketsPerParticipant;
        uint256 numberOfWinners;
        uint256 totalTicketsSold;
        bool raffleClosed;
    }

    RaffleInfo public raffle;

    struct UserInfo {
        string email;
        uint256 ticketsPurchased;
    }

    struct Affiliate {
        address affiliateAddress;
        uint256 ticketsSold;
        uint256 totalCommission; // Commission rate in percentage
    }

    mapping(address => UserInfo) public userInfoMap;  
    mapping(address => Affiliate) public affiliates; //AFF

    address[] public participants;
    uint256[] public winnerIndices;

    constructor(
        string memory _name,
        string memory _image,
        string memory _detailPageImage,
        uint256 _marketValue,
        uint256 _endTime,
        uint256 _ticketPrice,
        uint256 _maxTickets,
        uint256 _maxTicketsPerParticipant,
        uint256 _numberOfWinners,
        address _manager,
        IERC20 _usdtAddress
    ) {
        require(_numberOfWinners <= 3, "Winners Can't be more than 3");
        manager = _manager;
        raffle = RaffleInfo(
            _name,
            _image,
            _detailPageImage,
            _marketValue,
            block.timestamp,
            block.timestamp.add(3600 * _endTime),
            _ticketPrice,
            _maxTickets,
            _maxTicketsPerParticipant,
            _numberOfWinners,
            0,
            false
        );
        usdtAddress = _usdtAddress;
    }

    event AffliateCreated(
        address creator,
        address affiliater,
        uint256 ticketPrice,
        uint256 ticketsBuy,
        uint256 commission
    );

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this");
        _;
    }

    modifier notClosed() {
        require(!raffle.raffleClosed, "Raffle is closed");
        _;
    }

    function getRaffle() public view returns (RaffleInfo memory) {
        return raffle;
    }

    // function enter(string memory email, uint256 numberOfTickets) public notClosed {
    //     require(numberOfTickets > 0, "Number of tickets must be greater than 0");
    //     require(
    //         raffle.totalTicketsSold.add(numberOfTickets) <= raffle.maxTickets,
    //         "Exceeds max tickets available"
    //     );
    //     require(
    //         userInfoMap[msg.sender].ticketsPurchased.add(numberOfTickets) <= raffle.maxTicketsPerParticipant,
    //         "Exceeds max tickets per participant"
    //     );

    //     require(usdtAddress.balanceOf(msg.sender) >= raffle.ticketPrice.mul(numberOfTickets), "Insufficient funds");
    //     require(usdtAddress.transferFrom(msg.sender, manager, raffle.ticketPrice.mul(numberOfTickets)), "USDT transfer failed");

    //     for (uint256 i = 0; i < numberOfTickets; i++) {
    //         participants.push(msg.sender);
    //     }

    //     raffle.totalTicketsSold = raffle.totalTicketsSold.add(numberOfTickets);
    //     userInfoMap[msg.sender] = UserInfo(email, userInfoMap[msg.sender].ticketsPurchased.add(numberOfTickets));

    //     if (raffle.totalTicketsSold >= raffle.maxTickets) {
    //         closeRaffle();
    //     }
    // }

    function enter(string memory email, uint256 numberOfTickets, address referrer) public notClosed {
        require(numberOfTickets > 0, "Number of tickets must be greater than 0");
        require(
            raffle.totalTicketsSold.add(numberOfTickets) <= raffle.maxTickets,
            "Exceeds max tickets available"
        );
        require(
            userInfoMap[msg.sender].ticketsPurchased.add(numberOfTickets) <= raffle.maxTicketsPerParticipant,
            "Exceeds max tickets per participant"
        );

        uint256 ticketPrice = raffle.ticketPrice.mul(numberOfTickets);
        uint256 commission = 0;

        require(usdtAddress.balanceOf(msg.sender) >= ticketPrice, "Insufficient funds");

        if (referrer != address(0)) {
            Affiliate storage affiliate = affiliates[referrer];

            if (affiliate.affiliateAddress == address(0)) {
                // Create a new affiliate if the referrer does not exist
                affiliate.affiliateAddress = referrer;
            }

            // Calculate the commission based on the number of tickets
            if (numberOfTickets >= 1 && numberOfTickets <= 5) {
                commission = ticketPrice.mul(5).div(100);
            } else if (numberOfTickets <= 10) {
                commission = ticketPrice.mul(10).div(100);
            } else if (numberOfTickets <= 20) {
                commission = ticketPrice.mul(15).div(100);
            } else if (numberOfTickets > 20) {
                commission = ticketPrice.mul(20).div(100);
            }

            usdtAddress.transferFrom(msg.sender, affiliate.affiliateAddress, commission);
            affiliate.ticketsSold = affiliate.ticketsSold.add(numberOfTickets);
            affiliate.totalCommission = affiliate.totalCommission.add(commission);
        }

        uint256 remainingAmount = ticketPrice.sub(commission);
        require(usdtAddress.transferFrom(msg.sender, manager, remainingAmount), "USDT transfer failed");

        for (uint256 i = 0; i < numberOfTickets; i++) {
            participants.push(msg.sender);
        }

        raffle.totalTicketsSold = raffle.totalTicketsSold.add(numberOfTickets);
        userInfoMap[msg.sender] = UserInfo(email, userInfoMap[msg.sender].ticketsPurchased.add(numberOfTickets));

        emit AffliateCreated(
            msg.sender,
            referrer,
            raffle.ticketPrice,
            numberOfTickets,
            commission
        );

        if (raffle.totalTicketsSold >= raffle.maxTickets) {
            closeRaffle();
        }
    }


    function closeRaffle() internal notClosed {
        require(raffle.totalTicketsSold > 0, "No participants to select from");
        require(raffle.numberOfWinners <= raffle.totalTicketsSold, "Not enough participants for the number of winners");

        raffle.raffleClosed = true;

        uint256 randomWinner = random();
        for (uint256 i = 0; i < raffle.numberOfWinners; i++) {
            if (i == 0) {
                winnerIndices.push(randomWinner % raffle.totalTicketsSold);
            } else if (i == 1) {
                winnerIndices.push((randomWinner.add(randomWinner.div(2))) % raffle.totalTicketsSold);
            } else {
                winnerIndices.push((randomWinner.add(randomWinner.div(4))) % raffle.totalTicketsSold);
            }
        }
    }

    function getWinners() public view returns (address[] memory) {
        address[] memory winners = new address[](winnerIndices.length);
        for (uint256 i = 0; i < winnerIndices.length; i++) {
            winners[i] = participants[winnerIndices[i]];
        }
        return winners;
    }

    function random() private view returns (uint256) {
        // return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, participants)));
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, participants)));
    }

    function getParticipantsCount() public view returns (uint256) {
        return raffle.totalTicketsSold;
    }

    function updateMaxTicketsPerParticipant(uint256 _maxTicketsPerParticipant) public onlyManager {
        raffle.maxTicketsPerParticipant = _maxTicketsPerParticipant;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/watch raffle.sol/factory.sol


pragma solidity ^0.8.19;




contract RaffleFactory is Ownable {
    IERC20 public usdtAddress;
    address[] public deployedRaffles;
    uint256 public affiliateCommissionDenominator = 100;

    constructor(address _usdtAddress) {
        usdtAddress = IERC20(_usdtAddress);
    }

    // struct Affiliate {
    //     address affiliateAddress;
    //     uint256 ticketsSold;
    //     uint8 commissionRate; // Commission rate in percentage
    // }

    // mapping(address => Affiliate) public affiliates;

    struct Winners {
        address winner1;
        address winner2;
        address winner3;
    }

    // function setAffiliateCommissionRate(address affiliateAddress, uint8 commissionRate) external onlyOwner {
    //     require(commissionRate <= 20, "Commission rate cannot exceed 20%");
    //     affiliates[affiliateAddress] = Affiliate(
    //         affiliateAddress,
    //         0,
    //         commissionRate
    //     );
    // }

    event RaffleCreated(
        address indexed raffleAddress,
        string _watch,
        string _image,
        string _detailPageImage,
        uint256 marketValue,
        uint256 _endTimeHours,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 maxTicketsPerParticipant,
        uint256 duration,
        address creator
    );

    function createRaffle(
        string memory _watch,
        string memory _image,
        string memory _detailPageImage,
        uint256 _marketValue,
        uint256 _endTimeHours,
        uint256 _ticketPrice,
        uint256 _maxTickets,
        uint256 _maxTicketsPerParticipant,
        uint256 _numberOfWinners
    ) external onlyOwner {
        address newRaffle = address(
            new Raffle(
                _watch,
                _image,
                _detailPageImage,
                _marketValue,
                _endTimeHours,
                _ticketPrice,
                _maxTickets,
                _maxTicketsPerParticipant,
                _numberOfWinners,
                msg.sender,
                usdtAddress
            )
        );
        deployedRaffles.push(newRaffle);
        emit RaffleCreated(
            newRaffle,
            _watch,
            _image,
            _detailPageImage,
            _marketValue,
            _endTimeHours,
            _ticketPrice,
            _maxTickets,
            _maxTicketsPerParticipant,
            _numberOfWinners,
            msg.sender
        );
    }

    function getDeployedRaffles() public view returns (address[] memory) {
        return deployedRaffles;
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(amount <= usdtAddress.balanceOf(address(this)), "Insufficient balance");
        usdtAddress.transfer(to, amount);
    }

    function allWinners() external view returns (Winners[] memory) {
        address[] memory raffles = deployedRaffles;
        uint256 winnerzLength;
        uint256 temp1;

        for (uint256 i = 0; i < raffles.length; i++) {
            bool raffleClosed = Raffle(raffles[i]).getRaffle().raffleClosed;
            if (raffleClosed) {
                address[] memory winnersAddr = Raffle(raffles[i]).getWinners();
                if (winnersAddr.length > 0) {
                    temp1++;
                }
            }
        }
        Winners[] memory winners = new Winners[](temp1);

        for (uint256 i = 0; i < raffles.length; i++) {
            bool raffleClosed = Raffle(raffles[i]).getRaffle().raffleClosed;
            if (raffleClosed) {
                address[] memory winnersAddr = Raffle(raffles[i]).getWinners();
                if (winnersAddr.length > 0) {
                    if (winnersAddr.length == 1) {
                        winners[winnerzLength] = Winners(
                            winnersAddr[0],
                            address(0),
                            address(0)
                        );
                        winnerzLength++;
                    } else if (winnersAddr.length == 2) {
                        winners[winnerzLength] = Winners(
                            winnersAddr[0],
                            winnersAddr[1],
                            address(0)
                        );
                        winnerzLength++;
                    } else {
                        winners[winnerzLength] = Winners(
                            winnersAddr[0],
                            winnersAddr[1],
                            winnersAddr[2]
                        );
                        winnerzLength++;
                    }
                }
            }
        }
        return winners;
    }
}