// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract CadetSub is Ownable {
    using SafeMath for uint256;

    IERC20 public token;

    mapping(bytes32 => address) public addrByRef;
    mapping(address => bytes32) public refByAddress;

    uint256 public subscriptions = 0;
    uint8 public discount = 10;
    uint8 public bonus = 20;

    struct User {
        address user;
        uint8 subType;
        uint256 termStart;
        uint256 nextPayment;
        address referrer;
    }

    struct Score {
        address affiliate;
        uint256 earned;
        uint16 referrals;
    }

    mapping(address => Score) public affiliates; 
    mapping(address => User) public users;

    uint256 public MONTH_PRICE = 15 * 10**6;
    uint256 public YEAR_PRICE = 150 * 10**6;
    uint256 public LIFETIME_PRICE = 200 * 10**6;

    event MonthSubscription(address indexed, uint256, uint256, bytes32);
    event YearSubscription(address indexed, uint256, uint256, bytes32);
    event LifetimeSubscription(address indexed, uint256, uint256, bytes32);
    event ReferralEarned(address indexed, uint256);
    event BillPaid(address indexed, uint256);
    event CancelSubscription(address, uint256);
    event PriceChange(uint256);
    event USDTWithdraw(uint256);
    event UpdateReferrer(address indexed, uint256);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function subscribe(uint8 tokenId, string memory _refCode) external {
        uint256 amountPaid;
        uint256 nextPayment;
        address referrer;

        bytes32 refCode = bytes32(abi.encodePacked(_refCode));

        require(addrByRef[refCode] != msg.sender, "Can't refer yourself");
        require(
            token.balanceOf(msg.sender) >= amountPaid,
            "Insufficient funds"
        );

        if (tokenId == 1) {
            amountPaid = MONTH_PRICE;
            nextPayment = block.timestamp + (86400 * 30);
        } else if (tokenId == 2) {
            amountPaid = YEAR_PRICE;
            nextPayment = block.timestamp + (86400 * 365);
        } else if (tokenId == 3) {
            amountPaid = LIFETIME_PRICE;
        } else {
            revert("invalid tokenId input");
        }

        subscriptions++;

        if (addrByRef[refCode] != address(0)) {
            //Add 10% referral logic to change the amount Paid
            referrer = addrByRef[refCode];
            amountPaid = amountPaid - ((amountPaid * discount) / 100);
            uint256 commission = (amountPaid * bonus) / 100;
            amountPaid = amountPaid - commission;

            affiliates[referrer].affiliate = referrer;
            affiliates[referrer].referrals++;
            affiliates[referrer].earned = commission;



            token.transferFrom(msg.sender, addrByRef[refCode], commission);

            emit ReferralEarned(referrer, block.timestamp);
        }

        users[msg.sender] = User(
            msg.sender,
            tokenId,
            block.timestamp,
            nextPayment,
            referrer
        );

        token.transferFrom(msg.sender, owner(), amountPaid);

        if (tokenId == 1) {
            emit MonthSubscription(msg.sender, amountPaid, tokenId, refCode);
        } else if (tokenId == 2) {
            emit YearSubscription(msg.sender, amountPaid, tokenId, refCode);
        } else {
            emit LifetimeSubscription(msg.sender, amountPaid, tokenId, refCode);
        }
    }

    function checkStatus(address _addr) external view returns (bool) {
        if (users[_addr].subType == 3) {
            return true;
        } else if (block.timestamp < users[_addr].nextPayment) {
            return true;
        } else {
            return false;
        }
    }

    function payBill(address _addr) external {
        require(users[_addr].user != address(0), "User not found!");
        require(
            users[_addr].subType != 3,
            "Lifetime membership does not have to pay bill!"
        );
        require(block.timestamp >= users[_addr].nextPayment, "Already paid up to date.");
        uint256 amount;
        uint256 nextPayment;

        if (users[_addr].subType == 2) {
            amount = YEAR_PRICE;
            nextPayment = block.timestamp + (86400 * 365);
        } else {
            amount = MONTH_PRICE;
            nextPayment = block.timestamp + (86400 * 30);
        }

        users[_addr].nextPayment = nextPayment;


        if (users[_addr].referrer != address(0)) {
            uint256 commission = (amount * bonus) / 100;
            amount = amount - commission;

            token.transferFrom(msg.sender, users[_addr].referrer, commission);

            affiliates[users[_addr].referrer].earned += commission;

            emit ReferralEarned(users[_addr].referrer, block.timestamp);
        }

        token.transferFrom(msg.sender, owner(), amount);

        emit BillPaid(msg.sender, amount);
    }

    function addReferralAddress(string memory userName, address _addr) public {
        require(
            msg.sender == _addr || msg.sender == owner(),
            "You cannot add someone else's address to the referral program"
        );
        bytes32 _referralCode = bytes32(abi.encodePacked(userName));
        refByAddress[_addr] = _referralCode;
        addrByRef[_referralCode] = _addr;
    }

    function bulkAddReferralAddress(
        string[] calldata userNames,
        address[] calldata _addr
    ) external onlyOwner {
        for (uint8 i; i < userNames.length; i++) {
            addReferralAddress(userNames[i], _addr[i]);
        }
    }

    function updateSubscription(address _addr, uint8 _choice) external {
        require(users[_addr].user != address(0), "User not found!");
        require(
            msg.sender == users[_addr].user,
            "Cannot update someone else's subscription"
        );
        require(
            users[_addr].subType != 3,
            "User already has lifetime membership"
        );
        uint256 nextPayment;

        if (_choice == 1) {
            require(users[_addr].subType != 1, "User already has this subscription!");
            nextPayment = block.timestamp + (86400 * 30);
            users[_addr].subType = 1;
        } else {
            uint256 amount;
            if (_choice == 2) {
                require(users[_addr].subType != 2, "User already has this subscription!");
                amount = YEAR_PRICE;
                nextPayment = block.timestamp + (86400 * 365);
                users[_addr].subType = 2;
            } else {
                amount = LIFETIME_PRICE;
                users[_addr].subType = 3;
            }

            if (users[_addr].referrer != address(0)) {
                uint256 commission = (amount * bonus) / 100;
                amount = amount - commission;
                token.transferFrom(
                    msg.sender,
                    users[_addr].referrer,
                    commission
                );

                affiliates[users[_addr].referrer].earned += commission;

                emit ReferralEarned(users[_addr].referrer, block.timestamp);
            }

            token.transferFrom(msg.sender, owner(), amount);
        }

        users[_addr].nextPayment = nextPayment;
    }

    function cancelSubscription(address _addr) external {
        require(
            msg.sender == users[_addr].user,
            "Cannot cancel someone else's subscription"
        );
        delete users[_addr];

        subscriptions--;

        emit CancelSubscription(_addr, block.timestamp);
    }

    function updateReferrer(address userAddress, address newReferrer)
        external
        onlyOwner
    {
        users[userAddress].referrer = newReferrer;

        emit UpdateReferrer(userAddress, block.timestamp);
    }

    function setPrices(
        uint256 _newMonthPrice,
        uint256 _newYearPrice,
        uint256 _newLifetimePrice
    ) external onlyOwner {
        MONTH_PRICE = _newMonthPrice;
        YEAR_PRICE = _newYearPrice;
        LIFETIME_PRICE = _newLifetimePrice;

        emit PriceChange(block.timestamp);
    }

    function setToken(address _newToken) external onlyOwner {
        token = IERC20(_newToken);
    }

    function setBonus(uint8 _bonus) external onlyOwner {
        bonus = _bonus;
    }

    function setDiscount(uint8 _disc) external onlyOwner {
        discount = _disc;
    }

    function emergencyTokenWithdraw(address _stuckToken) external onlyOwner {
        IERC20 stuckToken = IERC20(_stuckToken);
        uint256 balance = stuckToken.balanceOf(address(this));
        stuckToken.transfer(owner(), balance);

        emit USDTWithdraw(balance);
    }
}