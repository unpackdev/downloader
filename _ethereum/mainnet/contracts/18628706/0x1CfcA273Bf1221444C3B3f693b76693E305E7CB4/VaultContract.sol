// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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

// File: vault.sol



pragma solidity ^0.8.9;




interface IAffiliate {
    function changeUpline(address _addr, address _upline) external;

    function checkAffiliate(address _address) external view returns (uint256);

    function getUpline(address _addr) external view returns (address);
}

contract VaultContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public withdrawDuration = 1 days;
    uint256 public withdrawLimit = 10; //10%

    uint256 public stakeFee = 50; //50%
    uint256 public affiliateDeduction = 5; //5%
    uint256 public affiliateFee = 25; //25%

    address private operatorAddress;
    address private affiliateAddress;
    address private stakingAddress;
    address private teamWallet;

    uint256 public totalDeposits;
    uint256 public totalWithdrawn;
    uint256 public totalProfit;
    uint256 public totalDepositors;

    uint256 public denominator = 1000;

    bool public isPaused;

    struct Deposit {
        address depositor;
        uint256 amount;
        uint256 timestamp;
        bool withdrawn;
    }

    struct Depositor {
        uint256 totalDeposits;
        uint256 totalWithdrawn;
        uint256 totalDepositsCount;
        uint256 totalWithdrawnCount;
        uint256 totalEarned;
        uint256 totalReferralEarned;
    }

    mapping(address => Depositor) public depositors;
    mapping(address => Deposit[]) public deposits;

    address[] public depositorsList;

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Only bot operator can call this function");
        _;
    }

    event Received(address, uint256);
    event Withdrawn(address, uint256);

    constructor(address _operatorAddress, address _affiliateAddress, address _stakingAddress) {
        require(_operatorAddress != address(0), "Invalid operator address");
        require(_affiliateAddress != address(0), "Invalid affiliate address");
        require(_stakingAddress != address(0), "Invalid staking address");

        operatorAddress = _operatorAddress;
        affiliateAddress = _affiliateAddress;
        stakingAddress = _stakingAddress;
    }

    //receive ETH by failure
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function depositETH(address _upline) external payable nonReentrant {
        require(msg.value > 0, "Invalid amount");
        require(_upline != address(0), "Invalid upline address");
        require(_upline != msg.sender, "Cannot refer yourself");

        uint256 amount = msg.value;

        totalDeposits = totalDeposits.add(amount);
        totalDepositors = totalDepositors.add(1);

        Depositor storage depositor = depositors[msg.sender];
        depositor.totalDeposits = depositor.totalDeposits.add(amount);
        depositor.totalDepositsCount = depositor.totalDepositsCount.add(1);

        //add to depositors list
        if (depositorsList.length == 0) {
            depositorsList.push(msg.sender);
        } else {
            bool isExist = false;
            for (uint256 i = 0; i < depositorsList.length; i++) {
                if (depositorsList[i] == msg.sender) {
                    isExist = true;
                    break;
                }
            }
            if (!isExist) {
                depositorsList.push(msg.sender);
            }
        }

        IAffiliate(affiliateAddress).changeUpline(msg.sender, _upline);

        Deposit memory deposit = Deposit({
        depositor : msg.sender,
        amount : amount,
        timestamp : block.timestamp,
        withdrawn : false
        });
        deposits[msg.sender].push(deposit);

        emit Received(msg.sender, amount);
    }

    function withdrawETH() external nonReentrant {
        require(!isPaused, "Contract is paused");
        require(deposits[msg.sender].length > 0, "No deposits found");

        uint256 totalAmount;

        for (uint256 i = 0; i < deposits[msg.sender].length; i++) {
            Deposit storage deposit = deposits[msg.sender][i];
            if (deposit.withdrawn) {
                continue;
            }

            uint256 amount = deposit.amount;

            totalAmount = totalAmount.add(amount);

            deposit.withdrawn = true;
            deposit.timestamp = block.timestamp;

            totalDeposits = totalDeposits.sub(amount);
            totalWithdrawn = totalWithdrawn.add(amount);
            totalDepositors = totalDepositors.sub(1);

            Depositor storage depositor = depositors[msg.sender];
            depositor.totalWithdrawn = depositor.totalWithdrawn.add(amount);
            depositor.totalWithdrawnCount = depositor.totalWithdrawnCount.add(1);
        }

        require(totalAmount > 0, "No deposits found");

        uint256 withdrawLimitAmount = totalDeposits.mul(withdrawLimit).div(100);
        require(totalAmount <= withdrawLimitAmount, "Withdraw limit exceeded");

        if (depositorsList.length > 0) {
            for (uint256 i = 0; i < depositorsList.length; i++) {
                if (depositorsList[i] == msg.sender) {
                    delete depositorsList[i];
                    break;
                }
            }
        }

        //        payable(msg.sender).transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function depositProfit() external payable nonReentrant onlyOperator {//mev bot will call this function for deposit profit eth;
        uint256 _amount = msg.value;
        require(_amount > 0, "Invalid amount");

        totalProfit = totalProfit.add(_amount);

        uint256 forStake;

        for (uint256 i = 0; i < depositorsList.length; i++) {
            IAffiliate affiliate = IAffiliate(affiliateAddress);
            bool isAffiliate = affiliate.checkAffiliate(depositorsList[i]) > 0;
            uint256 depositorProfit = _calcRate(depositorsList[i], _amount);

            if (isAffiliate) {
                forStake = forStake.add(depositorProfit.mul(stakeFee - affiliateDeduction).mul(100 - affiliateFee).div(10000));
                uint256 forUpline = depositorProfit.mul(stakeFee - affiliateDeduction).mul(affiliateFee).div(10000);

                //referrer profit (amount*(45%)*25%/100)
                depositors[affiliate.getUpline(depositorsList[i])].totalEarned = depositors[affiliate.getUpline(depositorsList[i])].totalEarned.add(forUpline);
                depositors[affiliate.getUpline(depositorsList[i])].totalReferralEarned = depositors[affiliate.getUpline(depositorsList[i])].totalReferralEarned.add(forUpline);
                payable(affiliate.getUpline(depositorsList[i])).transfer(forUpline);

                // depositor profit (amount*(100%-45%)/100)
                depositors[depositorsList[i]].totalEarned = depositors[depositorsList[i]].totalEarned.add(depositorProfit.mul(100 - (stakeFee - affiliateDeduction)).div(100));
                payable(depositorsList[i]).transfer(depositorProfit.mul(100 - (stakeFee - affiliateDeduction)).div(100));
            } else {
                forStake = forStake.add(depositorProfit.mul(stakeFee).div(100));

                // depositor profit (amount*(100%-50%)/100)
                depositors[depositorsList[i]].totalEarned = depositors[depositorsList[i]].totalEarned.add(depositorProfit.mul(100 - stakeFee).div(100));
                payable(depositorsList[i]).transfer(depositorProfit.mul(100 - stakeFee).div(100));
            }
        }

        payable(stakingAddress).transfer(forStake);

        emit Received(msg.sender, _amount);
    }

    function _calcRate(address _depositor, uint256 _amount) internal view returns (uint256) {
        uint256 userDeposits = depositors[_depositor].totalDeposits;
        uint256 rate = userDeposits * _amount / totalDeposits;

        require(rate < _amount, "Invalid rate");

        //depositor's profit
        return rate;
    }

    function getDeposits(address _depositor) external view returns (Deposit[] memory) {
        return deposits[_depositor];
    }

    function setOperator(address _operatorAddress) external onlyOwner {
        operatorAddress = _operatorAddress;
    }

    function setTeamWallet(address _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function setWithdrawDuration(uint256 _withdrawDuration) external onlyOwner {
        withdrawDuration = _withdrawDuration;
    }

    function setWithdrawLimit(uint256 _withdrawLimit) external onlyOwner {
        withdrawLimit = _withdrawLimit;
    }

    function setFees(uint256 _stakeFee, uint256 _affiliateDeduction, uint256 _affiliateFee) external onlyOwner {
        stakeFee = _stakeFee;
        affiliateDeduction = _affiliateDeduction;
        affiliateFee = _affiliateFee;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setAffiliateAddress(address _affiliateAddress) external onlyOwner {
        affiliateAddress = _affiliateAddress;
    }

    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function withdrawForBot() external onlyOperator {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdrawn(msg.sender, balance);
    }
}