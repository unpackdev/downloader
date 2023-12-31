// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./HalfLifeCarbonCreditAuction.sol";
import "./ICarbonCreditAuction.sol";
/**
 * @title CarbonCreditDescendingPriceAuction
 * @notice This contract is a reverse dutch auction for GCC.
 *         - The price has a half life of 1 week
 *         - The max that the price can grow is 2x per 24 hours
 *         - For every sale made, the price increases by the % of the total sold that the sale was
 *             - For example, if 10% of the available GCC is sold, then the price increases by 10%
 *             - If 100% of the available GCC is sold, then the price doubles
 *         - GCC is added to the pool of available GCC linearly over the course of a week
 *         - When new GCC is added, all pending vesting amounts and the new amount are vested over the course of a week
 *         - There is no cap on the amount of GCC that can be purchased in a single transaction
 *         - All GCC donations must be registered by the miner pool contract
 * @author DavidVorick
 * @author 0xSimon(twitter) -  0xSimbo(github)
 */

contract CarbonCreditDescendingPriceAuction is ICarbonCreditAuction {
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error CallerNotGCC();
    error UserPriceNotHighEnough();
    error NotEnoughGCCForSale();
    error CannotBuyZeroUnits();

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev The precision (magnifier) used for calculations
    uint256 private constant PRECISION = 1e8;
    /// @dev The number of seconds in a day
    uint256 private constant ONE_DAY = uint256(1 days);
    /// @dev The number of seconds in a week
    uint256 private constant ONE_WEEK = uint256(7 days);
    /**
     * @notice the amount of GCC sold within a single unit (0.000000000001 GCC)
     * @dev This is equal to 1e-12 GCC
     */
    uint256 public constant SALE_UNIT = 1e6;

    /* -------------------------------------------------------------------------- */
    /*                                 immutables                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice The GLOW token
    IERC20 public immutable GLOW;
    /// @notice The GCC token
    IERC20 public immutable GCC;

    /* -------------------------------------------------------------------------- */
    /*                                 state vars                                */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev a variable to keep track of the total amount of GCC that has been fully vested
     *         - it's not accurate and should only be used in conjunction with
     *             - {totalAmountReceived} to calculate the total supply
     *             - as shown in {totalSupply}
     */
    uint256 internal _pesudoTotalAmountFullyAvailableForSale;

    /// @notice The total amount of GLOW received from the miner pool
    uint256 public totalAmountReceived;

    /// @notice The total number of units of GCC sold
    uint256 public totalUnitsSold;

    /// @notice The price of GCC 24 hours ago
    ///         - this price is not accurate if there have been no sales in the last 24 hours
    ///         - it should not be relied on for accurate calculations
    uint256 public pseudoPrice24HoursAgo;

    /// @dev The price of GCC per sale unit
    /// @dev this price is not the actual price, and should be used in conjunction with {getPricePerUnit}
    uint256 internal pricePerSaleUnit;

    /// @notice The timestamps
    Timestamps public timestamps;

    /* -------------------------------------------------------------------------- */
    /*                                   structs                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev A struct to keep track of the timestamps all in a single slot
     * @param lastSaleTimestamp the timestamp of the last sale
     * @param lastReceivedTimestamp the timestamp of the last time GCC was received from the miner pool
     * @param lastPriceChangeTimestamp the timestamp of the last time the price changed
     */
    struct Timestamps {
        uint64 lastSaleTimestamp;
        uint64 lastReceivedTimestamp;
        uint64 lastPriceChangeTimestamp;
        uint64 firstReceivedTimestamp;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    /**
     * @param glow the GLOW token
     * @param gcc the GCC token
     * @param startingPrice the starting price of 1 unit of GCC
     */
    constructor(IERC20 glow, IERC20 gcc, uint256 startingPrice) payable {
        GLOW = glow;
        GCC = gcc;
        pricePerSaleUnit = startingPrice;
        pseudoPrice24HoursAgo = startingPrice;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 buy gcc                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc ICarbonCreditAuction
     */
    function buyGCC(uint256 unitsToBuy, uint256 maxPricePerUnit) external {
        if (unitsToBuy == 0) {
            _revert(CannotBuyZeroUnits.selector);
        }
        Timestamps memory _timestamps = timestamps;
        uint256 _lastPriceChangeTimestamp = _timestamps.lastPriceChangeTimestamp;
        uint256 _pseudoPrice24HoursAgo = pseudoPrice24HoursAgo;
        uint256 price = getPricePerUnit();
        if (price > maxPricePerUnit) {
            _revert(UserPriceNotHighEnough.selector);
        }
        uint256 gccPurchasing = unitsToBuy * SALE_UNIT;
        uint256 glowToTransfer = unitsToBuy * price;

        uint256 totalSaleUnitsAvailable = totalSaleUnits();
        uint256 saleUnitsLeftForSale = totalSaleUnitsAvailable - totalUnitsSold;

        if (saleUnitsLeftForSale < unitsToBuy) {
            _revert(NotEnoughGCCForSale.selector);
        }

        uint256 newPrice = price + (price * (unitsToBuy * PRECISION / saleUnitsLeftForSale) / PRECISION);

        //The new price can never grow more than 100% in 24 hours
        if (newPrice * PRECISION / _pseudoPrice24HoursAgo > 2 * PRECISION) {
            newPrice = _pseudoPrice24HoursAgo * 2;
        }
        //If it's been more than a day since the last sale, then update the price
        //To the price in the current tx
        //Also update the last price change timestamp
        if (block.timestamp - _lastPriceChangeTimestamp > ONE_DAY) {
            pseudoPrice24HoursAgo = price;
            _lastPriceChangeTimestamp = block.timestamp;
        }

        //
        pricePerSaleUnit = newPrice;

        totalUnitsSold += unitsToBuy;
        timestamps = Timestamps({
            lastSaleTimestamp: uint64(block.timestamp),
            lastReceivedTimestamp: _timestamps.lastReceivedTimestamp,
            lastPriceChangeTimestamp: uint64(_lastPriceChangeTimestamp),
            firstReceivedTimestamp: _timestamps.firstReceivedTimestamp
        });
        GLOW.transferFrom(msg.sender, address(this), glowToTransfer);
        GCC.transfer(msg.sender, gccPurchasing);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 receive gcc                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc ICarbonCreditAuction
     */
    function receiveGCC(uint256 amount) external {
        if (msg.sender != address(GCC)) {
            _revert(CallerNotGCC.selector);
        }
        Timestamps memory _timestamps = timestamps;
        _pesudoTotalAmountFullyAvailableForSale = totalSupply();
        timestamps = Timestamps({
            lastSaleTimestamp: _timestamps.lastSaleTimestamp,
            lastReceivedTimestamp: uint64(block.timestamp),
            lastPriceChangeTimestamp: _timestamps.lastPriceChangeTimestamp,
            firstReceivedTimestamp: _timestamps.firstReceivedTimestamp == 0
                ? uint64(block.timestamp)
                : _timestamps.firstReceivedTimestamp
        });
        totalAmountReceived += amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 view functions                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc ICarbonCreditAuction
     */
    function getPricePerUnit() public view returns (uint256) {
        Timestamps memory _timestamps = timestamps;
        uint256 _lastSaleTimestamp = _timestamps.lastSaleTimestamp;
        uint256 firstReceivedTimestamp = _timestamps.firstReceivedTimestamp;
        if (firstReceivedTimestamp == 0) {
            return pricePerSaleUnit;
        }
        if (_lastSaleTimestamp == 0) {
            _lastSaleTimestamp = firstReceivedTimestamp;
        }
        uint256 _pricePerSaleUnit = pricePerSaleUnit;
        return
            HalfLifeCarbonCreditAuction.calculateHalfLifeValue(_pricePerSaleUnit, block.timestamp - _lastSaleTimestamp);
    }

    /**
     * @inheritdoc ICarbonCreditAuction
     */
    function totalSupply() public view returns (uint256) {
        Timestamps memory _timestamps = timestamps;
        uint256 _lastReceivedTimestamp = _timestamps.lastReceivedTimestamp;
        uint256 _totalAmountReceived = totalAmountReceived;
        uint256 amountThatNeedsToVest = _totalAmountReceived - _pesudoTotalAmountFullyAvailableForSale;
        uint256 timeDiff = _min(ONE_WEEK, block.timestamp - _lastReceivedTimestamp);
        return (_pesudoTotalAmountFullyAvailableForSale + amountThatNeedsToVest * timeDiff / ONE_WEEK);
    }

    /**
     * @inheritdoc ICarbonCreditAuction
     */
    function unitsForSale() external view returns (uint256) {
        return totalSaleUnits() - totalUnitsSold;
    }

    /**
     * @inheritdoc ICarbonCreditAuction
     */
    function totalSaleUnits() public view returns (uint256) {
        return totalSupply() / (SALE_UNIT);
    }

    /* -------------------------------------------------------------------------- */
    /*                                     utils                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @param a the first number
     * @param b the second number
     * @return smaller - the smaller of the two numbers
     */
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    /**
     * @notice More efficiently reverts with a bytes4 selector
     * @param selector The selector to revert with
     */
    function _revert(bytes4 selector) private pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(0x0, selector)
            revert(0x0, 0x04)
        }
    }
}
