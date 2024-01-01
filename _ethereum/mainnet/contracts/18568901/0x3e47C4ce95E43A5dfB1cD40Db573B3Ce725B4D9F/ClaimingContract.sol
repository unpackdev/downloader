// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        // Gnosis Safe MultiSig Wallet
        _owner = address(0xd701a9BAB866610189285E1BE17D2A80A4Df29b3);
        emit OwnershipTransferred(address(0), _owner);
    }

    function renounounceOwnership() public onlyOwner {
        _owner = address(0);
        pendingOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Caller != pending owner');
        address oldOwner = _owner;
        _owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, _owner);
    }
}

contract ClaimingContract is Ownable, ReentrancyGuard {
    IERC20 public token;

    mapping(address => uint256) public allocations;
    uint256 public totalAllocatedAmount;

    event TokensAllocated(address indexed to, uint256 amount);
    event TokensClaimed(address indexed by, uint256 amount);
    event TokensDeposited(address indexed by, uint256 amount);
    event TokensWithdrawn(address indexed by, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero.");
        token = IERC20(_token);
    }

    function depositTokens(uint256 _amount) public onlyOwner {
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit TokensDeposited(msg.sender, _amount);
    }

    function allocateTokens(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Cannot allocate to zero address.");
        require(token.balanceOf(address(this)) - totalAllocatedAmount >= _amount, "Insufficient unallocated balance");
        allocations[_to] += _amount;
        totalAllocatedAmount += _amount;
        emit TokensAllocated(_to, _amount);
    }

    function claimTokens() public nonReentrant {
        uint256 amount = allocations[msg.sender];
        require(amount > 0, "No tokens allocated");
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        allocations[msg.sender] = 0;
        totalAllocatedAmount -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit TokensClaimed(msg.sender, amount);
    }

    function withdrawUnallocatedTokens() public onlyOwner nonReentrant {
        uint256 unallocatedTokens = token.balanceOf(address(this)) - totalAllocatedAmount;
        require(unallocatedTokens > 0, "No unallocated tokens to withdraw");
        require(token.transfer(msg.sender, unallocatedTokens), "Transfer failed");
        emit TokensWithdrawn(msg.sender, unallocatedTokens);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner nonReentrant {
        require(token.transfer(msg.sender, _amount), "Transfer failed");
        emit TokensWithdrawn(msg.sender, _amount);
    }

}