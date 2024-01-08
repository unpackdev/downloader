// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// import "./console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract PrivateDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InvestorsAdded(address[] investors, uint256[] tokenAllocations, address caller);

    event InvestorAdded(address indexed investor, address indexed caller, uint256 allocation);

    event InvestorRemoved(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event TransferInvestment(address indexed owner, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;
    IERC20 private _oddzToken;
    address[] public investors;

    enum AllocationType { SEED, PRIVATE, STRATEGIC }

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        AllocationType allocationType;
    }

    uint256[] privateVesting = [
        15000000000000000000,
        15000000000000000000,
        15000000000000000000,
        30000000000000000000,
        30000000000000000000,
        30000000000000000000,
        50000000000000000000,
        50000000000000000000,
        50000000000000000000,
        75000000000000000000,
        75000000000000000000,
        75000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000,
        100000000000000000000
    ];

    uint256[] seedVesting = [
        10000000000000000000,
        10000000000000000000,
        10000000000000000000,
        20000000000000000000,
        20000000000000000000,
        20000000000000000000,
        30000000000000000000,
        30000000000000000000,
        30000000000000000000,
        40000000000000000000,
        40000000000000000000,
        40000000000000000000,
        50000000000000000000,
        50000000000000000000,
        50000000000000000000,
        65000000000000000000,
        65000000000000000000,
        65000000000000000000,
        80000000000000000000,
        80000000000000000000,
        80000000000000000000,
        100000000000000000000
    ];

    // 15% unlock on TGE; 15% every month until 5th month after TGE and 10% on 6th month
    // 15, 30, 45, 60,75, 90, 100

    uint256[] strategicVesting = [
        15000000000000000000,
        30000000000000000000,
        45000000000000000000,
        60000000000000000000,
        75000000000000000000,
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
        100000000000000000000,
        100000000000000000000,
        100000000000000000000
    ];

    mapping(address => Investor) public investorsInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;
    /// @dev Boolean variable that indicates whether the investors set was finalized.
    bool public isFinalized = false;

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

    modifier onlyInvestor() {
        require(investorsInfo[_msgSender()].exists, "Only investors allowed");
        _;
    }

    constructor(address _token) {
        _oddzToken = IERC20(_token);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev release tokens to all the investors
    function releaseTokens() external onlyOwner initialized() {
        for (uint8 i = 0; i < investors.length; i++) {
            uint256 availableTokens = withdrawableTokens(investors[i]);
            _oddzToken.safeTransfer(investors[i], availableTokens);
        }
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

    function withdrawTokens() external onlyInvestor() initialized() {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        _oddzToken.safeTransfer(_msgSender(), tokensAvailable);

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
    function withdrawableTokens(address _investor) public view returns (uint256 tokens) {
        Investor storage investor = investorsInfo[_investor];
        uint256 availablePercentage = _calculateAvailablePercentage(investor.allocationType);
        uint256 noOfTokens = _calculatePercentage(investor.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

        // console.log("Withdrawable Tokens: %s", tokensAvailable);

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
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.withdrawnTokens = _withdrawnTokens;
        investor.exists = true;
        investors.push(_investor);
        investor.allocationType = AllocationType(_allocationType);

        _totalAllocatedAmount = _totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    /// @dev Removes investor. This function doesn't limit max gas consumption,
    /// so having too many investors can cause it to reach the out-of-gas error.
    /// @param _investor Investor address.
    function removeInvestor(address _investor) external onlyOwner() {
        require(_investor != address(0), "invalid address");
        Investor storage investor = investorsInfo[_investor];
        uint256 allocation = investor.tokensAllotment;
        require(allocation > 0, "the investor doesn't exist");

        _totalAllocatedAmount = _totalAllocatedAmount.sub(allocation);
        investor.exists = false;
        investor.tokensAllotment = 0;

        emit InvestorRemoved(_investor, _msgSender(), allocation);
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

        if (currentTimeStamp > _initialTimestamp) {
            if (allocationType == AllocationType.PRIVATE) {
                return noOfMonths > 12 ? uint256(100).mul(1e18) : privateVesting[noOfMonths];
            } else if (allocationType == AllocationType.SEED) {
                return noOfMonths > 21 ? uint256(100).mul(1e18) : seedVesting[noOfMonths];
            } else if (allocationType == AllocationType.STRATEGIC) {
                return noOfMonths > 6 ? uint256(100).mul(1e18) : strategicVesting[noOfMonths];
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

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}
