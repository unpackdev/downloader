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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: dsq-staking.sol


pragma solidity 0.8.22;





/*
 * Dollar Squeeze - Staking Contract
 * Developed by Kevin Remer (Totenmacher)
 */
contract DollarSqueeze_Staking is Ownable {
    using SafeMath for uint256;

    IERC20 public dividendToken;
    IERC721 public nftContract;

    bool public stakingActive;
    uint256 public totalStaked;

    struct userLockData {
        uint256 lockPeriod;
        uint256 lockStart;
        uint256 lockEnd;
        uint256 userAPR;
        uint256 userBalance;
        uint256 userRealized;
        uint256 userDivHistory;
    }

    struct lockPeriodData {
        uint256 lockPeriod;
        uint256 bonusAPR;
    }

    uint256 public earlyWithdrawPenalty;
    uint256 private secPerYear;

    uint256 public baseAPR;
    uint256 public nft1BonusAPR;
    uint256 public nft5BonusAPR;
    uint256 public nft10BonusAPR;
    uint256 public cooldownPeriod;

    mapping(uint256 => lockPeriodData) public lockPeriods;
    mapping(address => userLockData) public userLock;
    mapping(address => uint256) public userCooldown;

    event userStakingReset(address user);
    event tokensStaked(address user, uint256 amount, uint256 lockPeriod);
    event userInfoResynced(address user);
    event tokensWithdrawn(address user, uint256 userBalance, uint256 withdrawAmount);
    event dividendsHarvested(address user, uint256 unpaidDividends);
    event userLockSet(address user, uint256 amount, uint256 lockPeriod_);

    event generalMessage(string errMessage, address user);

    constructor(address tokenAddress_, address nftContract_) Ownable(msg.sender) {
        dividendToken = IERC20(tokenAddress_);
        nftContract = IERC721(nftContract_);

        secPerYear = (60 * 60 * 24 * 365);

        baseAPR = 5;
        nft1BonusAPR = 1;
        nft5BonusAPR = 2;
        nft10BonusAPR = 3;

        cooldownPeriod = 30 days;

        lockPeriods[1].lockPeriod = 30 days;
        lockPeriods[1].bonusAPR = 0;

        lockPeriods[3].lockPeriod = 90 days;
        lockPeriods[3].bonusAPR = 1;

        lockPeriods[6].lockPeriod = 180 days;
        lockPeriods[6].bonusAPR = 2;

        earlyWithdrawPenalty = 10;
    }

    /*
     * Admin Functions
     */

    function changeActiveStatus(bool stakingActive_) external onlyOwner {
        stakingActive = stakingActive_;
    }

    function clearStuckTokens(address token_) external onlyOwner {
        if(token_ == address(dividendToken)) {
            if(totalStaked > 0) {
                emit generalMessage("There are still tokens staked", msg.sender);
                return;
            }
        }
    
        IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }

    function clearStuckETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        emit generalMessage("Contract ETH sent to owner", msg.sender);
    }

    function resetUserStaking(address wallet_) external onlyOwner {
        doResetUserStaking(wallet_);
    }

    function resetUserCooldown(address wallet_) external onlyOwner {
        userCooldown[wallet_] = 0;

        emit generalMessage("User cooldown reset", wallet_);
    }

    function setCooldownPeriod(uint256 cooldownDays_) external onlyOwner {
        require(cooldownDays_ <= 90, "Cooldown period is too long");
    
        cooldownPeriod = cooldownDays_.mul(1 days);
    }

    /*
     * User Functions
     */
    function emergencyWithdrawal() external {
        doResetUserStaking(msg.sender);
        userCooldown[msg.sender] = block.timestamp.add(cooldownPeriod);

        emit generalMessage("Emergency withdrawal", msg.sender);
    }

    function stakeTokens(uint amount_, uint256 lockPeriod_) external {
        require(amount_ > 0, "You must stake at least one token");
        require(amount_ <= dividendToken.balanceOf(msg.sender), "Not enough free tokens");
        require(stakingActive, "Staking pool is currently inactive");
        require(userCooldown[msg.sender] <= block.timestamp, "Wallet is in staking cooldown");

        if(userCooldown[msg.sender] > 0) {
            userCooldown[msg.sender] = 0;
        }

        if(userLock[msg.sender].lockPeriod == 0) {
            require(lockPeriod_ == 1 || lockPeriod_ == 3 || lockPeriod_ == 6, "Invalid lock period");
        } else {
            lockPeriod_ = userLock[msg.sender].lockPeriod;
        }

        try dividendToken.transferFrom(msg.sender, address(this), amount_) {
            setUserLock(msg.sender, amount_, lockPeriod_);

            emit tokensStaked(msg.sender, amount_, lockPeriod_);
        } catch {
            emit generalMessage("Staking failed", msg.sender);
        }
    }

    function resyncUserInfo() external {
        require(userLock[msg.sender].userBalance > 0, "User has no staked tokens");

        setUserLock(msg.sender, 0, 0);

        emit userInfoResynced(msg.sender);
    }

    function withdrawTokens() external {
        require(userLock[msg.sender].userBalance > 0, "User has no staked tokens");

        doHarvestDividends(msg.sender);

        uint256 earlyWithdraw = 0;
        if(userLock[msg.sender].lockEnd > block.timestamp) {
            earlyWithdraw = earlyWithdrawPenalty;
        }

        uint256 userFullAmount = userLock[msg.sender].userBalance;
        uint256 withdrawAmount = userFullAmount;
        if(earlyWithdraw > 0) {
            uint256 earlyWDFee = userFullAmount.mul(earlyWithdraw).div(100);
            dividendToken.transfer(owner(), earlyWDFee);
            withdrawAmount = userFullAmount.sub(earlyWDFee);
        }

        try dividendToken.transfer(msg.sender, withdrawAmount) {
            delete userLock[msg.sender];
            totalStaked -= userFullAmount;

            emit tokensWithdrawn(msg.sender, userFullAmount, withdrawAmount);
        } catch {
            emit generalMessage("Could not withdrawal", msg.sender);
        }
    }

    function harvestDividends() external {
        doHarvestDividends(msg.sender);
    }

    /*
     * Support Functions
     */
    function doResetUserStaking(address wallet_ ) internal {
        uint256 curBalance = userLock[wallet_].userBalance;
        try dividendToken.transfer(wallet_, curBalance) {
            delete userLock[wallet_];
            totalStaked -= curBalance;

            emit userStakingReset(wallet_);
        } catch {
            emit generalMessage("Could not reset user", wallet_);
        }
    }

    function setUserLock(address user_, uint256 amount_, uint256 lockPeriod_) internal {
        uint256 unpaidDiv = viewUnpaidDividends(user_);

        if(userLock[user_].userBalance > 0) {
            totalStaked += amount_.add(unpaidDiv);
            userLock[user_].userDivHistory += unpaidDiv;
            userLock[user_].userRealized += unpaidDiv;
            userLock[user_].userBalance += amount_.add(unpaidDiv);
        } else {
            userLock[user_].lockEnd = block.timestamp+lockPeriods[lockPeriod_].lockPeriod;
            userLock[user_].lockPeriod = lockPeriod_;
            totalStaked += amount_;
            userLock[user_].userBalance = amount_;
        }

        uint256 userNFTBalance = nftContract.balanceOf(user_);

        uint256 nftBonus;
        if(userNFTBalance > 0) {
            if(userNFTBalance < 5) {
                nftBonus = nft1BonusAPR;
            } else {
                if(userNFTBalance < 10) {
                    nftBonus = nft5BonusAPR;
                } else {
                    nftBonus = nft10BonusAPR;
                }
            }
        }

        userLock[user_].userAPR = baseAPR.add(lockPeriods[lockPeriod_].bonusAPR).add(nftBonus);

        userLock[user_].lockStart = block.timestamp;

        emit userLockSet(user_, amount_, lockPeriod_);
    }

    function viewTotalDividends(address user_) public view returns (uint256) {
        return userLock[user_].userDivHistory.add(calcCurrentDividends(user_));
    }

    function viewUnpaidDividends(address user_) public view returns (uint256) {
        return getUnpaidDividends(user_);
    }

    function calcCurrentDividends(address user_) internal view returns (uint256) {
        uint256 userDivPerSec = userLock[user_].userAPR.mul(10**18).div(secPerYear);

        uint256 userDividends = userLock[user_].userBalance.mul(block.timestamp.sub(userLock[user_].lockStart)).mul(userDivPerSec).div(100*(10**18));

        return userDividends;
    }

    function getUnpaidDividends(address user_) internal view returns (uint256) {
        uint256 userTotalDividends = viewTotalDividends(user_);

        if(userTotalDividends > userLock[user_].userRealized) {
            return userTotalDividends.sub(userLock[user_].userRealized);
        }
        else{
            return 0;
        }
    }

    function doHarvestDividends(address user_) internal {
        uint256 unpaidDividends = getUnpaidDividends(user_);
        if(unpaidDividends > 0) {
            try dividendToken.transfer(user_, unpaidDividends) {
                userLock[user_].userRealized += unpaidDividends;
            
                emit dividendsHarvested(user_, unpaidDividends);
            } catch {
                emit generalMessage("Could not harvest dividends", user_);
            }
        }
    }

    function getRemainingTokens() external view returns (uint256) {
        if(dividendToken.balanceOf(address(this)) > totalStaked) {
            return dividendToken.balanceOf(address(this)).sub(totalStaked);
        } else {
            return 0;
        }
    }

}