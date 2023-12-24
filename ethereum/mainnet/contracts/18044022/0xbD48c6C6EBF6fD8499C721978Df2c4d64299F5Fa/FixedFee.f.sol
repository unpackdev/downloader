// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

library Fixed256x18 {
    uint256 internal constant ONE = 1e18; // 18 decimal places

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            return (((a * ONE) - 1) / b) + 1;
        }
    }

    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

interface IPriceOracle {
    // --- Errors ---

    /// @dev Contract initialized with an invalid deviation parameter.
    error InvalidDeviation();

    // --- Types ---

    struct PriceOracleResponse {
        bool isBrokenOrFrozen;
        bool priceChangeAboveMax;
        uint256 price;
    }

    // --- Functions ---

    /// @dev Return price oracle response which consists the following information: oracle is broken or frozen, the
    /// price change between two rounds is more than max, and the price.
    function getPriceOracleResponse() external returns (PriceOracleResponse memory);

    /// @dev Maximum time period allowed since oracle latest round data timestamp, beyond which oracle is considered
    /// frozen.
    function timeout() external view returns (uint256);

    /// @dev Used to convert a price answer to an 18-digit precision uint.
    function TARGET_DIGITS() external view returns (uint256);

    /// @dev price deviation for the oracle in percentage.
    function DEVIATION() external view returns (uint256);
}

interface IPriceFeed {
    // --- Events ---

    /// @dev Last good price has been updated.
    event LastGoodPriceUpdated(uint256 lastGoodPrice);

    /// @dev Price difference between oracles has been updated.
    /// @param priceDifferenceBetweenOracles New price difference between oracles.
    event PriceDifferenceBetweenOraclesUpdated(uint256 priceDifferenceBetweenOracles);

    /// @dev Primary oracle has been updated.
    /// @param primaryOracle New primary oracle.
    event PrimaryOracleUpdated(IPriceOracle primaryOracle);

    /// @dev Secondary oracle has been updated.
    /// @param secondaryOracle New secondary oracle.
    event SecondaryOracleUpdated(IPriceOracle secondaryOracle);

    // --- Errors ---

    /// @dev Invalid primary oracle.
    error InvalidPrimaryOracle();

    /// @dev Invalid secondary oracle.
    error InvalidSecondaryOracle();

    /// @dev Primary oracle is broken or frozen or has bad result.
    error PrimaryOracleBrokenOrFrozenOrBadResult();

    /// @dev Invalid price difference between oracles.
    error InvalidPriceDifferenceBetweenOracles();

    // --- Functions ---

    /// @dev Return primary oracle address.
    function primaryOracle() external returns (IPriceOracle);

    /// @dev Return secondary oracle address
    function secondaryOracle() external returns (IPriceOracle);

    /// @dev The last good price seen from an oracle by Raft.
    function lastGoodPrice() external returns (uint256);

    /// @dev The maximum relative price difference between two oracle responses.
    function priceDifferenceBetweenOracles() external returns (uint256);

    /// @dev Set primary oracle address.
    /// @param newPrimaryOracle Primary oracle address.
    function setPrimaryOracle(IPriceOracle newPrimaryOracle) external;

    /// @dev Set secondary oracle address.
    /// @param newSecondaryOracle Secondary oracle address.
    function setSecondaryOracle(IPriceOracle newSecondaryOracle) external;

    /// @dev Set the maximum relative price difference between two oracle responses.
    /// @param newPriceDifferenceBetweenOracles The maximum relative price difference between two oracle responses.
    function setPriceDifferenceBetweenOracles(uint256 newPriceDifferenceBetweenOracles) external;

    /// @dev Returns the latest price obtained from the Oracle. Called by Raft functions that require a current price.
    ///
    /// Also callable by anyone externally.
    /// Non-view function - it stores the last good price seen by Raft.
    ///
    /// Uses a primary oracle and a fallback oracle in case primary fails. If both fail,
    /// it uses the last good price seen by Raft.
    ///
    /// @return currentPrice Returned price.
    /// @return deviation Deviation of the reported price in percentage.
    /// @notice Actual returned price is in range `currentPrice` +/- `currentPrice * deviation / ONE`
    function fetchPrice() external returns (uint256 currentPrice, uint256 deviation);
}

/// @dev Interface that PSM fee calculators need to follow
interface IPSMFeeCalculator {
    /// @dev Calculates fee for buying R from PSM or selling it to PSM. Should revert in case of not allowed trade.
    /// @param amount Amount of tokens coming into PSM. Expressed in R, or reserve token.
    /// @param isBuyingR True if user is buying R by depositing reserve to the PSM.
    function calculateFee(uint256 amount, bool isBuyingR) external returns (uint256 feeAmount);
}

/// @dev Constant fee calculator for PSM.
contract PSMFixedFee is IPSMFeeCalculator, Ownable2Step {
    using Fixed256x18 for uint256;

    /// @dev Fees are set by the owner.
    /// @param buyRFee_ Fee percentage for buying R.
    /// @param buyReserveFee_ Fee percentage for buying reserve.
    event FeesSet(uint256 buyRFee_, uint256 buyReserveFee_);

    /// @dev Price feed contract address was set.
    /// @param priceFeed_ Address of the price feed contract.
    event PriceFeedSet(IPriceFeed priceFeed_);

    /// @dev Price of reserve considered as lowest acceptable price at which trading is allowed.
    /// @param reserveDepegThreshold_ Threshold of the reserve price to consider it depegged.
    event ReserveDepegThresholdSet(uint256 reserveDepegThreshold_);

    /// @dev Thrown in case of setting invalid fee percentage.
    error InvalidFee();

    /// @dev Thrown in case of providing zero address as input.
    error ZeroAddressProvided();

    /// @dev Thrown in case of action is disabled because of reserve depeg.
    /// @param currentReservePrice The current price of reserve found in oracle.
    error DisabledBecauseOfReserveDepeg(uint256 currentReservePrice);

    /// @dev Fee percentage for buying R from PSM.
    uint256 public buyRFee;

    /// @dev Fee percentage for buying reserve token from PSM.
    uint256 public buyReserveFee;

    /// @dev Address of the price feed contract.
    IPriceFeed public priceFeed;

    /// @dev Price of reserve considered as lowest acceptable price at which trading is allowed.
    uint256 public reserveDepegThreshold;

    constructor(uint256 buyRFee_, uint256 buyReserveFee_, IPriceFeed priceFeed_, uint256 reserveDepegThreshold_) {
        setFees(buyRFee_, buyReserveFee_);
        setPriceFeed(priceFeed_);
        setReserveDepegThreshold(reserveDepegThreshold_);
    }

    function calculateFee(uint256 amount, bool isBuyingR) external override returns (uint256 feeAmount) {
        if (isBuyingR) {
            (uint256 currentReservePrice,) = priceFeed.fetchPrice();
            if (currentReservePrice < reserveDepegThreshold) {
                revert DisabledBecauseOfReserveDepeg(currentReservePrice);
            }
            return amount.mulUp(buyRFee);
        }
        return amount.mulUp(buyReserveFee);
    }

    /// @dev Set fees for buying R and reserve token. Callable only by contract owner.
    /// @param buyRFee_ Fee percentage for buying R.
    /// @param buyReserveFee_ Fee percentage for buying reserve.
    function setFees(uint256 buyRFee_, uint256 buyReserveFee_) public onlyOwner {
        if (buyRFee_ > Fixed256x18.ONE || buyReserveFee_ > Fixed256x18.ONE) {
            revert InvalidFee();
        }
        buyRFee = buyRFee_;
        buyReserveFee = buyReserveFee_;
        emit FeesSet(buyRFee_, buyReserveFee_);
    }

    /// @dev Set new price feed contract address. Callable only by contract owner.
    /// @param priceFeed_ Address of the price feed contract.
    function setPriceFeed(IPriceFeed priceFeed_) public onlyOwner {
        if (address(priceFeed_) == address(0)) {
            revert ZeroAddressProvided();
        }
        priceFeed = priceFeed_;
        emit PriceFeedSet(priceFeed_);
    }

    /// @dev Set new price threshold for reserve. Callable only by contract owner.
    /// @param reserveDepegThreshold_ Threshold of the reserve price to consider it depegged.
    function setReserveDepegThreshold(uint256 reserveDepegThreshold_) public onlyOwner {
        reserveDepegThreshold = reserveDepegThreshold_;
        emit ReserveDepegThresholdSet(reserveDepegThreshold_);
    }
}
