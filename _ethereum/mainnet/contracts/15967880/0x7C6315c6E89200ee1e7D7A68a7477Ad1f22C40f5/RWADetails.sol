// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./AccessControlManager.sol";
import "./CurrencyOracle.sol";

/// @title Real World Asset Details
/// @notice This contract stores the real world assets for the protocol

contract RWADetails {
    /// @dev All assets are stored with 4 decimal shift unless specified
    uint128 public constant MO_DECIMALS = 10**4;
    uint256 public constant RWA_DECIMALS = 10**12;

    event RWAUnitCreated(uint256 indexed rWAUnitId);
    event RWAUnitAddedUnitsForTokenId(
        uint256 indexed rWAUnitId,
        uint16 indexed tokenId,
        uint64 units
    );
    event RWAUnitRedeemedUnitsForTokenId(
        uint256 indexed rWAUnitId,
        uint16 indexed tokenId,
        uint64 units
    );
    event RWAUnitDetailsUpdated(
        uint256 indexed rWAUnitId,
        uint128 indexed unitPrice,
        uint32 indexed priceUpdateDate,
        string portfolioDetailsLink
    );
    event RWAUnitSchemeDocumentLinkUpdated(
        uint256 indexed rWAUnitId,
        string schemeDocumentLink
    );
    event CurrencyOracleAddressSet(address indexed currencyOracleAddress);
    event AccessControlManagerSet(address indexed accessControlAddress);
    event SeniorDefaultUpdated(
        uint256 indexed rWAUnitId,
        bool indexed defaultFlag
    );
    event AutoCalcFlagUpdated(
        uint256 indexed rWAUnitId,
        bool indexed autoCalcFlag
    );
    event RWAUnitValueUpdated(
        uint256 indexed rWAUnitId,
        uint32 indexed priceUpdateDate,
        uint128 indexed unitPrice
    );
    event RWAUnitPayoutUpdated(
        uint256 indexed rWAUnitId,
        uint128 indexed payoutAmount,
        uint128 indexed unitPrice
    );

    /** @notice This variable (struct RWAUnit) stores details of real world asset (called RWAUnit).
     *  unit price, portfolio details link and price update date are refreshed regularly
     *  The units mapping stores how many real world asset units are held by MoH tokenId.
     *  apy stores daily compounding rate, shifted by 10 decimals.
     *  defaultFlag is used to indicate asset default.
     *  if autoCalcFlag is set to true then asset value is calculated using apy and time elapsed.
     *  apy is mandatory if autoCalculate is set to true.
     */
    /** @dev
     *  uint16 is sufficient for number of MoH tokens since its extremely unlikely to exceed 64k types of MoH tokens
     *  unint64 can hold 1600 trillion units of real world asset with 4 decimal places.
     *  uint32 can only hold 800k units of real world assets with 4 decimal places which might be insufficient
     *  (if each real world asset is $100, that is only $80m)
     *  since price is not 12 decimals shifted, increasing it to uint128
     */

    struct RWAUnit {
        bool autoCalcFlag;
        bool defaultFlag;
        uint16 tokenId;
        uint32 startDate;
        uint32 endDate;
        uint32 priceUpdateDate;
        uint64 apy; // RWA_DECIMALS shifted
        uint64 apyLeapYear; // RWA_DECIMALS shifted
        uint64 units;
        uint128 notionalValue; // RWA_DECIMALS shifted
        uint128 unitPrice; // RWA_DECIMALS shifted
        bytes32 fiatCurrency;
    }

    /** @notice This variable (struct RWAUnitDetail) stores additional details of real world asset (called RWAUnit).
     *  name is only updatable during creation.
     *  schemeDocumentLink is mostly static.
     *  portfolioDetailsLink is refreshed regularly
     */
    struct RWAUnitDetail {
        string name;
        string schemeDocumentLink;
        string portfolioDetailsLink;
    }

    /// @dev Currency Oracle Address contract associated with RWA unit
    address public currencyOracleAddress;

    /// @dev Implements RWA manager and whitelist access
    address public accessControlManagerAddress;

    /// @dev unique identifier for the rwa unit
    uint256 public rWAUnitId = 1;

    /// @dev used to determine number of days in asset value calculation
    bool public leapYear;

    /// @dev mapping between the id and the struct
    mapping(uint256 => RWAUnit) public rWAUnits;

    /// @dev mapping between unit id and additional details
    mapping(uint256 => RWAUnitDetail) public rWAUnitDetails;

    /// @dev mapping of tokenId to rWAUnitIds . Used for calculating asset value for a tokenId.
    mapping(uint256 => uint256[]) public tokenIdToRWAUnitId;

    constructor(address _accessControlManager) {
        accessControlManagerAddress = _accessControlManager;
        emit AccessControlManagerSet(_accessControlManager);
    }

    /// @notice Access modifier to restrict access only to owner

    modifier onlyOwner() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isOwner(msg.sender), "NO");
        _;
    }

    /// @dev Access modifier to restrict access only to RWA manager addresses

    modifier onlyRWAManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isRWAManager(msg.sender), "NR");
        _;
    }

    /// @dev Access modifier to restrict access only to RWA manager addresses

    modifier onlyCronManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isCronManager(msg.sender), "NC");
        _;
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _accessControlManagerAddress Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(
        address _accessControlManagerAddress
    ) external onlyOwner {
        accessControlManagerAddress = _accessControlManagerAddress;
        emit AccessControlManagerSet(_accessControlManagerAddress);
    }

    /// @notice Setter for leapYear
    /// @param _leapYear whether current period is in a leap year

    function setLeapYear(bool _leapYear) external onlyRWAManager {
        leapYear = _leapYear;
    }

    /** @notice function createRWAUnit allows creation of a new Real World Asset type (RWA unit)
     *  It takes the name and scheme document as inputs along with initial price and date
     *  Checks on inputs include ensuring name is entered, link is provided for document and initial price is entered
     */
    /// @dev Explain to a developer any extra details
    /// @param _name is the name of the RWA scheme
    /// @param _schemeDocumentLink contains the link for the RWA scheme document
    /// @param _portfolioDetailsLink contains the link for the RWA portfolio details document
    /// @param _fiatCurrency  fiat currency for the unit
    /// @param _notionalValue initial value of a single RWA unit
    /// @param _autoCalcFlag specifies whether principal should be auto calculated. Only applicable for senior unit type
    /// @param _units number of units.
    /// @param _startDate specifies the start date for the rwa unit, mandatory input as this is the start for price calculation.
    /// @param _endDate specifies the end date for the rwa unit, place holder value, not used in any calculations.
    /// @param _tokenId specifies the mo token this unit is linked to. mandatory input as this cannot be set later for the unit.
    /// @param _apy daily compounding interest for the unit, used to update price when auto calculation is enabled for the unit.
    /// @param _apyLeapYear daily compounding interest for the unit during leap year

    function createRWAUnit(
        string memory _name,
        string memory _schemeDocumentLink,
        string memory _portfolioDetailsLink,
        bytes32 _fiatCurrency,
        uint128 _notionalValue,
        bool _autoCalcFlag,
        uint64 _units,
        uint32 _startDate,
        uint32 _endDate,
        uint16 _tokenId,
        uint64 _apy,
        uint64 _apyLeapYear
    ) external onlyRWAManager {
        require(
            (bytes(_name).length > 0) &&
                _tokenId > 0 &&
                _fiatCurrency != "" &&
                _notionalValue > 0 &&
                _startDate > 0,
            "BD"
        );
        if (_autoCalcFlag) {
            require(_apy > 0 && _apyLeapYear > 0, "WI");
        }

        uint256 id = rWAUnitId++;

        rWAUnits[id].fiatCurrency = _fiatCurrency;
        rWAUnits[id].unitPrice = _notionalValue;
        rWAUnits[id].tokenId = _tokenId;
        rWAUnits[id].autoCalcFlag = _autoCalcFlag;
        rWAUnits[id].startDate = _startDate;
        rWAUnits[id].priceUpdateDate = _startDate;
        rWAUnits[id].endDate = _endDate;
        rWAUnits[id].notionalValue = _notionalValue;
        rWAUnits[id].units = _units;
        rWAUnits[id].apy = _apy;
        rWAUnits[id].apyLeapYear = _apyLeapYear;

        tokenIdToRWAUnitId[_tokenId].push(id);

        rWAUnitDetails[id] = RWAUnitDetail({
            name: _name,
            schemeDocumentLink: _schemeDocumentLink,
            portfolioDetailsLink: _portfolioDetailsLink
        });

        emit RWAUnitCreated(id);
    }

    /** @notice Function allows adding RWA units to a particular RWA unit ID.
     */
    /** @dev Function emits the RWAUnitAddedUnitsForTokenId event which represents RWA id, MoH token id and number of units.
     *      It is read as given number of tokens of RWA id are added to MoH pool represnted by MoH token id
     *  @dev tokenIds stores the MoH token IDs holding units of this RWA.
     *      This mapping is specific to the RWA scheme represented by the struct
     */
    /// @param _id contains the id of the RWA unit being added
    /// @param _units contains the number of RWA units added to the MoH token

    function addRWAUnits(uint256 _id, uint64 _units) external onlyRWAManager {
        RWAUnit storage rWAUnit = rWAUnits[_id];
        rWAUnit.units += _units;
        emit RWAUnitAddedUnitsForTokenId(_id, rWAUnit.tokenId, _units);
    }

    /** @notice Function allows RWA manager to update redemption of RWA units. Redemption of RWA units leads to
     *  an increase in cash / stablecoin balances and reduction in RWA units held.
     *  The cash / stablecoin balances are not handled in this function
     */
    /** @dev Function emits the RWAUnitRedeemedUnitsForTokenId event which represents RWA id, MoH token id and number of units.
     *      It is read as given number of tokens of RWA id are subtracted from the MoH pool represnted by MoH token id
     */
    /// @param _id contains the id of the RWA unit being redeemed
    /// @param _units contains the number of RWA units redeemed from the MoH token

    function redeemRWAUnits(uint256 _id, uint64 _units)
        external
        onlyRWAManager
    {
        RWAUnit storage rWAUnit = rWAUnits[_id];
        require(rWAUnit.units >= _units, "ECA1");
        rWAUnit.units -= _units;
        emit RWAUnitRedeemedUnitsForTokenId(_id, rWAUnit.tokenId, _units);
    }

    /** @notice Function allows RWA Manager to update the RWA scheme documents which provides the parameter of the RWA scheme such as fees,
     *  how the scheme is run etc. This is not expected to be updated frequently
     */
    /// @dev Function emits RWAUnitSchemeDocumentLinkUpdated event which provides id of RWA scheme update and the updated scheme document link
    /// @param _schemeDocumentLink stores the link to the RWA scheme document
    /// @param _id contains the id of the RWA being updated

    function updateRWAUnitSchemeDocumentLink(
        uint256 _id,
        string memory _schemeDocumentLink
    ) external onlyRWAManager {
        require((bytes(_schemeDocumentLink)).length > 0, "ECC2");
        rWAUnitDetails[_id].schemeDocumentLink = _schemeDocumentLink;
        emit RWAUnitSchemeDocumentLinkUpdated(_id, _schemeDocumentLink);
    }

    /** @notice Function allows RWA Manager to update the details of the RWA portfolio.
     *  Changes in the portfolio holdings and / or price of holdings are updated via portfolio details link and
     *  the updated price of RWA is updated in _unitPrice field. This is expected to be updated regulatory
     */
    /// @dev Function emits RWAUnitDetailsUpdated event which provides id of RWA updated, unit price updated and price update date
    /// @param _id Refers to id of the RWA being updated
    /// @param _unitPrice stores the price of a single RWA unit
    /// @param _priceUpdateDate stores the last date on which the RWA unit price was updated by RWA Manager
    /// @param _portfolioDetailsLink stores the link to the file containing details of the RWA portfolio and unit price

    function updateRWAUnitDetails(
        uint256 _id,
        string memory _portfolioDetailsLink,
        uint128 _unitPrice,
        uint32 _priceUpdateDate
    ) external onlyRWAManager {
        require((bytes(_portfolioDetailsLink)).length > 0, "ECC2");

        RWAUnit storage rWAUnit = rWAUnits[_id];
        rWAUnit.unitPrice = _unitPrice;
        rWAUnitDetails[_id].portfolioDetailsLink = _portfolioDetailsLink;
        rWAUnit.priceUpdateDate = _priceUpdateDate;
        emit RWAUnitDetailsUpdated(
            _id,
            _unitPrice,
            _priceUpdateDate,
            _portfolioDetailsLink
        );
    }

    /// @notice Allows setting currencyOracleAddress
    /// @param _currencyOracleAddress address of the currency oracle

    function setCurrencyOracleAddress(address _currencyOracleAddress)
        external
        onlyOwner
    {
        currencyOracleAddress = _currencyOracleAddress;
        emit CurrencyOracleAddressSet(currencyOracleAddress);
    }

    /** @notice Function allows RWA Manager to update defaultFlag for a linked senior unit.
     */
    /// @dev Function emits SeniorDefaultUpdated event which provides value of defaultFlag for the unit id.
    /// @param _id Refers to id of the RWA being updated
    /// @param _defaultFlag boolean value to be set.

    function setSeniorDefault(uint256 _id, bool _defaultFlag)
        external
        onlyRWAManager
    {
        rWAUnits[_id].defaultFlag = _defaultFlag;
        emit SeniorDefaultUpdated(_id, _defaultFlag);
    }

    /** @notice Function allows RWA Manager to update autoCalcFlag for the RWA unit.
     * If value of autoCalcFlag is false then unitPrice and priceUpdateDate are mandatory.
     * If value of autoCalcFlag is true then apy and apyLeapYear can only be set if
     * values are not set for these attributes.
     */
    /// @dev Function emits AutoCalcFlagUpdated event which provides id of RWA updated and autoCalcFlag value set.
    /// @param _id Refers to id of the RWA being updated
    /// @param _autoCalcFlag Refers to autoCalcFlag of the RWA being updated
    /// @param _unitPrice Refers to unitPrice of the RWA being updated
    /// @param _priceUpdateDate Refers to priceUpdateDate of the RWA being updated
    /// @param _apy Refers to daily compounding interest of the RWA being updated

    function updateAutoCalc(
        uint256 _id,
        bool _autoCalcFlag,
        uint128 _unitPrice,
        uint32 _priceUpdateDate,
        uint64 _apy,
        uint64 _apyLeapYear
    ) external onlyRWAManager {
        require(
            _autoCalcFlag
                ? ((rWAUnits[_id].apy > 0 && rWAUnits[_id].apyLeapYear > 0) ||
                    (_apy > 0 && _apyLeapYear > 0))
                : (_unitPrice > 0 && _priceUpdateDate > 0),
            "WI"
        );

        rWAUnits[_id].autoCalcFlag = _autoCalcFlag;
        if (_autoCalcFlag) {
            if (rWAUnits[_id].apy == 0) {
                rWAUnits[_id].apy = _apy;
                rWAUnits[_id].apyLeapYear = _apyLeapYear;
            }
        } else {
            rWAUnits[_id].unitPrice = _unitPrice;
            rWAUnits[_id].priceUpdateDate = _priceUpdateDate;
        }
        emit AutoCalcFlagUpdated(_id, _autoCalcFlag);
    }

    /** @notice Function returns whether token redemption is allowed for the RWA unit id.
     *  Returns true only if units have been redeemed or outstanding amount is 0 and defaultFlag is false
     */
    /// @param _id Refers to id of the RWA unit
    /// @return redemptionAllowed Indicates whether the RWA unit can be redeemed.

    function isRedemptionAllowed(uint256 _id)
        external
        view
        returns (bool redemptionAllowed)
    {
        redemptionAllowed =
            (rWAUnits[_id].units == 0 || rWAUnits[_id].unitPrice == 0) &&
            !rWAUnits[_id].defaultFlag;
    }

    /** @notice Function is used to udpate the rwa unit value if auto calculation is enabled for the RWA unit id.
     *  apy is used to calculate and the udpate the latest unit price.
     */
    /// @param _id Refers to id of the RWA unit
    /// @param _date Date for which rwa asset value should be updated to.

    function updateRWAUnitValue(uint16 _id, uint32 _date)
        public
        onlyCronManager
    {
        RWAUnit storage rWAUnit = rWAUnits[_id];

        require(
            _date >= rWAUnit.priceUpdateDate &&
                rWAUnit.autoCalcFlag &&
                (uint32(block.timestamp) > _date),
            "IT"
        );

        uint256 calculatedAmount = uint256(rWAUnit.unitPrice);

        uint256 daysPassed = uint256(
            (_date - rWAUnit.priceUpdateDate) / 1 days
        );

        uint256 loops = daysPassed / 4; // looping to prevent overflow
        uint256 remainder = daysPassed % 4;

        uint256 interest = (RWA_DECIMALS +
            (leapYear ? rWAUnit.apyLeapYear : rWAUnit.apy))**4;

        for (uint256 i = 0; i < loops; i = i + 1) {
            calculatedAmount =
                (calculatedAmount * interest) /
                (RWA_DECIMALS**4);
        }

        if (remainder > 0) {
            interest =
                (RWA_DECIMALS +
                    (leapYear ? rWAUnit.apyLeapYear : rWAUnit.apy)) **
                    remainder;
            calculatedAmount =
                (calculatedAmount * interest) /
                (RWA_DECIMALS**remainder);
        }

        rWAUnit.priceUpdateDate = _date;
        rWAUnit.unitPrice = uint128(calculatedAmount);

        emit RWAUnitValueUpdated(_id, _date, rWAUnit.unitPrice);
    }

    /** @notice Function is used to register payout for the RWA unit id.
     *  RWA value is update to the date specified and then payout is subtracted to get latest price.
     */
    /// @param _id Refers to id of the RWA unit
    /// @param _date Date for which rwa asset value should be updated to.
    /// @param _payoutAmount payout amount to be subtracted from the unit price.

    function udpatePayout(
        uint16 _id,
        uint32 _date,
        uint128 _payoutAmount
    ) external onlyCronManager {
        RWAUnit storage rWAUnit = rWAUnits[_id];

        updateRWAUnitValue(_id, _date);
        if (rWAUnit.unitPrice <= _payoutAmount) {
            rWAUnit.unitPrice = 0;
        } else {
            rWAUnit.unitPrice = rWAUnit.unitPrice - _payoutAmount;
        }
        emit RWAUnitPayoutUpdated(_id, _payoutAmount, rWAUnit.unitPrice);
    }

    /** @notice Function returns the value of RWA units held by a given MoH token id.
     *  This is calculated as number of RWA units against the MoH token multiplied by unit price of an RWA token.
     */
    /// @dev Explain to a developer any extra details
    /// @param _tokenId is the MoH token Id for which value of RWA units is being calculated
    /// @param _inCurrency currency in which assetValue is to be returned
    /// @return assetValue real world asset value for the token as per the date in the requested currency.

    function getRWAValueByTokenId(uint16 _tokenId, bytes32 _inCurrency)
        external
        view
        returns (uint128 assetValue)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);

        uint256[] memory tokenUnitIds = tokenIdToRWAUnitId[_tokenId];

        for (uint256 i = 0; i < tokenUnitIds.length; i++) {
            uint256 id = tokenUnitIds[i];
            RWAUnit storage rWAUnit = rWAUnits[id];

            if (rWAUnit.units == 0 || rWAUnit.unitPrice == 0) continue;

            uint128 calculatedAmount = rWAUnit.unitPrice * rWAUnit.units;

            // convert if necessary and add to assetValue
            if (rWAUnit.fiatCurrency == _inCurrency) {
                assetValue += calculatedAmount;
            } else {
                (uint64 convRate, uint8 decimalsVal) = currencyOracle
                    .getFeedLatestPriceAndDecimals(
                        rWAUnit.fiatCurrency,
                        _inCurrency
                    );
                assetValue += ((calculatedAmount * convRate) /
                    uint128(10**decimalsVal));
            }
        }
        // returning 4 decimal shifted asset value
        assetValue = assetValue / uint128(RWA_DECIMALS);
    }

    /** @notice Function returns RWA units for the token Id
     */
    /// @param _tokenId Refers to token id
    /// @return rWAUnitsByTokenId returns array of RWA Unit IDs associated to tokenId

    function getRWAUnitsForTokenId(uint256 _tokenId)
        external
        view
        returns (uint256[] memory rWAUnitsByTokenId)
    {
        rWAUnitsByTokenId = tokenIdToRWAUnitId[_tokenId];
    }
}
