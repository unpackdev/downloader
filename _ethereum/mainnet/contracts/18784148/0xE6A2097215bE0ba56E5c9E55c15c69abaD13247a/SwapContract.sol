// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// File: Swap_flattened.sol


// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// File: Swap.sol


pragma solidity ^0.8.0;





// Points Contract Interface
interface IPointsContract {
    function updatePoints(address holder, uint256 amount) external;
    function adjustPoints(address holder, int256 amount) external;
    function getPointsBalance(address holder) external view returns (uint256);
}


contract SwapContract is Ownable, ReentrancyGuard {
    IERC20 public usdc;
    IERC20 public usdt;

    IPointsContract public pointsContract;
    AggregatorV3Interface internal priceFeed;

    uint256 public constant POINT_VALUE = 1 ether;
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 10;

    event PointsPurchased(address indexed user, uint256 points, uint256 ethAmount);
    event PointsSold(address indexed user, uint256 points, uint256 ethAmount);
    event FundsWithdrawn(address indexed owner, uint256 amount, string currency);
    event PointsSoldForStablecoin(address indexed user, uint256 points, uint256 stablecoinAmount, address stablecoin);
    event PointsPurchasedWithStablecoin(address indexed user, uint256 points, uint256 amount, address stablecoin);



    constructor(address _pointsContractAddress, address _usdcAddress, address _usdtAddress, address initialOwner) 
        Ownable(initialOwner) 
    {
        pointsContract = IPointsContract(_pointsContractAddress);
        usdc = IERC20(_usdcAddress);
        usdt = IERC20(_usdtAddress);
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    }

    function getLatestETHPrice() public view returns (uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

   function pointsToETH(uint256 points) public view returns (uint256) {
        uint256 ethPrice = getLatestETHPrice(); // Price of 1 ETH in USD, with 8 decimal places
        // Convert points to ETH: Multiply by 1e18 for ETH decimals, then divide by the price (adjusted for decimals)
        uint256 ethAmount = (points * 1e18) / (ethPrice * 1e10); // Multiply price by 1e10 to match ETH's 18 decimal places
        return ethAmount;
    }

    




    function buyPointsWithETH(uint256 pointsToBuy) public payable nonReentrant {
        require(pointsToBuy > 0, "Points to buy must be greater than 0");

        uint256 ethPrice = getLatestETHPrice(); // Price of 1 ETH in USD
        uint256 ethAmountNeeded = (pointsToBuy * 1e18) / (ethPrice * 1e10); // Convert points to equivalent ETH

        require(msg.value >= ethAmountNeeded, "Insufficient ETH sent");

        uint256 platformFee = (ethAmountNeeded * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = ethAmountNeeded - platformFee;

        // Update points balance
        pointsContract.adjustPoints(msg.sender, int256(pointsToBuy));

        // Refund excess ETH if any
        if(msg.value > ethAmountNeeded) {
            payable(msg.sender).transfer(msg.value - ethAmountNeeded);
        }

        // Transfer platform fee
        payable(owner()).transfer(platformFee);

        emit PointsPurchased(msg.sender, pointsToBuy, amountAfterFee);
    }


    function sellPointsForETH(uint256 points) public nonReentrant {
        require(pointsContract.getPointsBalance(msg.sender) >= points, "Insufficient points");

        uint256 ethPrice = getLatestETHPrice(); // Get the latest ETH price in USD
        uint256 ethAmount = (points * 1e18 * 1e10) / ethPrice; // Calculate the ETH amount for the given points

        require(address(this).balance >= ethAmount, "Insufficient contract balance");

        // Adjust the user's points in the PointsContract
        pointsContract.adjustPoints(msg.sender, -int256(points));

        // Send the calculated ETH amount to the user
        payable(msg.sender).transfer(ethAmount);

        emit PointsSold(msg.sender, points, ethAmount);
    }

    function sellPointsForUSDC(uint256 points) public nonReentrant {
        require(pointsContract.getPointsBalance(msg.sender) >= points, "Insufficient points");

        // Assuming 1 point = 1 unit of USDC
        uint256 usdcAmount = points;

        require(usdc.balanceOf(address(this)) >= usdcAmount, "Insufficient USDC balance in contract");

        // Deduct points from the user's balance
        pointsContract.adjustPoints(msg.sender, -int256(points));

        // Transfer USDC to the user
        require(usdc.transfer(msg.sender, usdcAmount), "USDC transfer failed");

        emit PointsSoldForStablecoin(msg.sender, points, usdcAmount, address(usdc));
    }

    function sellPointsForUSDT(uint256 points) public nonReentrant {
        require(pointsContract.getPointsBalance(msg.sender) >= points, "Insufficient points");

        // Assuming 1 point = 1 unit of USDT
        uint256 usdtAmount = points;

        require(usdt.balanceOf(address(this)) >= usdtAmount, "Insufficient USDT balance in contract");

        // Deduct points from the user's balance
        pointsContract.adjustPoints(msg.sender, -int256(points));

        // Transfer USDT to the user
        require(usdt.transfer(msg.sender, usdtAmount), "USDT transfer failed");

        emit PointsSoldForStablecoin(msg.sender, points, usdtAmount, address(usdt));
    }




    function buyPointsWithUSDC(uint256 amount) public nonReentrant {
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        uint256 pointsToAllocate = amount / POINT_VALUE;
        uint256 platformFee = (amount * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - platformFee;

        require(usdc.transfer(owner(), platformFee), "Fee transfer failed");
        pointsContract.adjustPoints(msg.sender, int256(pointsToAllocate));

        emit PointsPurchasedWithStablecoin(msg.sender, pointsToAllocate, amountAfterFee, address(usdc));
    }

    function buyPointsWithUSDT(uint256 amount) public nonReentrant {
    require(usdt.transferFrom(msg.sender, address(this), amount), "USDT transfer failed");
        uint256 pointsToAllocate = amount / POINT_VALUE;
        uint256 platformFee = (amount * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - platformFee;

        require(usdc.transfer(owner(), platformFee), "Fee transfer failed");
        pointsContract.adjustPoints(msg.sender, int256(pointsToAllocate));

        emit PointsPurchasedWithStablecoin(msg.sender, pointsToAllocate, amountAfterFee, address(usdc));
    }



    function withdrawFunds(string memory currency) public onlyOwner {
        if (keccak256(bytes(currency)) == keccak256("ETH")) {
            uint256 ethBalance = address(this).balance;
            payable(owner()).transfer(ethBalance);
            emit FundsWithdrawn(owner(), ethBalance, "ETH");
        } else if (keccak256(bytes(currency)) == keccak256("USDC")) {
            uint256 usdcBalance = usdc.balanceOf(address(this));
            require(usdc.transfer(owner(), usdcBalance), "USDC withdrawal failed");
            emit FundsWithdrawn(owner(), usdcBalance, "USDC");
        } else if (keccak256(bytes(currency)) == keccak256("USDT")) {
            uint256 usdtBalance = usdt.balanceOf(address(this));
            require(usdt.transfer(owner(), usdtBalance), "USDT withdrawal failed");
            emit FundsWithdrawn(owner(), usdtBalance, "USDT");
        } else {
            revert("Invalid currency");
        }
    }

    
    function transferOwnership(address newOwner) public override onlyOwner {
        // Your additional logic here

        super.transferOwnership(newOwner);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    event FundsReceived(address indexed sender, uint256 amount);
}