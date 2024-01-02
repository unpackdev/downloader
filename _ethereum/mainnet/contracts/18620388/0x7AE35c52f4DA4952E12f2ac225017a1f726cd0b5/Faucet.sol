// Sources flattened with hardhat v2.19.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/access/Ownable.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/Faucet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

contract Faucet is Ownable {
    uint256 public withdrawalAmount;
    uint256 public withdrawalInterval;

    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => bool) public whitelist;

    event Withdrawal(address indexed recipient, uint256 amount);
    event Whitelisted(address indexed account, bool isWhitelisted);

    constructor(address initialOwner) Ownable(initialOwner) {
        withdrawalAmount = 2e17;  // 0.2 ETH in wei (1 ether = 1e18 wei)
        withdrawalInterval = 30 days; // One month in seconds
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address is not whitelisted");
        _;
    }

    modifier onlyOncePerInterval() {
        require(
            lastWithdrawTime[msg.sender] + withdrawalInterval < block.timestamp,
            "You can only withdraw once per interval"
        );
        _;
    }

    function setWithdrawalAmount(uint256 _amount) external onlyOwner {
        withdrawalAmount = _amount;
    }

    function setWithdrawalInterval(uint256 _interval) external onlyOwner {
        withdrawalInterval = _interval;
    }

    function addToWhitelist(address _account) external onlyOwner {
        whitelist[_account] = true;
        emit Whitelisted(_account, true);
    }

    function removeFromWhitelist(address _account) external onlyOwner {
        whitelist[_account] = false;
        emit Whitelisted(_account, false);
    }

    function withdraw() external onlyWhitelisted onlyOncePerInterval {
        require(
            address(this).balance >= withdrawalAmount,
            "Insufficient funds in the faucet"
        );

        lastWithdrawTime[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: withdrawalAmount}("");
        require(success, "Failed to send Ether");

        emit Withdrawal(msg.sender, withdrawalAmount);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    receive() external payable {}
}