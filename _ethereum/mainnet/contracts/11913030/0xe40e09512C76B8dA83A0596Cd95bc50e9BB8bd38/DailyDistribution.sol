// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// import "./console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract DailyDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InvestorAdded(address indexed investor, address indexed caller, uint256 allocation);

    event InvestorRemoved(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event DepositInvestment(address indexed investor, uint256 value);

    event TransferInvestment(address indexed owner, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    uint256 private totalAllocatedAmount;
    uint256 private initialTimestamp;
    IERC20 private token;

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
    }

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

    constructor(address _token) public {
        token = IERC20(_token);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return initialTimestamp;
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function addInvestor(address _investor, uint256 _tokensAllotment) external onlyOwner {
        require(_investor != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.exists = true;
        totalAllocatedAmount = totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    // 15% on listing and rest daily distribution from day 31 for 11 months (12 months)
    function withdrawTokens() external onlyInvestor() initialized() {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        token.safeTransfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp) external onlyOwner() notInitialized() {
        isInitialized = true;
        initialTimestamp = _timestamp;
    }

    function withdrawableTokens(address _investor) public view returns (uint256 tokens) {
        Investor storage investor = investorsInfo[_investor];
        uint256 availablePercentage = _calculateAvailablePercentage();
        uint256 noOfTokens = _calculatePercentage(investor.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

        return tokensAvailable;
    }

    function _calculatePercentage(uint256 _amount, uint256 _percentage) private pure returns (uint256 percentage) {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage() private view returns (uint256 availablePercentage) {
        // Daily distribution from day 1 for 10 months
        // 0.373134328% of tokens everyday
        // 1000000 MAHA assigned

        uint256 distroDuration = initialTimestamp + 268 days;
        uint256 remainingDistroPercentage = 100;
        uint256 noOfRemaingDays = 268;
        uint256 everyDayReleasePercentage = remainingDistroPercentage.mul(1e18).div(noOfRemaingDays);
        // console.log("Every Day Release %: %s", everyDayReleasePercentage);

        uint256 currentTimeStamp = block.timestamp;

        if (currentTimeStamp > initialTimestamp) {
            if (currentTimeStamp < distroDuration) {
                uint256 noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(initialTimestamp, currentTimeStamp);
                // console.log("Number of days: %s", noOfDays);
                uint256 currentUnlockedPercentage = noOfDays.mul(everyDayReleasePercentage);
                // console.log("Current Unlock %: %s", currentUnlockedPercentage);
                return currentUnlockedPercentage;
            } else {
                return uint256(100).mul(1e18);
            }
        } else {
            return uint256(0);
        }
    }

    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), _amount);
        emit RecoverToken(_token, _amount);
    }
}
