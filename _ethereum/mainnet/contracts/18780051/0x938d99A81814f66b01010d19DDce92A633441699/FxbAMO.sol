// SPDX-License-Identifier: ISC
pragma solidity ^0.8.23;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================== FxbAMO ==============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

import "./ERC20.sol";
import "./Timelock2Step.sol";
import "./Operator2Step.sol";
import "./FXB.sol";
import "./FXBFactory.sol";
import "./SlippageAuction.sol";
import "./SlippageAuctionFactory.sol";

/// @title FXB AMO
/// @notice Contract to manage auctions started by the Frax team of Frax bonds
/// @dev "Bond" and "FXB" are used interchangeably
/// @dev https://github.com/FraxFinance/frax-bonds-amo
contract FxbAMO is Timelock2Step, OperatorRole2Step {
    // ==============================================================================
    // Storage
    // ==============================================================================

    /// @notice The lowest priceMin allowed when calling `startAuction()`
    uint128 public globalMinPriceMin;

    /// @notice Cumulative amount of FXB listed for auction via `startAuction()`
    uint256 public totalFxbAuctioned;

    /// @notice Cumulative amount of FXB pending in outstanding auctions
    uint256 public totalFxbPending;

    /// @notice Cumulative amount of FRAX received via `stopAuction()`
    uint256 public totalFraxReceived;

    /// @notice Cumulative amount of excess FRAX received from non-swap transfers to auctions via `stopAuction()`
    uint256 public totalFraxExcess;

    /// @notice Cumulative amount of FRAX withdrawn via `withdrawFrax()`
    uint256 public totalFraxWithdrawn;

    /// @notice Cumulative amount of FXB sold after auction close via `stopAuction()`
    uint256 public totalFxbSold;

    /// @notice Cumulative amount of FXB not sold after auction close via `stopAuction()`
    uint256 public totalFxbUnsold;

    /// @notice Cumulative amount of excess bonds received from non-swap transfers to auctions via `stopAuction()`
    uint256 public totalFxbExcess;

    /// @notice Cumulative amount of FXB minted either through `startAuction()` or `mintBonds()`
    uint256 public totalFxbMinted;

    /// @notice Cumulative amoount of FXB redeemed for FRAX
    uint256 public totalFxbRedeemed;

    /// @notice Cumulative amount of FXB withdrawn by timelock
    uint256 public totalFxbWithdrawn;

    /// @notice Interface address of the FXBFactory
    FXBFactory public immutable iFxbFactory;

    /// @notice Interface Address of the SlippageAuctionFactory
    SlippageAuctionFactory public immutable iAuctionFactory;

    /// @notice Interface address of FRAX
    IERC20 public immutable iFrax;

    /// @notice The longest duration a bond will take to expire, ie. 5 weeks rounds down to 1 month
    enum TimeToMaturity {
        NOW, // 0 seconds
        ONE_MONTH, // 30 days
        THREE_MONTHS, // 90 days
        SIX_MONTHS, // 180 days
        ONE_YEAR, // 365 days
        TWO_YEARS, // 365 * 2 days
        THREE_YEARS, // 365 * 3 days
        FIVE_YEARS, // 365 * 5 days
        SEVEN_YEARS, // 365 * 7 days
        TEN_YEARS // 365 * 10 days
    }

    /// @notice Details behind each `TimeToMaturity`
    /// @param minPriceMin  The lowest priceMin for the `TimeToMaturity` allowed via `startAuction()`
    /// @param duration     The duration in seconds for the maturity to be redeemable
    struct TimeToMaturityDetail {
        uint128 minPriceMin;
        uint128 duration;
    }

    /// @notice Mapping of all TimeToMaturity periods to their associated `TimeToMaturityDetail`
    mapping(TimeToMaturity => TimeToMaturityDetail) public timeToMaturityDetails;

    /// @notice Details behind each FXB auction
    /// @dev There is a 1:1 relationship between auction and FXB
    /// @param fxb Address of bond
    /// @param fxbAllowedToAuction Cumulative amount of bonds allowed to auction as set by timelock
    /// @param fxbAuctioned Cumulative amount of bonds auctioned via `startAuction()`
    /// @param fxbPending Current amount of FXB pending in current auction
    /// @param fxbUnsold Cumulative amount of bonds not sold via `stopAuction()`
    /// @param fxbSold Cumulative amount of bonds sold via `stopAuction()`
    /// @param fxbExcess Cumulative amount of excess bonds returned from non-swap transfers via `stopAuction()`
    /// @param fraxReceived Cumulative amount of FRAX received in auction sales via `stopAuction()`
    /// @param fraxExcess Cumulative amount of excess FRAX received from non-swap transfers via `stopAuction()`
    /// @param fxbMinted Cumulative amount of bonds minted by the AMO
    /// @param fxbRedeemed Cumulative amount of bonds redeemed by the AMO
    /// @param fxbWithdrawn Cumulative amount of bonds withdrawn from the AMO
    struct AuctionDetail {
        address fxb;
        uint256 fxbAllowedToAuction;
        uint256 fxbAuctioned;
        uint256 fxbPending;
        uint256 fxbUnsold;
        uint256 fxbSold;
        uint256 fxbExcess;
        uint256 fraxReceived;
        uint256 fraxExcess;
        uint256 fxbMinted;
        uint256 fxbRedeemed;
        uint256 fxbWithdrawn;
    }

    /// @notice mapping of all auction contracts to their associated `AuctionDetail`
    mapping(address auction => AuctionDetail) public auctionDetails;

    /// @notice reverse-lookup of bond address to auction address
    mapping(address fxb => address auction) public fxbToAuction;

    /// @notice Array of AMO-created auction contract addresses
    address[] public auctions;

    /// @param _timelock Address of timelock/owner
    /// @param _operator Address of approved operator
    /// @param _fxbFactory Address of deployed FXBFactory
    /// @param _auctionFactory Address of deployed SlippageAuctionFactory
    /// @param _frax Address of deployed FRAX
    constructor(
        address _timelock,
        address _operator,
        address _fxbFactory,
        address _auctionFactory,
        address _frax
    ) Timelock2Step(_timelock) OperatorRole2Step(_operator) {
        iFxbFactory = FXBFactory(_fxbFactory);
        iAuctionFactory = SlippageAuctionFactory(_auctionFactory);
        iFrax = IERC20(_frax);

        // Fill out timeToMaturity duration for interpolation
        timeToMaturityDetails[TimeToMaturity.ONE_MONTH].duration = 30 days;
        timeToMaturityDetails[TimeToMaturity.THREE_MONTHS].duration = 90 days;
        timeToMaturityDetails[TimeToMaturity.SIX_MONTHS].duration = 180 days;
        timeToMaturityDetails[TimeToMaturity.ONE_YEAR].duration = 365 days;
        timeToMaturityDetails[TimeToMaturity.TWO_YEARS].duration = 365 * 2 days;
        timeToMaturityDetails[TimeToMaturity.THREE_YEARS].duration = 365 * 3 days;
        timeToMaturityDetails[TimeToMaturity.FIVE_YEARS].duration = 365 * 5 days;
        timeToMaturityDetails[TimeToMaturity.SEVEN_YEARS].duration = 365 * 7 days;
        timeToMaturityDetails[TimeToMaturity.TEN_YEARS].duration = 365 * 10 days;
    }

    /// @notice Semantic version of this contract
    /// @return _major The major version
    /// @return _minor The minor version
    /// @return _patch The patch version
    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch) {
        return (1, 0, 0);
    }

    //==============================================================================
    // Acccess Control Functions
    //==============================================================================

    /// @dev Requirements for all functions that are callable by both the timelock and operator
    function _requireTimelockOrOperator(address _fxb) internal view {
        if (!(_isTimelock(msg.sender) || _isOperator(msg.sender))) {
            revert NotOperatorOrTimelock();
        }

        if (!isFxbApproved(_fxb)) {
            revert BondNotApproved();
        }
    }

    /// @notice Initiates the two-step operator transfer.
    /// @dev For role acceptance/renouncing documentation, see github.com/frax-standard-solidity/src/access-control/Operator2Step.sol
    /// @param _newOperator Address of the nominated (pending) operator
    function transferOperator(address _newOperator) external override {
        _requireSenderIsTimelock();
        _transferOperator(_newOperator);
    }

    //==============================================================================
    // Main Functions
    //==============================================================================

    /// @notice Create an auction contract for a bond created by the FXBFactory
    /// @dev Callable by timelock
    /// @param _fxb Address of bond
    /// @return auction Address of newly created auction contract
    function createAuctionContract(address _fxb) external returns (address auction) {
        _requireSenderIsTimelock();

        // Ensure fxb is legitimate from fxbFactory
        if (!iFxbFactory.isFxb(_fxb)) {
            revert NotLegitimateBond();
        }

        if (fxbToAuction[_fxb] != address(0)) {
            revert AuctionAlreadyCreated();
        }

        // Create the auction
        auction = iAuctionFactory.createAuctionContract({
            _timelock: address(this),
            _tokenBuy: address(iFrax),
            _tokenSell: _fxb
        });

        // bookkeeping

        AuctionDetail storage auctionDetail = auctionDetails[auction];

        // Set bond address to auction and reverse-lookup
        auctionDetail.fxb = _fxb;
        fxbToAuction[_fxb] = auction;

        // Push to auctions array
        auctions.push(auction);

        emit CreateAuctionContract({ fxb: _fxb, auction: auction });
    }

    /// @notice Start an auction for a bond
    /// @dev Callable by operator/timelock
    /// @dev Mints additional bonds to auction if needed.
    /// @dev Reverts on invalid auction address or parameters
    /// @dev Reverts if selling more bonds than set by `auctionDetail.fxbAllowedToAuction`
    /// @dev Reverts if the auction ends before bond maturity
    /// @dev Reverts if auction minPrice is lower than the value of `calculateTimeWeightedMinPriceMin()`
    /// @param _auction Address of auction contract to call `startAuction()`
    /// @param _params Parameters of the auction as defined by `SlippageAuction.StartAuctionParams` struct
    function startAuction(address _auction, SlippageAuction.StartAuctionParams calldata _params) external {
        AuctionDetail storage auctionDetail = auctionDetails[_auction];
        address fxb = auctionDetail.fxb;
        FXB iFxb = FXB(fxb);

        _requireTimelockOrOperator(fxb);

        // revert if selling too much of bond
        /// @dev no check of 0 amountListed needed as `SlippageAuction.startAuction()` will revert
        if (_params.amountListed + auctionDetail.fxbAuctioned > auctionDetail.fxbAllowedToAuction) {
            revert TooManyBondsAuctioned();
        }

        // revert if bond has expired
        FXB.BondInfo memory bondInfo = iFxb.bondInfo();
        if (block.timestamp > bondInfo.maturityTimestamp) {
            revert BondAlreadyRedeemable();
        }

        // revert if auction end time is after bond expiry
        if (_params.expiry > bondInfo.maturityTimestamp) {
            revert BondExpiresBeforeAuctionEnd();
        }

        // calculate timeToMaturity
        uint128 delta = uint128(bondInfo.maturityTimestamp - block.timestamp);
        TimeToMaturity timeToMaturity = calculateTimeToMaturity(delta);

        // revert if the priceMin is below the acceptable value
        if (_params.priceMin < _calculateTimeWeightedMinPriceMin({ _delta: delta, _timeToMaturity: timeToMaturity })) {
            revert PriceMinTooLow();
        }

        // Effects

        // bookkeeping
        totalFxbAuctioned += _params.amountListed;
        auctionDetail.fxbAuctioned += _params.amountListed;

        totalFxbPending += _params.amountListed;
        auctionDetail.fxbPending += _params.amountListed;

        // Interactions

        // mint bonds if needed
        uint256 balance = iFxb.balanceOf(address(this));
        uint256 fxbMinted;
        if (balance < _params.amountListed) {
            fxbMinted = _params.amountListed - balance;
            _mintBonds({ _fxb: fxb, _amount: fxbMinted });
        }

        // Start the auction
        iFxb.approve(_auction, _params.amountListed);
        SlippageAuction(_auction).startAuction(_params);

        emit StartAuction({
            from: msg.sender,
            auction: _auction,
            fxbMinted: fxbMinted,
            fxbAuctioned: auctionDetail.fxbAuctioned,
            totalFxbAuctioned_: totalFxbAuctioned
        });
    }

    /// @notice Stop an auction for a bond
    /// @dev Callable by operator/timelock
    /// @dev Reverts on invalid auction address
    /// @param _auction Address of auction contract to call `stopAuction()`
    function stopAuction(address _auction) external {
        AuctionDetail storage auctionDetail = auctionDetails[_auction];
        address fxb = auctionDetail.fxb; // gas

        _requireTimelockOrOperator(fxb);

        // Stop the auction
        (uint256 fraxReceived, uint256 fxbUnsold) = SlippageAuction(_auction).stopAuction();

        // Bookkeeping
        SlippageAuction.Detail memory detail = SlippageAuction(_auction).getLatestAuction();
        uint256 fxbListed = detail.amountListed; // gas
        uint256 fraxExcess = detail.amountExcessBuy;
        uint256 fxbExcess = detail.amountExcessSell;

        totalFraxReceived += fraxReceived;
        auctionDetail.fraxReceived += fraxReceived;

        totalFraxExcess += fraxExcess;
        auctionDetail.fraxExcess += fraxExcess;

        totalFxbExcess += fxbExcess;
        auctionDetail.fxbExcess += fxbExcess;

        totalFxbUnsold += fxbUnsold;
        auctionDetail.fxbUnsold += fxbUnsold;
        // Allow re-use of unsold FXB
        auctionDetail.fxbAuctioned -= fxbUnsold;

        totalFxbSold += (fxbListed - fxbUnsold);
        auctionDetail.fxbSold += (fxbListed - fxbUnsold);

        totalFxbPending -= fxbListed;
        auctionDetail.fxbPending -= fxbListed;

        // NOTE: no event needed as the auction contract emits all necessary data
    }

    /// @notice Mint bonds to the AMO
    /// @dev Callable by timelock
    /// @param _fxb Address of bond to mint
    /// @param _amount Amount of bond to mint
    function mintBonds(address _fxb, uint256 _amount) external {
        _requireSenderIsTimelock();

        if (!isFxbApproved(_fxb)) {
            revert BondNotApproved();
        }

        _mintBonds({ _fxb: _fxb, _amount: _amount });
    }

    /// @dev no check on approved bond as this is method is also called within startAuction(), where
    ///         a check for the bond being approved already exists
    function _mintBonds(address _fxb, uint256 _amount) private {
        // bookkeeping
        totalFxbMinted += _amount;
        auctionDetails[fxbToAuction[_fxb]].fxbMinted += _amount;

        // Handle approvals
        iFrax.approve(_fxb, _amount);

        // Mint bond to this contract
        /// @dev reverts if _amount == 0
        FXB(_fxb).mint(address(this), _amount);
    }

    /// @notice Redeem bonds to a recipient by converting the FXB into FRAX
    /// @dev Callable by timelock
    /// @param _fxb Address of bond to redeem
    /// @param _recipient Address to received the received FRAX
    /// @param _amount Amount of bonds to redeem
    function redeemBonds(address _fxb, address _recipient, uint256 _amount) external {
        _requireSenderIsTimelock();

        if (!isFxbApproved(_fxb)) {
            revert BondNotApproved();
        }

        // bookkeeping
        totalFxbRedeemed += _amount;
        auctionDetails[fxbToAuction[_fxb]].fxbRedeemed += _amount;

        // Burn bond from this contract and send redeemed FRAX to recipient
        /// @dev reverts if _amount == 0
        FXB(_fxb).burn(_recipient, _amount);
    }

    /// @notice Withdraw FRAX held by this contract to a recipient
    /// @dev Callable by timelock
    /// @param _recipient Address to receive the withdrawn FRAX
    /// @param _amount Amount of FRAX to withdraw
    function withdrawFrax(address _recipient, uint256 _amount) external {
        _requireSenderIsTimelock();

        // bookkeeping
        totalFraxWithdrawn += _amount;

        iFrax.transfer(_recipient, _amount);
    }

    /// @notice Withdraw bonds held by this contract to a recipient
    /// @dev Reverts on withdrawing any bonds that don't have an auction contract created by this AMO.
    /// @dev Callable by timelock
    /// @param _fxb Address of bond to withdraw
    /// @param _recipient Address to receive the withdrawn bonds
    /// @param _amount Amount of bonds to withdraw
    function withdrawBonds(address _fxb, address _recipient, uint256 _amount) external {
        _requireSenderIsTimelock();

        if (!isFxbApproved(_fxb)) {
            revert BondNotApproved();
        }

        // bookkeeping
        totalFxbWithdrawn += _amount;
        auctionDetails[fxbToAuction[_fxb]].fxbWithdrawn += _amount;

        IERC20(_fxb).transfer(_recipient, _amount);
    }

    //==============================================================================
    // Setter Functions
    //==============================================================================

    /// @notice Set the `minPriceMin` for a given `TimeToMaturity` within the `timeToMaturityDetails`
    /// @dev Callable by timelock
    /// @dev Reverts if setting a `minPriceMin` less than `globalMinPriceMin`
    /// @param _timeToMaturity `TimeToMaturity` enum
    /// @param _minPriceMin The minimum priceMin to set the for the `TimeToMaturity`
    function setMinPriceMin(TimeToMaturity _timeToMaturity, uint128 _minPriceMin) external {
        _requireSenderIsTimelock();

        // revert if setting a minPriceMin below the global value
        if (_minPriceMin < globalMinPriceMin) {
            revert MinPriceMinBelowGlobalMinPriceMin();
        }

        uint128 oldMinPriceMin = timeToMaturityDetails[_timeToMaturity].minPriceMin;

        // NOTE: cannot pass in a `TimeToMaturity` enum with an index that does not exist
        timeToMaturityDetails[_timeToMaturity].minPriceMin = _minPriceMin;

        emit SetMinPriceMin({
            timeToMaturity: _timeToMaturity,
            oldMinPriceMin: oldMinPriceMin,
            newMinPriceMin: _minPriceMin
        });
    }

    /// @notice Set the `globalMinPriceMin`
    /// @dev Callable by timelock
    /// @param _globalMinPriceMin New value of the `globalMinPriceMin`
    function setGlobalMinPriceMin(uint128 _globalMinPriceMin) external {
        _requireSenderIsTimelock();

        uint128 oldGlobalMinPriceMin = globalMinPriceMin;
        globalMinPriceMin = _globalMinPriceMin;

        emit SetGlobalMinPriceMin({
            oldGlobalMinPriceMin: oldGlobalMinPriceMin,
            newGlobalMinPriceMin: _globalMinPriceMin
        });
    }

    /// @notice Set the cumulative bonds allowed to auction for a given auction contract
    /// @dev Callable by timelock
    /// @dev Reverts on auction contracts not created by the AMO
    /// @param _auction Address of auction contract
    /// @param _fxbAllowedToAuction Cumulative amount of bonds allowed to auction
    function setFxbAllowedToAuction(address _auction, uint256 _fxbAllowedToAuction) public {
        _requireSenderIsTimelock();

        AuctionDetail storage auctionDetail = auctionDetails[_auction];

        if (!isFxbApproved(auctionDetail.fxb)) {
            revert BondNotApproved();
        }

        // bookkeeping
        uint256 oldFxbAllowedToAuction = auctionDetail.fxbAllowedToAuction;
        auctionDetail.fxbAllowedToAuction = _fxbAllowedToAuction;

        emit SetFxbAllowedToAuction({
            auction: _auction,
            oldFxbAllowedToAuction: oldFxbAllowedToAuction,
            newFxbAllowedToAuction: _fxbAllowedToAuction
        });
    }

    //==============================================================================
    // Helpers
    //==============================================================================

    /// @notice Multicall to trigger multiple actions in one contract call
    function multicall(bytes[] calldata _calls) external {
        for (uint256 i = 0; i < _calls.length; i++) {
            (bool s, ) = address(this).delegatecall(_calls[i]);
            if (!s) revert MulticallFailed();
        }
    }

    //==============================================================================
    // Views
    //==============================================================================

    /// @notice View to see if an auction address was created by the AMO
    /// @param _auction Address of auction to check
    /// @return True if created by the AMO, else false
    function isAuction(address _auction) public view returns (bool) {
        return auctionDetails[_auction].fxb != address(0);
    }

    /// @notice View to see if a FXB is approved by timelock for the AMO to auction
    /// @dev Switches to true within `createAuctionContract()`
    /// @param _fxb Address of FXB to check
    /// @return True if FXB is approved by timelock, else false
    function isFxbApproved(address _fxb) public view returns (bool) {
        return (_fxb != address(0) && fxbToAuction[_fxb] != address(0));
    }

    /// @notice View to return the length of the `auctions` array
    /// @return Length of `auctions` array
    function auctionsLength() external view returns (uint256) {
        return auctions.length;
    }

    /// @notice View to return the associated `AuctionDetail` for a given auction
    /// @dev Enables calling `auctionDetails` to return a struct instead of a tuple
    /// @param _auction Address of auction to lookup
    /// @return auctionDetail `AuctionDetail` of the requested auction
    function getAuctionDetails(address _auction) external view returns (AuctionDetail memory auctionDetail) {
        auctionDetail = auctionDetails[_auction];
    }

    /// @notice View to determine the `TimeToMaturity` enum value given a duration `_delta`
    /// @dev Values align to the `timeToMaturityDetails.duration` as defined in the constructor
    /// @param _delta Duration in seconds to calculate the `TimeToMaturity`
    /// @return timeToMaturity `TimeToMaturity` enum for the given `_delta`
    function calculateTimeToMaturity(uint256 _delta) public pure returns (TimeToMaturity timeToMaturity) {
        if (_delta > 365 * 10 days) {
            timeToMaturity = TimeToMaturity.TEN_YEARS;
        } else if (_delta > 365 * 7 days) {
            timeToMaturity = TimeToMaturity.SEVEN_YEARS;
        } else if (_delta > 365 * 5 days) {
            timeToMaturity = TimeToMaturity.FIVE_YEARS;
        } else if (_delta > 365 * 3 days) {
            timeToMaturity = TimeToMaturity.THREE_YEARS;
        } else if (_delta > 365 * 2 days) {
            timeToMaturity = TimeToMaturity.TWO_YEARS;
        } else if (_delta > 365 days) {
            timeToMaturity = TimeToMaturity.ONE_YEAR;
        } else if (_delta > 180 days) {
            timeToMaturity = TimeToMaturity.SIX_MONTHS;
        } else if (_delta > 90 days) {
            timeToMaturity = TimeToMaturity.THREE_MONTHS;
        } else if (_delta > 30 days) {
            timeToMaturity = TimeToMaturity.ONE_MONTH;
        } else {
            timeToMaturity = TimeToMaturity.NOW;
        }
    }

    /// @notice Returns the time-weighted average of minPriceMin of a `_delta` which lies between the two nearest `TimeToMaturity`s
    /// @dev If both `minPriceMin < globalMinPriceMin`, return `globalMinPriceMin`
    /// @dev If only one `minPriceMin > globalMinPriceMin`, return the value
    /// @dev If both `minPriceMin > globalMinPriceMin`, calculate the weighted average
    /// @param _delta Duration in seconds to locate the two nearest `TimeToMaturity`s
    /// @return Calculated `minPriceMin`
    function calculateTimeWeightedMinPriceMin(uint128 _delta) external view returns (uint128) {
        TimeToMaturity timeToMaturity = calculateTimeToMaturity(_delta);
        return _calculateTimeWeightedMinPriceMin({ _delta: _delta, _timeToMaturity: timeToMaturity });
    }

    function _calculateTimeWeightedMinPriceMin(
        uint128 _delta,
        TimeToMaturity _timeToMaturity
    ) internal view returns (uint128) {
        // Get the TimeToMaturity details of the current TimeToMaturity and the closest TimeToMaturity ...
        //   greater than ```_delta``` as ``` _delta > _timeToMaturity ```, therefore _delta is between the two TimeToMaturitys
        TimeToMaturityDetail memory lower = timeToMaturityDetails[_timeToMaturity];
        TimeToMaturityDetail memory upper;
        if (_timeToMaturity != TimeToMaturity.TEN_YEARS) {
            // keep upper set to 0 if ten years as there is no additional TimeToMaturity
            upper = timeToMaturityDetails[TimeToMaturity(uint8(_timeToMaturity) + 1)];
        }

        // gas
        uint128 globalMinPriceMin_ = globalMinPriceMin;

        // return global minPriceMin if both minPriceMins are less or equal to global
        if (lower.minPriceMin <= globalMinPriceMin_ && upper.minPriceMin <= globalMinPriceMin_) {
            return globalMinPriceMin_;
        }

        // If only one minPriceMin >= globalMinPriceMin, do not average and take the greater-than value
        if (upper.minPriceMin < globalMinPriceMin_ && lower.minPriceMin >= globalMinPriceMin_) {
            return lower.minPriceMin;
        } else if (lower.minPriceMin < globalMinPriceMin_ && upper.minPriceMin >= globalMinPriceMin_) {
            return upper.minPriceMin;
        }

        // THEN: both lower.minPriceMin && upper.minPriceMin > globalMinPriceMin, calculate time weighted average

        // Calculate how much percent have we moved from the bottom duration to the top, with 10**18 precision
        // ie: lower = 10 days, upper = 40 days, delta = 20 days, pct = 33% [ (20 - 10) / (40 - 10) ]
        uint256 pct = (1e18 * (_delta - lower.duration)) / (upper.duration - lower.duration);

        // Now apply that weighting to the lower and upper minPriceMin
        // ie. lower gets 66% of the weight, upper gets 33%
        uint256 minPriceMinLowerWeighted = (1e18 - pct) * lower.minPriceMin;
        uint256 minPriceMinUpperWeighted = pct * upper.minPriceMin;

        // Now that we have both weights, we add them up for the result and remove the precision
        return uint128((minPriceMinLowerWeighted + minPriceMinUpperWeighted) / 1e18);
    }

    //==============================================================================
    // Errors
    //==============================================================================
    /// @notice Revert in `createAuctionContract()` when attempting to create a second auction contract with the same bond address
    error AuctionAlreadyCreated();

    /// @notice Revert in `startAuction()` if the bond listed for auction has already reached maturity
    error BondAlreadyRedeemable();

    /// @notice Revert in all timelock/operator methods if the bond does not have an associated auction contract created by the AMO
    error BondNotApproved();

    /// @notice Revert in `startAuction()` if the auction end time is before the bond maturity
    error BondExpiresBeforeAuctionEnd();

    /// @notice Revert in `startAuction()` if `_params.minPriceMin` is below the time-weighted minPriceMin
    error PriceMinTooLow();

    /// @notice Revert in `setMinPriceMin()` if `_minPriceMin < globalMinPriceMin`
    error MinPriceMinBelowGlobalMinPriceMin();

    /// @notice Revert in `multicall()` if one of the calls does not succeed
    error MulticallFailed();

    /// @notice Revert in `createAuctionContract()` if the address of bond to create an auction for was not created by `iFxbFactory`
    error NotLegitimateBond();

    /// @notice Revert in all methods only callable by the timelock/operator
    error NotOperatorOrTimelock();

    /// @notice Revert in `startAuction()` if the cumulative amount of bonds listed for auction exceeds `auctionDetail.fxbAllowedToAuction`
    error TooManyBondsAuctioned();

    /// @notice Revert in `mintBonds()` if the cumulative amount of bonds minted exceeds `auctionDetail.fxbAllowedToAuction`
    error TooManyBondsMinted();

    //==============================================================================
    // Events
    //==============================================================================

    /// @notice Emitted in `createAuctionContract()`
    /// @param fxb Address of bond to create the auction contract
    /// @param auction Address of newly created auction contract
    event CreateAuctionContract(address indexed fxb, address indexed auction);

    /// @notice Emitted in `setFxbAllowedToAuction()`
    /// @param auction Address of auction to set `auctiondetail.fxbAllowedToAuction`
    /// @param oldFxbAllowedToAuction Previous value of `auctionDetail.fxbAllowedToAuction`
    /// @param newFxbAllowedToAuction New value of `auctionDetail.fxbAllowedToAuction`
    event SetFxbAllowedToAuction(
        address indexed auction,
        uint256 oldFxbAllowedToAuction,
        uint256 newFxbAllowedToAuction
    );

    /// @notice Emitted in `setGlobalMinPriceMin()`
    /// @param oldGlobalMinPriceMin Previous value of `globalMinPriceMin`
    /// @param newGlobalMinPriceMin New value of `globalMinPriceMin`
    event SetGlobalMinPriceMin(uint128 oldGlobalMinPriceMin, uint128 newGlobalMinPriceMin);

    /// @notice Emitted in `setMinPriceMin()`
    /// @param timeToMaturity A chosen `TimeToMaturity` enum value
    /// @param oldMinPriceMin Previous value of `timeToMaturityDetails.minPriceMin`
    /// @param newMinPriceMin new value of `timeToMaturityDetails.minPriceMin`
    event SetMinPriceMin(TimeToMaturity timeToMaturity, uint128 oldMinPriceMin, uint128 newMinPriceMin);

    /// @notice Emitted in `startAuction()`
    /// @param from Address to call `startAuction()`
    /// @param auction Address of auction contract
    /// @param fxbMinted Amount of bonds minted for the auction to start
    /// @param fxbAuctioned Amount of bonds listed for auction
    /// @param totalFxbAuctioned_ Cumulative amount of all bonds listed for auction
    event StartAuction(
        address indexed from,
        address indexed auction,
        uint256 fxbMinted,
        uint256 fxbAuctioned,
        uint256 totalFxbAuctioned_
    );
}
