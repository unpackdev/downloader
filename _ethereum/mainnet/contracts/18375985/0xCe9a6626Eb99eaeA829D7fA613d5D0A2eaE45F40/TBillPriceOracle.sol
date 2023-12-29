// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./AccessControl.sol";

/**
 * @title TBillPriceOracle
 * @notice This contract serves as an oracle for TBill's price. It allows certain operators to
 * update the price with restrictions on how much it can deviate from the last known price.
 *
 * @dev The contract is designed to be managed by a DAO and has various safety and administrative
 * features. The price update happens once a day and is limited by a certain percentage deviation.
 */
contract TBillPriceOracle is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct RoundData {
        uint80 roundId;
        uint256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    uint8 private _decimals;

    uint80 private _latestRound;
    uint256 private _closeNavPrice;

    uint256 public constant DEVIATION_FACTOR = 10000;
    uint256 private _maxPriceDeviation;
    mapping(uint80 => RoundData) private _roundData;

    event UpdatePrice(uint256 oldPrice, uint256 newPrice);
    event UpdateCloseNavPrice(uint256 oldPrice, uint256 newPrice);
    event UpdateCloseNavPriceManually(uint256 oldPrice, uint256 newPrice);
    event RoundUpdated(uint80 indexed roundId);
    event UpdateMaxPriceDeviation(uint256 oldDeviation, uint256 newDeviation);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    modifier onlyAdminOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(OPERATOR_ROLE, msg.sender),
            "Caller is not an admin or operator"
        );
        _;
    }

    /**
     * @notice Initializes the TBillPriceOracle contract with essential configuration values.
     * @param decimals_ Decimals used for the oracle price.
     * @param maxPriceDeviation_ Maximum allowed deviation for the price update.
     * @param initPrice_ Initial price for TBill.
     * @param closeNavPrice_ The last close net asset value price.
     * @param operator_ Address of the operator who can update the price.
     * @param admin_ Address of the administrator who can manage operators.
     */
    constructor(
        uint8 decimals_,
        uint256 maxPriceDeviation_,
        uint256 initPrice_,
        uint closeNavPrice_,
        address operator_,
        address admin_
    ) {
        require(admin_ != address(0), "invalid admin address");
        _decimals = decimals_;
        _maxPriceDeviation = maxPriceDeviation_;
        _latestRound++;
        RoundData storage round = _roundData[_latestRound];
        round.roundId = _latestRound;
        round.answer = initPrice_;
        round.startedAt = block.timestamp;
        round.updatedAt = block.timestamp;
        round.answeredInRound = _latestRound;
        _closeNavPrice = closeNavPrice_;
        _grantRole(OPERATOR_ROLE, operator_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * @return The number of decimals used in the oracle price.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return The ID of the latest round of price data.
     */
    function latestRound() public view returns (uint80) {
        return _latestRound;
    }

    /**
     * @return All data related to the latest round.
     */
    function latestRoundData()
        public
        view
        returns (uint80, uint256, uint256, uint256, uint80)
    {
        RoundData storage round = _roundData[_latestRound];
        return (
            round.roundId,
            round.answer,
            round.startedAt,
            round.updatedAt,
            round.answeredInRound
        );
    }

    /**
     * @return The latest price from the oracle.
     */
    function latestAnswer() public view returns (uint256) {
        return _roundData[_latestRound].answer;
    }

    /**
     * @return The last known close net asset value price.
     */
    function closeNavPrice() public view returns (uint256) {
        return _closeNavPrice;
    }

    /**
     * @return The maximum deviation factor for updating the price.
     */
    function maxPriceDeviation() public view returns (uint256) {
        return _maxPriceDeviation;
    }

    /**
     * @notice Updates the maximum deviation factor.
     * @param newDeviation The new deviation value.
     */
    function updateMaxPriceDeviation(uint256 newDeviation) public onlyAdmin {
        emit UpdateMaxPriceDeviation(_maxPriceDeviation, newDeviation);
        _maxPriceDeviation = newDeviation;
    }

    /**
     * @notice Updates the price with certain checks on the deviation.
     * @param price The new price to be set.
     */
    function updatePrice(uint256 price) public onlyAdminOrOperator {
        require(_isValidPriceUpdate(price), "Price update deviates too much");
        uint256 oldAnswer = _roundData[_latestRound].answer;
        emit UpdatePrice(oldAnswer, price);
        _latestRound++;
        RoundData storage round = _roundData[_latestRound];
        round.roundId = _latestRound;
        round.answer = price;
        round.startedAt = block.timestamp;
        round.updatedAt = block.timestamp;
        round.answeredInRound = _latestRound;
        emit RoundUpdated(_latestRound);
    }

    /**
     * @notice Updates the close net asset value price with checks on deviation.
     * @param price The new close NAV price to be set.
     */
    function updateCloseNavPrice(uint256 price) public onlyAdminOrOperator {
        emit UpdateCloseNavPrice(_closeNavPrice, price);
        require(
            _isValidPriceUpdate(price),
            "CloseNavPrice update deviates too much"
        );
        _closeNavPrice = price;
    }

    /**
     * @notice Manually updates the close net asset value price without any checks.
     * @param price The new close NAV price to be set.
     */
    function updateCloseNavPriceManually(uint256 price) public onlyAdmin {
        emit UpdateCloseNavPriceManually(_closeNavPrice, price);
        _closeNavPrice = price;
    }

    /**
     * @notice Checks if the given price is a valid update.
     * @param newPrice The price to be checked.
     * @return true if the price update is valid, otherwise false.
     */
    function isValidPriceUpdate(uint256 newPrice) public view returns (bool) {
        return _isValidPriceUpdate(newPrice);
    }

    /**
     * @dev Internal function to check if the given price update is valid.
     * @param newPrice The price to be checked.
     * @return true if the price update is valid, otherwise false.
     */
    function _isValidPriceUpdate(uint256 newPrice) private view returns (bool) {
        uint256 numerator = _closeNavPrice > newPrice
            ? _closeNavPrice - newPrice
            : newPrice - _closeNavPrice;
        uint256 denominator = (_closeNavPrice + newPrice) / 2;
        uint256 priceDeviation = (numerator * 10 ** _decimals) / denominator;
        uint256 _maxPriceDeviationReal = (_maxPriceDeviation *
            10 ** _decimals) / DEVIATION_FACTOR;
        return priceDeviation <= _maxPriceDeviationReal;
    }
}
