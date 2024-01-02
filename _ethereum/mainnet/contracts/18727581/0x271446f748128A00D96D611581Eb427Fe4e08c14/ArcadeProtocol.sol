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

contract ArcadeProtocol is Ownable {
    address public prizePoolContract;
    address public revenueShareWallet;
    uint256 public swapAmount;
    uint256 public prizePoolShare;

    constructor(address _prizePoolContract, address _revenueShareWallet) Ownable(msg.sender) {
        prizePoolContract = _prizePoolContract;
        revenueShareWallet = _revenueShareWallet;
        prizePoolShare = 35; // 35%
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /**
     * @notice Sets the prize pool contract
     */
    function setPrizePoolContract(address _prizePoolContract) external onlyOwner {
        prizePoolContract = _prizePoolContract;
    }

    /**
     * @notice Sets the revenue share wallet
     */
    function setRevenueWallet(address _revenueShareWallet) external onlyOwner {
        revenueShareWallet = _revenueShareWallet;
    }

    /**
     * @notice Sets the prize pool share 
     */
    function setPrizePoolShare(uint256 share) external onlyOwner {
        prizePoolShare = share;
    }

    /**
     * @notice Sets the swap threshold for the Arcoin ERC-20 contract, controlled outside so we can renounce ownership of the coin itself
     */
    function setSwapAmount(uint256 amount) external onlyOwner {
        swapAmount = amount;
    }

    /**
     * @notice Distributes ETH to the revenue share pool and the prize pool
     */
    function distributeFunds() external {
        uint256 prizePoolAmount = address(this).balance * prizePoolShare / 100;
        uint256 revenueShareAmount = address(this).balance - prizePoolShare;

        // Send 35% to the prize pool contract
        (bool sentPrize, ) = prizePoolContract.call{value: prizePoolAmount}("");
        require(sentPrize, "Failed to send Ether to prize pool");

        // Send 65% to the revenue share wallet
        (bool sentRevenue, ) = revenueShareWallet.call{value: revenueShareAmount}("");
        require(sentRevenue, "Failed to send Ether to revenue share wallet");
    }
}