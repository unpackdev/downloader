// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// import "./console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

// import "./Ownable.sol";
// import "./SafeERC20.sol";
// import "./IERC20.sol";
// import "./SafeMath.sol";

contract VortexTokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event DistributionAdded(address indexed investor, address indexed caller, uint256 allocation);

    event DistributionRemoved(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    enum DistributionType { RESERVE, REWARDS, TEAM_ADVISORS }

    uint256 private _initialTimestamp;
    IERC20 private _vortexToken;

    struct Distribution {
        address beneficiary;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        DistributionType distributionType;
    }

    mapping(DistributionType => Distribution) public distributionInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;
    /// @dev Boolean variable that indicates whether the investors set was finalized.
    bool public isFinalized = false;

    address _tressuryAddresss = 0x68B6eEC457E8fdd4886F0A91BA7444eC7D6bfaB1;

    uint256 constant _SCALING_FACTOR = 10**18; // decimals
    uint256 constant _year = 365 days;
    uint256 _oneMonth = _year.div(12);
    uint256 _cliff = _oneMonth.mul(6);

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

    constructor(address _token) {
        require(address(_token) != address(0x0), "Vortex token address is not valid");
        _vortexToken = IERC20(_token);

        _addDistribution(_tressuryAddresss, DistributionType.RESERVE, 8000000 * _SCALING_FACTOR);
        _addDistribution(_tressuryAddresss, DistributionType.REWARDS, 27000000 * _SCALING_FACTOR);
        _addDistribution(_tressuryAddresss, DistributionType.TEAM_ADVISORS, 20000000 * _SCALING_FACTOR);
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
        uint256 _tokensAllotment
    ) internal {
        require(_beneficiary != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Distribution storage distribution = distributionInfo[_distributionType];

        require(distribution.tokensAllotment == 0, "investor already added");

        distribution.beneficiary = _beneficiary;
        distribution.tokensAllotment = _tokensAllotment;
        distribution.distributionType = _distributionType;

        emit DistributionAdded(_beneficiary, _msgSender(), _tokensAllotment);
    }

    function withdrawTokens(uint256 _distributionType) external onlyOwner() initialized() {
        Distribution storage distribution = distributionInfo[DistributionType(_distributionType)];

        uint256 tokensAvailable = withdrawableTokens(DistributionType(_distributionType));

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        distribution.withdrawnTokens = distribution.withdrawnTokens.add(tokensAvailable);
        _vortexToken.safeTransfer(distribution.beneficiary, tokensAvailable);

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

    function _getCommunityRewardsPercentage(uint256 _currentTimeStamp)
        private
        view
        returns (uint256 _availablePercentage)
    {
        // Unlocked 16.66% every 6 months starting from TGE
        uint256 sixMonths = _initialTimestamp + _oneMonth * 6;
        uint256 eighteenMonths = _initialTimestamp + _oneMonth * 18;
        uint256 twentyFourMonths = _initialTimestamp + _oneMonth * 24;
        uint256 thirtyMonths = _initialTimestamp + _oneMonth * 30;

        if (_currentTimeStamp <= sixMonths) {
            return 16600000000000000000;
        } else if (_currentTimeStamp > sixMonths && _currentTimeStamp < _year) {
            return 33200000000000000000;
        } else if (_currentTimeStamp > _year && _currentTimeStamp < eighteenMonths) {
            return 49800000000000000000;
        } else if (_currentTimeStamp > eighteenMonths && _currentTimeStamp < twentyFourMonths) {
            return 66400000000000000000;
        } else if (_currentTimeStamp > twentyFourMonths && _currentTimeStamp < thirtyMonths) {
            return 83000000000000000000;
        } else {
            return uint256(100).mul(1e18);
        }
    }

    function _getAdvisorsPercentage(uint256 _currentTimeStamp) private view returns (uint256 _availablePercentage) {
        // TEAM 150 Days Lock from TGE, Released daily over 365 Days after 150 days cliff
        uint256 cliffDuration = _initialTimestamp + 150 days;
        uint256 oneYear = _initialTimestamp + 365 days + 150 days;
        uint256 remainingDistroPercentage = 100;
        uint256 noOfRemaingDays = 365;
        uint256 everyDayReleasePercentage = remainingDistroPercentage.mul(1e18).div(noOfRemaingDays);

        if (_currentTimeStamp > cliffDuration && _currentTimeStamp < oneYear) {
            // Date difference in days - (endDate - startDate) / 60 / 60 / 24; // 40 days
            uint256 intoDays = uint256(60).div(60).div(24);
            uint256 noOfDays = (_currentTimeStamp.sub(cliffDuration)).mul(1e18).div(intoDays);
            uint256 currentUnlockedPercentage = noOfDays.mul(everyDayReleasePercentage).div(1e18);

            return currentUnlockedPercentage.mul(1e18);
        } else {
            return uint256(100).mul(1e18);
        }
    }

    function _calculateAvailablePercentage(DistributionType distributionType)
        private
        view
        returns (uint256 _availablePercentage)
    {
        uint256 currentTimeStamp = block.timestamp;

        if (currentTimeStamp > _initialTimestamp) {
            if (distributionType == DistributionType.RESERVE) {
                // RESERVE Locked for 1 year from TGE
                if (currentTimeStamp <= _year) {
                    return uint256(0).mul(1e18);
                } else if (currentTimeStamp > _year) {
                    return uint256(100).mul(1e18);
                }
            } else if (distributionType == DistributionType.REWARDS) {
                return _getCommunityRewardsPercentage(currentTimeStamp);
            } else if (distributionType == DistributionType.TEAM_ADVISORS) {
                return _getAdvisorsPercentage(currentTimeStamp);
            }
        }
    }

    function recoverExcessToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}
