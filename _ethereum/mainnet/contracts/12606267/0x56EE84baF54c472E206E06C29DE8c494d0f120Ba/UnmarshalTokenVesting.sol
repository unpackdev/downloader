// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
// import "./console.sol";

contract UnmarshalTokenVesting is Ownable {
    using SafeMath for uint256;
    using BokkyPooBahsDateTimeLibrary for uint256;
    using SafeERC20 for IERC20;

    event DistributionAdded(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    enum DistributionType { STAKING, ECOSYSTEM, MARKETING, RESERVES, TEAM }

    uint256 private _initialTimestamp;
    IERC20 private _marshToken;

    struct Distribution {
        address beneficiary;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        DistributionType distributionType;
    }

    mapping(DistributionType => Distribution) public distributionInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;

    uint256 constant _SCALING_FACTOR = 10**18; // decimals

    uint256[] ecosystemVesting = [
        10000000000000000000,
        12500000000000000000,
        15000000000000000000,
        17500000000000000000,
        20000000000000000000,
        22500000000000000000,
        25000000000000000000,
        27500000000000000000,
        30000000000000000000,
        32500000000000000000,
        35000000000000000000,
        37500000000000000000,
        40000000000000000000,
        42500000000000000000,
        45000000000000000000,
        47500000000000000000,
        50000000000000000000,
        52500000000000000000,
        55000000000000000000,
        57500000000000000000,
        60000000000000000000,
        62500000000000000000,
        65000000000000000000,
        67500000000000000000,
        70000000000000000000,
        72500000000000000000,
        75000000000000000000,
        77500000000000000000,
        80000000000000000000,
        82500000000000000000,
        85000000000000000000,
        87500000000000000000,
        90000000000000000000,
        92500000000000000000,
        95000000000000000000,
        97500000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000
    ];

    uint256[] marketingReserveVesting = [
        5000000000000000000,
        8958333333000000000,
        12916666666000000000,
        16874999999000000000,
        20833333332000000000,
        24791666665000000000,
        28749999998000000000,
        32708333331000000000,
        36666666664000000000,
        40624999997000000000,
        44583333330000000000,
        48541666663000000000,
        52499999996000000000,
        56458333329000000000,
        60416666662000000000,
        64374999995000000000,
        68333333328000000000,
        72291666661000000000,
        76249999994000000000,
        80208333327000000000,
        84166666660000000000,
        88124999993000000000,
        92083333326000000000,
        96041666659000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000
    ];

    /// @dev Checks that the contract is initialized.
    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    /// @dev Checks that the contract is initialized.
    modifier notInitialized() {
        require(!isInitialized, "initialized");
        _;
    }

    constructor(
        address _token,
        address _treasury
    ) {
        require(address(_token) != address(0x0), "Marsh token address is not valid");
        _marshToken = IERC20(_token);

        _addDistribution(
            _treasury,
            DistributionType.STAKING,
            20000000 * _SCALING_FACTOR,
            1000000 * _SCALING_FACTOR
        );
        _addDistribution(_treasury, DistributionType.ECOSYSTEM, 24000000 * _SCALING_FACTOR, 2400000 * _SCALING_FACTOR);
        _addDistribution(_treasury, DistributionType.MARKETING, 6800000 * _SCALING_FACTOR, 340000 * _SCALING_FACTOR);
        _addDistribution(_treasury, DistributionType.RESERVES, 10000000 * _SCALING_FACTOR, 500000 * _SCALING_FACTOR);
        _addDistribution(_treasury, DistributionType.TEAM, 20000000 * _SCALING_FACTOR, 0);
    }

    /// @dev Returns initial timestamp
    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev Adds Distribution. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _beneficiary The address of distribution.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function _addDistribution(
        address _beneficiary,
        DistributionType _distributionType,
        uint256 _tokensAllotment,
        uint256 _withdrawnTokens
    ) internal {
        require(_beneficiary != address(0), "Invalid address");
        Distribution storage distribution = distributionInfo[_distributionType];
        distribution.beneficiary = _beneficiary;
        distribution.withdrawnTokens = _withdrawnTokens;
        distribution.tokensAllotment = _tokensAllotment;
        distribution.distributionType = _distributionType;

        emit DistributionAdded(_beneficiary, _msgSender(), _tokensAllotment);
    }

    function withdrawTokens(uint256 _distributionType) external onlyOwner() initialized() {
        Distribution storage distribution = distributionInfo[DistributionType(_distributionType)];

        uint256 tokensAvailable = withdrawableTokens(DistributionType(_distributionType));

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        distribution.withdrawnTokens = distribution.withdrawnTokens.add(tokensAvailable);
        _marshToken.safeTransfer(distribution.beneficiary, tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp) external onlyOwner() notInitialized() {
        isInitialized = true;
        _initialTimestamp = _timestamp;
    }

    function withdrawableTokens(DistributionType distributionType) public view returns (uint256 tokens) {
        Distribution storage distribution = distributionInfo[distributionType];
        uint256 availablePercentage = _calculateAvailablePercentage(distributionType);
        // console.log("Available Percentage: %s", availablePercentage);
        uint256 noOfTokens = _calculatePercentage(distribution.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(distribution.withdrawnTokens);

        // console.log("Withdrawable Tokens: %s",  tokensAvailable);
        return tokensAvailable;
    }

    function _calculatePercentage(uint256 _amount, uint256 _percentage) private pure returns (uint256 percentage) {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage(DistributionType distributionType)
        private
        view
        returns (uint256 _availablePercentage)
    {
        uint256 currentTimeStamp = block.timestamp;
        uint256 noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(_initialTimestamp, currentTimeStamp);
        uint256 noOfMonths = _daysToMonths(noOfDays);

        if (currentTimeStamp > _initialTimestamp) {
            if (distributionType == DistributionType.ECOSYSTEM) {
                return noOfMonths > 50 ? uint256(100).mul(1e18) : ecosystemVesting[noOfMonths];
            } else if (
                distributionType == DistributionType.MARKETING ||
                distributionType == DistributionType.RESERVES ||
                distributionType == DistributionType.STAKING
            ) {
                return noOfMonths > 38 ? uint256(100).mul(1e18) : marketingReserveVesting[noOfMonths];
            } else if (distributionType == DistributionType.TEAM) {
                uint256 _remainingDistroPercentage = 85;
                uint256 _noOfRemainingDays = 420;
                uint256 initialCliff = _initialTimestamp + 240 days;
                uint256 vestingDuration = _initialTimestamp + 660 days;
                uint256 everyDayReleasePercentage = _remainingDistroPercentage.mul(1e18).div(_noOfRemainingDays);
                // console.log("Every Day Release %: %s", everyDayReleasePercentage);
                require(currentTimeStamp >= initialCliff, "no tokens available for withdrawl");
                if (currentTimeStamp < vestingDuration) {
                    uint256 noOfDaysAfterCliff = BokkyPooBahsDateTimeLibrary.diffDays(initialCliff, currentTimeStamp);
                    uint256 currentUnlockedPercentage = noOfDaysAfterCliff.mul(everyDayReleasePercentage);
                    return uint256(15).mul(1e18).add(currentUnlockedPercentage);
                } else {
                    return uint256(100).mul(1e18);
                }
            }
        } else {
            return 0;
        }
    }

    function _daysToMonths(uint256 _days) private view returns (uint256 noOfMonths) {
        uint256 noOfDaysInMonth = uint256(30).mul(1e18);
        uint256 daysNormalized = _days.mul(1e18);
        uint256 noOfMonts = daysNormalized.div(noOfDaysInMonth);
        return noOfMonts;
    }

    function recoverExcessToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}
