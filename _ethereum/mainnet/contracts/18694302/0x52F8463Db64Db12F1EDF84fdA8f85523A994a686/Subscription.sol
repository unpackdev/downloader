// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/**
 * @title AggregatorV3Interface
 * @dev This interface represents the set of functions provided by the Chainlink V3 price feeds.
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8); // Returns the number of decimals the price is reported with
    function description() external view returns (string memory); // Returns a human-readable description of the price feed
    function version() external view returns (uint256); // Returns the version of the price feed contract
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound); // Returns the data for a specific round ID
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound); // Returns the data for the latest round
}


/**
 * @title Subscription Contract for NEFSTER.COM
 * @dev This contract allows users to subscribe to a service using WETH or USDC.
 */
contract Subscription is Ownable, Pausable {
    struct Subscriber {
        uint256 start;
        uint256 end;
        address token;
        uint256 unSubDate;
    }

    mapping(address => Subscriber) public subscribers;

    AggregatorV3Interface private priceFeedETH;
    IERC20 private WETH;
    IERC20 private USDC;
    IERC20 private DAI;
    IERC20 private USDT;

    uint256 public subscriptionPriceUSD;
    uint256 public gracePeriod = 2 * 86400; // 2 days in seconds

    event SubscribeEvent(address indexed user, uint256 start, uint256 end, address token);
    event UnsubscribeEvent(address indexed user);
    event CollectPaymentEvent(address indexed user, uint256 amount);
    event UnfundedErrorEvent(address indexed user);

    /**
     * @dev Contract constructor. Sets initial subscription price and token addresses.
     */
    constructor() {
        priceFeedETH = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // Chainlink ETH/USD Price Feed Mainnet Address
        WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH Mainnet Address
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC Mainnet Address
        DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI Mainnet Address
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT (Tether) Mainnet Address

        setSubscriptionPriceUSD(20);
    }


    /**
     * @dev Allows the owner to set the subscription price.
     * @param _price The new subscription price.
     */
    function setSubscriptionPriceUSD(uint256 _price) public onlyOwner {
        subscriptionPriceUSD = _price;
    }

    /**
     * @dev Allows the owner to set the grace period.
     * @param _gracePeriod The new grace period in seconds.
     */
    function setGracePeriod(uint256 _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
    }

    /**
     * @dev Allows a user to subscribe to the service.
     * @param _token The address of the  token the user wants to use for payment 
     */
    function subscribe(address _token) external whenNotPaused {
        require(_token == address(WETH) || _token == address(USDC) || _token == address(DAI) || _token == address(USDT), "Invalid token");
        uint256 subscriptionPrice = getSubscriptionPrice(_token);
        require(IERC20(_token).transferFrom(msg.sender, address(this), subscriptionPrice), "Transfer failed");

        Subscriber storage subscriber = subscribers[msg.sender];
        subscriber.start = block.timestamp;
        subscriber.end = block.timestamp + 30 days;
        subscriber.token = _token;
        subscriber.unSubDate = 0;

        emit SubscribeEvent(msg.sender, subscriber.start, subscriber.end, _token);
    }

    /**
     * @dev Allows a user to unsubscribe from the service.
     */
    function unsubscribe() external {
        require(isSubscriber(msg.sender), "Not a subscriber");
        if (subscribers[msg.sender].unSubDate == 0) {
            subscribers[msg.sender].unSubDate = subscribers[msg.sender].start + 30 days;
        }
        emit UnsubscribeEvent(msg.sender);
    }

    /**
    * @dev admin function to unsubscribe an address immediately  
    */
    function unsubscribeAdmin(address _address) external onlyOwner {
        subscribers[_address].unSubDate = block.timestamp;
        emit UnsubscribeEvent(_address);
    }

    /**
     * @dev Allows the owner to collect payment from a user.
     * @param _user The user to collect payment from.
     */
    function collectPayment(address _user) external onlyOwner {
        require(isSubscriber(_user), "Not a subscriber");
        Subscriber storage subscriber = subscribers[_user];
        require(block.timestamp >= subscriber.end, "Cannot collect payment before subscription end");
        uint256 subscriptionPrice = getSubscriptionPrice(subscriber.token);
        if (IERC20(subscriber.token).balanceOf(_user) < subscriptionPrice) {
            emit UnfundedErrorEvent(_user);
            subscribers[_user].unSubDate = subscribers[_user].start + 30 days;
            return;
        }
        require(IERC20(subscriber.token).transferFrom(_user, address(this), subscriptionPrice), "Transfer failed");
        subscriber.start = subscriber.end;
        subscriber.end += 30 days;

        emit CollectPaymentEvent(_user, subscriptionPrice);
    }



    /**
     * @dev Checks if a user is a subscriber.
     * @param _user The user to check.
     * @return True if the user is a subscriber, false otherwise.
     */
    function isSubscriber(address _user) public view returns (bool) {
        Subscriber storage subscriber = subscribers[_user];
        if (subscriber.unSubDate != 0 && block.timestamp > subscriber.unSubDate) {
            // User has chosen to unsubscribe and the unsubscription date has passed
            return false;
        }
        return (subscriber.end != 0 && block.timestamp <= subscriber.end + gracePeriod);
    }


    /**
    * @dev Gets the subscription price in the specified token.
    * @param _token The token to get the subscription price in.
    * @return The subscription price in the specified token.
    */
    function getSubscriptionPrice(address _token) public view returns (uint256) {
        if (_token == address(WETH)) {
            (, int256 priceETH,,,) = priceFeedETH.latestRoundData();
            return (subscriptionPriceUSD * 10**18 * 10**8) / uint256(priceETH); // Convert to token units
        } else if (_token == address(USDC) || _token == address(DAI) || _token == address(USDT)) {
            return subscriptionPriceUSD * 10**6; // 1 USDC/DAI/USDT = 1 USD, and USDC/DAI/USDT has 6 decimal places
        } else {
            revert("Invalid token");
        }
    }


    /**
     * @dev Allows the owner to withdraw ERC20 tokens from the contract.
     * @param _token The token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "Not enough balance");
        require(_token.transfer(owner(), _amount), "Transfer failed");
    }

    /**
    * @dev returns the contract balance of a given ERC20 token
    * @param _token address of the token 
    */
    function tokenBalance(IERC20 _token) public view returns (uint256){
        return _token.balanceOf(address(this));
    }

}