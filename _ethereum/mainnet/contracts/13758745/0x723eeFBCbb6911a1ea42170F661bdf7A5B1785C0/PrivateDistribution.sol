// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// import "./console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract EcosystemDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InvestorsAdded(address[] investors, uint256[] tokenAllocations, address caller);

    event InvestorAdded(address indexed investor, address indexed caller, uint256 allocation);

    event InvestorRemoved(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event DepositInvestment(address indexed investor, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;
    IERC20 private _propelToken;
    address[] public investors;

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
    }

    struct Vesting {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    mapping(uint256 => Vesting) public vestingsInfo;
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

    // 20% on TGE, 3 months cliff and monthly upto 12 months
    uint256[] _privateVesting = [
        20000000000000000000,
        20000000000000000000,
        20000000000000000000,
        20000000000000000000,
        28888888889000000000,
        37777777778000000000,
        46666666667000000000,
        55555555556000000000,
        64444444445000000000,
        73333333334000000000,
        82222222223000000000,
        91111111112000000000,
        100000000001000000000
    ];

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
        _propelToken = IERC20(_token);
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
        uint256[] calldata _withdrawnTokens
    ) external onlyOwner {
        require(_investors.length == _tokenAllocations.length, "different arrays sizes");
        for (uint256 i = 0; i < _investors.length; i++) {
            _addInvestor(_investors[i], _tokenAllocations[i], _withdrawnTokens[i]);
        }
        emit InvestorsAdded(_investors, _tokenAllocations, msg.sender);
    }

    // 25% at TGE, 75% released daily over 120 Days after 30 Days Cliff
    function withdrawTokens() external onlyInvestor() initialized() {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        _propelToken.safeTransfer(_msgSender(), tokensAvailable);

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
        uint256 availablePercentage = _calculateAvailablePercentage();
        uint256 noOfTokens = _calculatePercentage(investor.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

        return tokensAvailable;
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    /// @param _withdrawnTokens The amounts of the tokens already withdrawn by each investor.
    function _addInvestor(
        address _investor,
        uint256 _tokensAllotment,
        uint256 _withdrawnTokens
    ) internal onlyOwner {
        require(_investor != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.withdrawnTokens = _withdrawnTokens;
        investor.exists = true;
        investors.push(_investor);
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

    function _calculateAvailablePercentage() private view returns (uint256 availablePercentage) {
        uint256 currentTimeStamp = block.timestamp;
        uint256 noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(_initialTimestamp, currentTimeStamp);
        uint256 noOfMonths = _daysToMonths(noOfDays);

        // console.log("Months=%s, Release Percentage=%s%", noOfMonths, _privateVesting[noOfMonths].div(1e18));

        return noOfMonths > 11 ? uint256(100).mul(1e18) : _privateVesting[noOfMonths];
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
