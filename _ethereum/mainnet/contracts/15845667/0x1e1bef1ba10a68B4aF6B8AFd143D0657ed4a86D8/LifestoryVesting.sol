// SPDX-License-Identifier: MIT
// File: contracts/ILifeCoin.sol


pragma solidity ^0.8.0;

// @author: Abderrahmane Bouali for Lifestory


/**
 * @title LifeCoin
 * LifeCoin - Lifestory token contract (LIFC)
 */
interface ILifeCoin {
     /**
     * @dev onlyVestingContract function to create new coins up to the max cap
     * @param _to address receiving the coins  
     * @param _amount amount of coins to mint  
     */
    function mint(address _to, uint256 _amount) external;
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/LifestoryVesting.sol


pragma solidity ^0.8.0;





// @author: Abderrahmane Bouali for Lifestory

/**
 * @title Lifestory Vesting
 * Lifestory Vesting contract
 */
contract LifestoryVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // LifeCoin contract
    ILifeCoin private immutable lifeCoin;
    
    struct Beneficiary {
        uint256 cliff;
        uint256 vesting;
        uint256 amountTotal;
        uint256 released;
        uint256 firstBenefit;
    }
    
    //1000000000 is the max quantity of LIFC mint (10**18 is the decimal)
    uint256 public constant MAX_RELEASED = 1000000000 * 10**18;

    // number of LIFC to be released
    uint256 public totalToRelease;

    // immutable var to define one day in timestamp
    uint256 public immutable dayTime;
    // immutable to define the start time of the vesting
    uint256 public immutable startedTime;

     /**
     * @dev constructor of LifestoryVesting
     * @param _lifeCoinAddress address of ERC20 contract of LIFC (LifeCoin)
     * @param _nbSecInDay define one day in seconds (timestamp)
     */
    constructor(address _lifeCoinAddress, uint256 _nbSecInDay) {
        lifeCoin = ILifeCoin(_lifeCoinAddress);
        dayTime = _nbSecInDay;
        startedTime = block.timestamp;
    }

    // Mapping from beneficiary address to Beneficiary structure
    mapping(address => Beneficiary) private beneficiaries;

    /**
     * @dev Emitted when `beneficiary` release `amount`
     */
    event Released(address beneficiary, uint256 amount);

    /**
     * @dev onlyOwner function to create a new beneficiary for a vesting.
     * @notice the distribution of tokens is implemented as stated in the whitepaper
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _amount total amount of tokens to be released at the end of the vesting
     * @param _firstBenefit amount of tokens released at the begin of the vesting
     * @param _cliff_day duration in days of the cliff after which tokens will begin to vest
     * @param _vesting_day duration in days of the period in which the tokens will vest
     */
    function createBeneficiary(
        address _beneficiary,
        uint256 _amount,
        uint256 _firstBenefit,
        uint256 _cliff_day,
        uint256 _vesting_day
    ) public onlyOwner {
        require(
            totalToRelease.add(_amount)  <= MAX_RELEASED,
            "LifestoryVesting: maximal vesting already set"
        );
        require(
            _firstBenefit <= _amount,
            "LifestoryVesting: firstBenefit higher from amount"
        );
        require(
            beneficiaries[_beneficiary].amountTotal  < 1,
            "LifestoryVesting: already a beneficiary"
        );
        require(_vesting_day > 0, "LifestoryVesting: duration must be > 0 days");
        require(_amount > 0, "LifestoryVesting: amount must be > 0");

        beneficiaries[_beneficiary] = Beneficiary(
            _cliff_day.mul(dayTime),
            _vesting_day.mul(dayTime),
            _amount,
            0,
            _firstBenefit
        );
        totalToRelease = totalToRelease.add(_amount);
    }

    /**
     * @dev see {createBeneficiary}.
     */
    function createBeneficiaryBatch(
        address[] memory _beneficiary,
        uint256[] memory _amount,
        uint256[] memory _firstBenefit,
        uint256[] memory _cliff_day,
        uint256[] memory _vesting_day
    ) public onlyOwner {
        require(
            _beneficiary.length == _amount.length
             && _amount.length == _firstBenefit.length
             && _amount.length == _cliff_day.length
             && _amount.length == _vesting_day.length,
            "LifestoryVesting: length not equal"
        );
        for (uint256 i = 0; i < _beneficiary.length; i++) {
            createBeneficiary(_beneficiary[i], _amount[i], _firstBenefit[i], _cliff_day[i], _vesting_day[i]);
        }    
    }

    /**
     * @dev view function to get Beneficiary structure 
     * @param _beneficiary address of beneficiary
     */
    function getBeneficiary(address _beneficiary)
        public
        view
        returns (Beneficiary memory)
    {
        return beneficiaries[_beneficiary];
    }

    /**
     * @dev view function to see number of LifeCoin can release at `_currentTime`
     * @param _beneficiary address of beneficiary
     * @param _currentTime time in timestamp
     */
    function getAmountReleasable(address _beneficiary, uint256 _currentTime)
        public
        view
        returns (uint256)
    {
        Beneficiary memory beneficiary = beneficiaries[_beneficiary];
        require(
            beneficiary.amountTotal > 0,
            "LifestoryVesting: beneficiary not exist"
        );

        if (_currentTime < startedTime.add(beneficiary.cliff)){
            return beneficiary.firstBenefit.sub(beneficiary.released); 
        } else if (_currentTime >= startedTime.add(beneficiary.vesting).add(beneficiary.cliff)) {
            return beneficiary.amountTotal.sub(beneficiary.released);
        } else {
            uint256 amountPerSeconds = (beneficiary.amountTotal.sub(beneficiary.firstBenefit)).div(beneficiary.vesting);
            uint256 deltaPerSeconds = _currentTime.sub(startedTime.add(beneficiary.cliff));
            uint256 amount = (deltaPerSeconds.mul(amountPerSeconds)).add(beneficiary.firstBenefit);
            return amount.sub(beneficiary.released);
        }
    }

    /**
     * @dev public function to release `_amount` of LifeCoin
     * @dev this function can only be called by beneficiary
     * @dev this function checks if your `_amount` is less or equal
     * then the maximum amount you can release at the current time
     * @param _amount the amount to release
     */
    function release(uint256 _amount)
        public
        nonReentrant
    {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];
        require(
            beneficiary.amountTotal > 0,
            "LifestoryVesting: only beneficiary can release vested tokens"
        );

        uint256 entitledAmount = getAmountReleasable(msg.sender, block.timestamp);

        require(
            entitledAmount >= _amount,
            "LifestoryVesting: cannot release tokens, not enough vested tokens"
        );

        beneficiary.released = beneficiary.released.add(_amount);

        lifeCoin.mint(msg.sender, _amount);

        emit Released(msg.sender, _amount);
    }
}