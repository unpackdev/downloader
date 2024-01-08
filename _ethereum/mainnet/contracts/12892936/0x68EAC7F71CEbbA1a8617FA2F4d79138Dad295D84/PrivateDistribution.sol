// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

// import "./console.sol";

contract PrivateDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InvestorsAdded(address[] investors, uint256[] tokenAllocations, address caller);

    event InvestorAdded(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event TransferInvestment(address indexed owner, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;
    IERC20 private _donToken;
    address[] public investors;

    enum AllocationType { SEED, PRIVATE_ONE, PRIVATE_TWO, MARKETING, ADVISORS }

    uint256[] _seedVesting = [
        10000000000000000000,
        19000000000000000000,
        28000000000000000000,
        37000000000000000000,
        46000000000000000000,
        55000000000000000000,
        64000000000000000000,
        73000000000000000000,
        82000000000000000000,
        91000000000000000000,
        100000000000000000000
    ];

    uint256[] _privateVesting = [
        15000000000000000000,
        23500000000000000000,
        32000000000000000000,
        40500000000000000000,
        49000000000000000000,
        57500000000000000000,
        66000000000000000000,
        74500000000000000000,
        83000000000000000000,
        91500000000000000000,
        100000000000000000000
    ];

    uint256[] _marketingVesting = [
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

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        AllocationType allocationType;
    }

    mapping(AllocationType => mapping(address => Investor)) public investorsInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;

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

    modifier onlyInvestor(AllocationType _allocationType) {
        require(investorsInfo[_allocationType][_msgSender()].exists, "Only investors allowed");
        _;
    }

    constructor(address _token) {
        _donToken = IERC20(_token);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev Adds investors. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investors The addresses of new investors.
    /// @param _tokenAllocations The amounts of the tokens that belong to each investor.
    function addInvestors(
        address[] calldata _investors,
        uint256[] calldata _tokenAllocations,
        uint256[] calldata _withdrawnTokens,
        uint256[] calldata _allocationTypes
    ) external onlyOwner {
        require(_investors.length == _tokenAllocations.length, "different arrays sizes");
        for (uint256 i = 0; i < _investors.length; i++) {
            _addInvestor(_investors[i], _tokenAllocations[i], _withdrawnTokens[i], _allocationTypes[i]);
        }
        emit InvestorsAdded(_investors, _tokenAllocations, msg.sender);
    }

    function withdrawTokens(AllocationType _allocationType) external onlyInvestor(_allocationType) initialized() {
        Investor storage investor = investorsInfo[_allocationType][_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_allocationType, _msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawal");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        _donToken.safeTransfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp) external onlyOwner() notInitialized() {
        isInitialized = true;
        _initialTimestamp = _timestamp;
    }

    /// @dev withdrawble tokens for an address
    /// @param _investor whitelisted investor address
    function withdrawableTokens(AllocationType _allocationType, address _investor)
        public
        view
        returns (uint256 tokens)
    {
        Investor storage investor = investorsInfo[_allocationType][_investor];
        uint256 availablePercentage = _calculateAvailablePercentage(investor.allocationType);
        uint256 noOfTokens = _calculatePercentage(investor.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

        // console.log("Avaialable Percentage: %s%", availablePercentage.div(1e18));
        // console.log("Withdrawable Tokens: %s", tokensAvailable.div(1e18));

        return tokensAvailable;
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    /// @param _allocationType The allocation type to each investor.
    function _addInvestor(
        address _investor,
        uint256 _tokensAllotment,
        uint256 _withdrawnTokens,
        uint256 _allocationType
    ) internal onlyOwner {
        require(_investor != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        AllocationType allocationType = AllocationType(_allocationType);
        Investor storage investor = investorsInfo[allocationType][_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.withdrawnTokens = _withdrawnTokens;
        investor.exists = true;
        investors.push(_investor);
        investor.allocationType = allocationType;

        _totalAllocatedAmount = _totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    /// @dev calculate percentage value from amount
    /// @param _amount amount input to find the percentage
    /// @param _percentage percentage for an amount
    function _calculatePercentage(uint256 _amount, uint256 _percentage) private pure returns (uint256 percentage) {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage(AllocationType allocationType)
        private
        view
        returns (uint256 availablePercentage)
    {
        uint256 currentTimeStamp = block.timestamp;
        uint256 noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(_initialTimestamp, currentTimeStamp);
        uint256 noOfMonths = _daysToMonths(noOfDays);

        if (allocationType == AllocationType.PRIVATE_ONE || allocationType == AllocationType.PRIVATE_TWO) {
            return _privateVesting[noOfMonths];
        } else if (allocationType == AllocationType.SEED) {
            return _seedVesting[noOfMonths];
        } else if (allocationType == AllocationType.MARKETING || allocationType == AllocationType.ADVISORS) {
            return _marketingVesting[noOfMonths];
        }

        return uint256(0);
    }

    function _daysToMonths(uint256 _days) private view returns (uint256 noOfMonths) {
        uint256 noOfDaysInMonth = uint256(30).mul(1e18);
        uint256 daysNormalized = _days.mul(1e18);
        return daysNormalized.div(noOfDaysInMonth);
    }

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}
