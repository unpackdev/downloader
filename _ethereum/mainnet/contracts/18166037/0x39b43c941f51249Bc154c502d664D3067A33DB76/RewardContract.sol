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

// File: RewardContract.sol


pragma solidity ^0.8.0;



contract RewardContract is ReentrancyGuard {
    
    IERC20 public SphynxToken;
    
    struct UserRecord {
        uint256 totalPurchasedAmount;
        uint256 totalBonus;
        uint256 lastPurchaseTime;
        bool isRewardExcluded;
    }
    
    mapping(address => UserRecord) public userRecords;
    
    modifier onlySphynxToken() {
        require(msg.sender == address(SphynxToken), "Only Sphynx Token contract can call this function");
        _;
    }
    
    constructor(address _SphynxToken) {
        SphynxToken = IERC20(_SphynxToken);
    }

    function updateBonusAmount(address _user, uint256 _amount) external onlySphynxToken {
        UserRecord storage userRecord = userRecords[_user];
        
        if (userRecord.lastPurchaseTime == 0 || block.timestamp >= userRecord.lastPurchaseTime + 7 days) {
            userRecord.totalPurchasedAmount += _amount;
            if(userRecord.lastPurchaseTime == 0 ){
                userRecord.lastPurchaseTime = block.timestamp;  
                userRecord.totalBonus = calculateBonus(_amount);
            }
        } else {
            uint256 remainingDays = 7 - ((block.timestamp - userRecord.lastPurchaseTime) / 1 days);
            userRecord.totalPurchasedAmount += _amount;
            userRecord.totalBonus += ((_amount * 25 / 100) * remainingDays / 7);
        }
    }
    
    function calculateBonus(uint256 _amount) private pure returns (uint256) {
        return (_amount * 25) / 100;
    }
    
    function claimReward() external nonReentrant {
        UserRecord storage userRecord = userRecords[msg.sender];
        
        require(userRecord.lastPurchaseTime > 0, "No purchase has been made");
        require(block.timestamp >= userRecord.lastPurchaseTime + 7 days, "Reward is not yet claimable");
        require(!userRecord.isRewardExcluded, "This address is excluded from receiving the reward");
        
        // Transfer the bonus to the user
        require(SphynxToken.transfer(msg.sender, userRecord.totalBonus), "Transfer failed");
        
        // Reset the last purchase time and total amount so that the user can start a new bonus period
        userRecord.lastPurchaseTime = block.timestamp;
        userRecord.totalBonus = calculateBonus(userRecord.totalPurchasedAmount);
    }
    
    function setIsRewardExcluded(address _user) external onlySphynxToken {
        userRecords[_user].isRewardExcluded = true;
    }
}