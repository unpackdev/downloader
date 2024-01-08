// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract PolkaRareTokenVesting is Ownable {
    using SafeMath for uint256;
    using BokkyPooBahsDateTimeLibrary for uint256;
    using SafeERC20 for IERC20;

    event DistributionAdded(address indexed investor, address indexed caller, uint256 allocation);

    event DistributionRemoved(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    enum DistributionType { ECOSYSTEM_FUND, MARKETING_GRANTS, ADVISORS, TEAM, RESERVES, OPERATIONS, MINING_STAKING }

    uint256 private _initialTimestamp;
    IERC20 private _pRareToken;

    struct Distribution {
        address beneficiary;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        DistributionType distributionType;
    }

    mapping(DistributionType => Distribution) public distributionInfo;

    mapping(DistributionType => uint256[]) public vestingInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;
    /// @dev Boolean variable that indicates whether the investors set was finalized.
    bool public isFinalized = false;

    uint256 constant _SCALING_FACTOR = 10**18; // decimals

    uint256[] _ecosystemVesting = [
        0,
        0,
        0,
        0,
        0,
        0,
        10000000000000000000,
        20000000000000000000,
        30000000000000000000,
        40000000000000000000,
        50000000000000000000,
        60000000000000000000,
        70000000000000000000,
        80000000000000000000,
        90000000000000000000,
        100000000000000000000
    ];

    uint256[] _marketingVesting = [
        0,
        5000000000000000000,
        10000000000000000000,
        15000000000000000000,
        20000000000000000000,
        25000000000000000000,
        30000000000000000000,
        35000000000000000000,
        40000000000000000000,
        45000000000000000000,
        50000000000000000000,
        55000000000000000000,
        60000000000000000000,
        65000000000000000000,
        70000000000000000000,
        75000000000000000000,
        80000000000000000000,
        85000000000000000000,
        90000000000000000000,
        95000000000000000000,
        100000000000000000000
    ];

    uint256[] _teamVesting = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        10000000000000000000,
        20000000000000000000,
        30000000000000000000,
        40000000000000000000,
        50000000000000000000,
        60000000000000000000,
        70000000000000000000,
        80000000000000000000,
        90000000000000000000,
        100000000000000000000
    ];

    uint256[] _reservesVesting = [
        0,
        0,
        0,
        0,
        0,
        0,
        5000000000000000000,
        10000000000000000000,
        15000000000000000000,
        20000000000000000000,
        25000000000000000000,
        30000000000000000000,
        35000000000000000000,
        40000000000000000000,
        45000000000000000000,
        50000000000000000000,
        55000000000000000000,
        60000000000000000000,
        65000000000000000000,
        70000000000000000000,
        75000000000000000000,
        80000000000000000000,
        85000000000000000000,
        90000000000000000000,
        95000000000000000000,
        100000000000000000000
    ];

    uint256[] _operationsVesting = [
        0,
        0,
        0,
        5000000000000000000,
        10000000000000000000,
        15000000000000000000,
        20000000000000000000,
        25000000000000000000,
        30000000000000000000,
        35000000000000000000,
        40000000000000000000,
        45000000000000000000,
        50000000000000000000,
        55000000000000000000,
        60000000000000000000,
        65000000000000000000,
        70000000000000000000,
        75000000000000000000,
        80000000000000000000,
        85000000000000000000,
        90000000000000000000,
        95000000000000000000,
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

    uint256[] _miningStakingVesting = [
        0,
        10000000000000000000,
        20000000000000000000,
        30000000000000000000,
        40000000000000000000,
        50000000000000000000,
        60000000000000000000,
        70000000000000000000,
        80000000000000000000,
        90000000000000000000,
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

    constructor(address _token, address _treasury) {
        require(address(_token) != address(0x0), "PolkaRare token address is not valid");
        _pRareToken = IERC20(_token);

        _addDistribution(
            _treasury,
            DistributionType.ECOSYSTEM_FUND,
            9625000 * _SCALING_FACTOR,
            3125000 * _SCALING_FACTOR,
            _ecosystemVesting
        );
        _addDistribution(
            _treasury,
            DistributionType.MARKETING_GRANTS,
            10000000 * _SCALING_FACTOR,
            4000000 * _SCALING_FACTOR,
            _marketingVesting
        );
        _addDistribution(_treasury, DistributionType.ADVISORS, 3000000 * _SCALING_FACTOR, 0, _ecosystemVesting);
        _addDistribution(_treasury, DistributionType.TEAM, 12000000 * _SCALING_FACTOR, 0, _teamVesting);
        _addDistribution(_treasury, DistributionType.RESERVES, 10000000 * _SCALING_FACTOR, 0, _reservesVesting);
        _addDistribution(_treasury, DistributionType.OPERATIONS, 4000000 * _SCALING_FACTOR, 0, _operationsVesting);
        _addDistribution(
            _treasury,
            DistributionType.MINING_STAKING,
            120000000 * _SCALING_FACTOR,
            0,
            _miningStakingVesting
        );
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
        uint256 _withdrawnTokens,
        uint256[] storage _distributionVesting
    ) internal {
        require(_beneficiary != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Distribution storage distribution = distributionInfo[_distributionType];

        require(distribution.tokensAllotment == 0, "investor already added");

        distribution.beneficiary = _beneficiary;
        distribution.withdrawnTokens = _withdrawnTokens;
        distribution.tokensAllotment = _tokensAllotment;
        distribution.distributionType = _distributionType;
        vestingInfo[_distributionType] = _distributionVesting;

        emit DistributionAdded(_beneficiary, _msgSender(), _tokensAllotment);
    }

    function withdrawTokens(uint256 _distributionType) external onlyOwner() initialized() {
        Distribution storage distribution = distributionInfo[DistributionType(_distributionType)];

        uint256 tokensAvailable = withdrawableTokens(DistributionType(_distributionType));

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        distribution.withdrawnTokens = distribution.withdrawnTokens.add(tokensAvailable);
        _pRareToken.safeTransfer(distribution.beneficiary, tokensAvailable);

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
        uint256[] storage distributionVesting = vestingInfo[distributionType];

        if (currentTimeStamp > _initialTimestamp) {
            return distributionVesting[noOfMonths];
        } else {
            return 0;
        }
    }

    function _daysToMonths(uint256 _days) private pure returns (uint256 noOfMonths) {
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
