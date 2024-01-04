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

    event DepositInvestment(address indexed investor, uint256 value);

    event TransferInvestment(address indexed owner, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    event TokenVestingAdded(uint256 indexed vestingMonth, uint256 indexed releaseTime, uint256 releasePercentage);

    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;
    IERC20 private _blankToken;
    address[] public investors;
    uint256 private vestingMonth = 0;

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

    string private constant INSUFFICIENT_BALANCE = "Insufficient balance";
    string private constant INVALID_VESTING_ID = "Invalid vesting id";
    string private constant VESTING_ALREADY_RELEASED = "Vesting already released";
    string private constant INVALID_BENEFICIARY = "Invalid beneficiary address";
    string private constant NOT_VESTED = "Tokens have not vested yet";


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
        _blankToken = IERC20(_token);

        uint256 SCALING_FACTOR = 10 ** 18; // decimals
        uint256 day = 1 days;

        // 20% on TGE, 8% for Month 1 2; then 7% for Month 3 6; then 6% for Month 7 12
        addVesting(_initialTimestamp, 20 * SCALING_FACTOR);
        // 8% for Month 1 2
        addVesting(_initialTimestamp + 30 * day, 28 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 60 * day, 36 * SCALING_FACTOR);
        // 7% for Month 3 6
        addVesting(_initialTimestamp + 90 * day, 43 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 120 * day, 50 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 150 * day, 57 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 180 * day, 64 * SCALING_FACTOR);
        // 6% for Month 7 12
        addVesting(_initialTimestamp + 210 * day, 70 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 240 * day, 76 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 270 * day, 82 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 300 * day, 88 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 330 * day, 94 * SCALING_FACTOR);
        addVesting(_initialTimestamp + 365 * day, 100 * SCALING_FACTOR);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev release tokens to all the investors
    function releaseTokens() external onlyOwner initialized() {
        for (uint8 i = 0; i < investors.length; i++) {
            uint256 availableTokens = withdrawableTokens(investors[i]);
            _blankToken.safeTransfer(investors[i], availableTokens);
        }
    }

    /// @dev Adds investors. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investors The addresses of new investors.
    /// @param _tokenAllocations The amounts of the tokens that belong to each investor.
    function addInvestors(address[] calldata _investors, uint256[] calldata _tokenAllocations) external onlyOwner {
        require(_investors.length == _tokenAllocations.length, "different arrays sizes");
        for (uint256 i = 0; i < _investors.length; i++) {
            _addInvestor(_investors[i], _tokenAllocations[i]);
        }
        emit InvestorsAdded(_investors, _tokenAllocations, msg.sender);
    }

    // 25% at TGE, 75% released daily over 120 Days after 30 Days Cliff
    function withdrawTokens() external onlyInvestor() initialized() {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        _blankToken.safeTransfer(_msgSender(), tokensAvailable);

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

    /**
     * @notice Function to add a vesting
     * Since this is onlyOwner protected, tokens are assumed to be transferred to the vesting contract
     * @param _releaseTime  Time for release
     * @param _releasePercentage       Amount of vesting
     */
    function addVesting(
        uint256 _releaseTime,
        uint256 _releasePercentage
    ) public onlyOwner {
        vestingMonth = vestingMonth.add(1);
        vestingsInfo[vestingMonth] = Vesting({
            releaseTime: _releaseTime,
            releasePercentage: _releasePercentage
        });
        emit TokenVestingAdded(vestingMonth , _releaseTime, _releasePercentage);
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function _addInvestor(address _investor, uint256 _tokensAllotment) internal onlyOwner {
        require(_investor != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.exists = true;
        investors.push(_investor);
        _totalAllocatedAmount = _totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    /// @dev calculate percentage value from amount
    /// @param _amount amount input to find the percentage
    /// @param _percentage percentage for an amount
    function _calculatePercentage(uint256 _amount, uint256 _percentage) private pure returns (uint256 percentage) {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage() private view returns (uint256 availablePercentage) {
        uint256 currentTimeStamp = block.timestamp;
        uint256 noOfMonths = BokkyPooBahsDateTimeLibrary.diffMonths(_initialTimestamp, currentTimeStamp);
        Vesting storage vesting = vestingsInfo[noOfMonths.add(1)];

        // console.log("Months=%s, Release Percentage=%s%", noOfMonths.add(1), vesting.releasePercentage.div(1e18));

        return vesting.releasePercentage;
    }

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}
