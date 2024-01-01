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

// File: contracts/contract.sol


pragma solidity ^0.8.0;



contract ScratchCardGame is Ownable {
    IERC20 public scratchToken;
    uint256 public scratchCost = 1500000 * 1e18;
    uint256 public balanceThreshold = 500000000 * 1e18; // Disable scratch() If wallet token balance insufficient

    // Prize Tier
    uint256[] public prizeThresholds = [
        20,
        1020,
        4020,
        11020,
        21020,
        41020,
        91020,
        1000000
    ];

    // Prize amounts
    uint256[] public prizeAmounts = [
        450000000, 
        300000000, 
        150000000, 
        75000000, 
        45000000, 
        15000000, 
        7500000,
        0
    ];
 
    event PrizeWon(
        uint256 indexed ticketId,
        uint256 prizeAmount,
        address winner
    );

    event Ticket(
        uint256 indexed ticketId,
        uint256 result
    );

    struct Winner {
        address user;
        uint256 ticketId;
        uint256 result;
        uint256 prizeAmount;
    }

    Winner[] public winners;
    uint256 public totalScratchCards;

    constructor(address _scratchToken) Ownable(msg.sender) {
        scratchToken = IERC20(_scratchToken);
    }

    function generateRandomValue(address user, uint256 ticketId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, user, ticketId))) % 1000000;
    }

    function calculatePrize(uint256 randomValue) internal view returns (uint256) {
        for (uint i = 0; i < prizeThresholds.length; i++) {
            if (randomValue < prizeThresholds[i]) {
                return prizeAmounts[i];
            }
        }
        return 0;
    }

    function setScratchCost(uint256 _newCost) external onlyOwner {
        scratchCost = _newCost;
    }

    function setBalanceThreshold(uint256 _balance) external onlyOwner {
        balanceThreshold = _balance;
    }

    function withdrawTokens(address _to, uint256 _amount) external onlyOwner {
        require(scratchToken.transfer(_to, _amount), "Token transfer failed");
    }

    function getAllowanceAmount() public view returns (uint256) {
        return scratchToken.allowance(msg.sender, address(this));
    }

    // Function to get the contract's Ether balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function scratch() public returns (uint256) {
        uint256 contractScratchTokenBalance = scratchToken.balanceOf(address(this));
        require(contractScratchTokenBalance >= balanceThreshold , "Wallet $SCRATCH balance Insufficient");

        uint256 userBalance = scratchToken.balanceOf(msg.sender);
        require(userBalance >= scratchCost, "User Insufficient $SCRATCH balance");

        // Check if the contract is allowed to transfer the required $SCRATCH tokens
        uint256 allowance = scratchToken.allowance(msg.sender, address(this));
        require(allowance >= scratchCost, "Allowance not sufficient");

        require(
            scratchToken.transferFrom(msg.sender, address(this), scratchCost),
            "Failed to transfer $SCRATCH"
        );
        
        uint256 ticketId = totalScratchCards++;

        uint256 randomValue = generateRandomValue(msg.sender, ticketId);
      
        uint256 prize = calculatePrize(randomValue) * 1e18;

        emit Ticket(ticketId, randomValue);
    
        if (prize > 0) {
            // Transfer the tokens
            require(
                scratchToken.transfer(msg.sender, prize),
                "Token transfer failed"
            );
 
            winners.push(Winner(msg.sender, ticketId, randomValue, prize));
            emit PrizeWon(ticketId, prize, msg.sender);
        }
        return prize;
    }

    function getWinner(uint256 index) public view returns (address user, uint256 ticketId, uint256 result, uint256 prizeAmount) {
        require(index < winners.length, "Invalid index");
        Winner memory winner = winners[index];
        return (winner.user, winner.ticketId, winner.result, winner.prizeAmount);
    }

    function getNumberOfWinners() public view returns (uint256) {
        return winners.length;
    }

    function withdrawETH() public payable onlyOwner {
        require(address(this).balance > 0, "No Balance to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }
}