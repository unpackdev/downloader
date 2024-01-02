pragma solidity 0.6.7;

import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";

abstract contract TokenLike {
    function balanceOf(address) public view virtual returns (uint256);
}

contract UniswapV3Medianizer {
    // --- Auth ---
    mapping(address => uint) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external virtual isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }

    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(
        address account
    ) external virtual isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }

    /**
     * @notice Checks whether msg.sender can call an authed function
     **/
    modifier isAuthorized() {
        require(
            authorizedAccounts[msg.sender] == 1,
            "UniswapV3Medianizer/account-not-authorized"
        );
        _;
    }

    // --- Uniswap Vars ---
    // Default amount of targetToken used when calculating the denominationToken output
    uint128 public defaultAmountIn = 1 ether;
    // Minimum liquidity of targetToken to consider a valid result
    uint256 public minimumLiquidity;
    // Token for which the contract calculates the medianPrice for
    address public targetToken;
    // Pair token from the Uniswap pair
    address public denominationToken;
    // The pool to read price data from
    address public uniswapPool;

    // --- General Vars ---
    // The desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint32 public windowSize;
    // Manual flag that can be set by governance and indicates if a result is valid or not
    uint256 public validityFlag;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(bytes32 parameter, uint256 val);

    constructor(
        address uniswapPool_,
        address targetToken_,
        uint32 windowSize_,
        uint256 minimumLiquidity_
    ) public {
        require(
            uniswapPool_ != address(0),
            "UniswapV3Medianizer/null-uniswap-factory"
        );
        require(windowSize_ > 0, "UniswapV3Medianizer/null-window-size");

        authorizedAccounts[msg.sender] = 1;

        uniswapPool = uniswapPool_;
        windowSize = windowSize_;
        minimumLiquidity = minimumLiquidity_;
        validityFlag = 1;
        targetToken = targetToken_;

        address token0 = IUniswapV3Pool(uniswapPool_).token0();
        address token1 = IUniswapV3Pool(uniswapPool_).token1();

        require(
            targetToken_ == token0 || targetToken_ == token1,
            "UniswapV3Medianizer/target-not-from-pool"
        );

        denominationToken = targetToken_ == token0 ? token1 : token0;

        // Emit events
        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("windowSize"), windowSize_);
    }

    // --- General Utils --
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    function both(bool x, bool y) private pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "UniswapV3Medianizer/toUint128_overflow");
        return uint128(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2 ** 32, "UniswapV3Medianizer/toUint32_overflow");
        return uint32(value);
    }

    // --- Administration ---
    /**
     * @notice Modify uint256 parameters
     * @param parameter Name of the parameter to modify
     * @param data New parameter value
     **/
    function modifyParameters(
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        if (parameter == "validityFlag") {
            require(
                either(data == 1, data == 0),
                "UniswapV3Medianizer/invalid-data"
            );
            validityFlag = data;
        } else if (parameter == "defaultAmountIn") {
            require(data > 0, "UniswapV3Medianizer/invalid-default-amount-in");
            defaultAmountIn = toUint128(data);
        } else if (parameter == "windowSize") {
            require(data > 0, "UniswapV3Medianizer/invalid-window-size");
            windowSize = toUint32(data);
        } else if (parameter == "minimumLiquidity") {
            minimumLiquidity = data;
        } else revert("UniswapV3Medianizer/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Getters ---
    /**
     * @notice Returns true if feed is valid
     **/
    function isValid() public view returns (bool) {
        return
            both(
                validityFlag == 1,
                TokenLike(targetToken).balanceOf(address(uniswapPool)) >=
                    minimumLiquidity
            );
    }

    /**
     * @notice Returns medianPrice for windowSize
     **/
    function getTwapPrice() public view returns (uint256) {
        return getTwapPrice(windowSize);
    }

    /**
     * @notice Returns medianPrice for a given period
     * @param period Number of seconds in the past to start calculating time-weighted average
     * @return TWAP
     **/
    function getTwapPrice(uint32 period) public view returns (uint256) {
        int24 timeWeightedAverageTick = consult(
            address(uniswapPool),
            period,
            0
        );
        return
            OracleLibrary.getQuoteAtTick(
                timeWeightedAverageTick,
                defaultAmountIn,
                targetToken,
                denominationToken
            );
    }

    /**
     * @notice Returns medianPrice for a given period
     * @param periodStart Number of seconds in the past to start calculating time-weighted average
     * @param periodEnd Number of seconds in the past to end calculating time-weighted average
     * @return TWAP
     **/
    function getTwapPrice(uint32 periodStart, uint32 periodEnd) public view returns (uint256) {
        int24 timeWeightedAverageTick = consult(
            address(uniswapPool),
            periodStart,
            periodEnd
        );
        return
            OracleLibrary.getQuoteAtTick(
                timeWeightedAverageTick,
                defaultAmountIn,
                targetToken,
                denominationToken
            );
    }    

    /**
     * @notice Fetch the latest medianPrice (for maxWindow) or revert if is is null
     **/
    function read() external view returns (uint256 value) {
        value = getTwapPrice();
        require(
            both(value > 0, isValid()),
            "UniswapV3Medianizer/invalid-price-feed"
        );
    }

    /**
     * @notice Fetch the latest medianPrice and whether it is null or not
     **/
    function getResultWithValidity()
        external
        view
        returns (uint256 value, bool valid)
    {
        value = getTwapPrice();
        valid = both(value > 0, isValid());
    }

    
    /// @notice Fetches time-weighted average tick using Uniswap V3 oracle
    /// @notice Updated from OracleLibrary code to allow for setting an end timestamp to the TWAP
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @param periodStartSecondsAgo Number of seconds in the past to start calculating time-weighted average
    /// @param periodEndSecondsAgo Number of seconds in the past to end calculating time-weighted average
    /// @return timeWeightedAverageTick The time-weighted average tick from (block.timestamp - period) to block.timestamp
    function consult(
        address pool,
        uint32 periodStartSecondsAgo,
        uint32 periodEndSecondsAgo
    ) internal view returns (int24 timeWeightedAverageTick) {
        require(periodStartSecondsAgo != 0, "BP");

        uint32 period = periodStartSecondsAgo - periodEndSecondsAgo;

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = periodStartSecondsAgo;
        secondAgos[1] = periodEndSecondsAgo;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(
            secondAgos
        );
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / period);

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % period != 0))
            timeWeightedAverageTick--;
    }
}
