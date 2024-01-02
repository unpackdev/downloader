// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract BlazexEscrow is Ownable, ReentrancyGuard {
    address public manager = msg.sender;
    address public blazexWallet = msg.sender; // can update to staking contract later.

    uint112 public blazexFeePercent = 500; //10% default (please put percent in multiple of 100)

    struct Project {
        uint256 amount;
        uint256 extraAmount;
        uint256 blazexFee;
        address user;
        address token;
        bytes32 depositHash;
        bool paid;
        bool deposited;
        bool refunded;
        uint256 callerId;
        uint256 callId;
        uint256 chain;
    }

    modifier onlyManager() {
        require(
            address(msg.sender) == manager,
            "Escrow: Caller is not manager"
        );
        _;
    }

    mapping(uint256 => Project) public projects;
	mapping(uint256 => mapping(bytes32 => bool)) public externalPaymentHashes;

    constructor() {}

    function deposit(
        uint256 amount,
        uint256 callerId,
        uint256 callId,
        address token,
        uint256 chain
    ) external payable nonReentrant {
        require(amount > 0, "Escrow: amount must be greater then 0");

        Project storage project = projects[callId];
        require(project.amount == 0, "Escrow: Call id exist");
        require(!project.deposited, "Escrow: Already deposited");
        require(msg.value >= amount, "Escrow: Insufficient value");
        payable(address(this)).transfer(msg.value);

        project.deposited = true;
        project.amount = amount;
        project.callerId = callerId;
        project.callId = callId;
        project.token = token;
        project.blazexFee = (blazexFeePercent * amount) / 10000;
        project.user = address(msg.sender);
        project.chain = chain;
    }

    function depositExternal(
        address depositor,
        bytes32 depositHash,
        uint256 amount,
        uint256 extraAmount,
        uint256 callerId,
        uint256 callId,
        address token,
        uint256 chain
    ) public onlyManager nonReentrant {
        require(depositor != address(0), "Invalid depositor address");
        require(amount > 0, "Escrow: amount must be greater then 0");
		require(!externalPaymentHashes[chain][depositHash], "Duplicate payment hash");
		externalPaymentHashes[chain][depositHash] = true;
        Project storage project = projects[callId];
        require(project.amount == 0, "Escrow: Call id exist");
        require(!project.deposited, "Escrow: Already deposited");
        project.deposited = true;
        project.amount = amount;
        project.extraAmount = extraAmount;
        project.callerId = callerId;
        project.callId = callId;
        project.token = token;
        project.blazexFee = (blazexFeePercent * amount) / 10000;
        project.user = depositor;
        project.depositHash = depositHash;
        project.chain = chain;
    }

    function refund(uint256 callId) public onlyManager nonReentrant {
        Project storage project = projects[callId];
        require(project.deposited, "Escrow: Not yet deposited");
        require(!project.paid, "Escrow: Already paid");
        require(!project.refunded, "Escrow: Already refunded");

        project.refunded = true;
        payable(project.user).transfer(project.amount);
    }

    function pay(uint256 callId, address influencer)
        external
        onlyManager
        nonReentrant
    {
        Project storage project = projects[callId];
        require(project.deposited, "Escrow: Not yet deposited");
        require(!project.paid, "Escrow: Already paid");
        require(!project.refunded, "Escrow: Already refunded");
        project.paid = true;
        uint256 blazexFee = project.blazexFee;
        uint256 amount = project.amount - blazexFee;
        payable(address(blazexWallet)).transfer(blazexFee);
        (bool sent, ) = influencer.call{value: amount}("");
        require(
            sent,
            "Address provided can't receive payments. Please use a different ethereum address"
        );
    }

    function changeManager(address _newManager) external onlyOwner {
        manager = _newManager;
    }

    function changeBlazexWallet(address _newFeeWallet) external onlyOwner {
        blazexWallet = _newFeeWallet;
    }

    // put in multiple of 100
    function changeBlazexFeePercent(uint112 _feePercent) external onlyOwner {
        blazexFeePercent = _feePercent;
    }

    function emergencyWithdraw() external onlyOwner nonReentrant {
        // this function call is prohibited only call this function when there is stuck funds in the contract
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}