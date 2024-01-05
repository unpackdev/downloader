// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

// import "./console.sol";

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

    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;
    IERC20 private _pmonToken;
    address[] public investors;

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        uint256 initialUnlockAmount;
        uint256 vestingDays;
        uint256 cliffDays;
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

    constructor(address _token) {
        _pmonToken = IERC20(_token);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp) external onlyOwner() notInitialized() {
        isInitialized = true;
        _initialTimestamp = _timestamp;
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev Adds investors. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investors The addresses of new investors.
    /// @param _tokenAllocations The amounts of the tokens that belong to each investor.
    /// @param _vestingDays The amount of days of the daily vesting AFTER THE CLIFF
    function addInvestors(
        address[] calldata _investors,
        uint256[] calldata _tokenAllocations,
        uint256[] calldata _initialUnlockAmount,
        uint256[] calldata _vestingDays,
        uint256[] calldata _cliffDays
    ) external onlyOwner {
        require(_investors.length == _tokenAllocations.length, "different arrays sizes");
        for (uint256 i = 0; i < _investors.length; i++) {
            _addInvestor(_investors[i], _tokenAllocations[i], _initialUnlockAmount[i], _vestingDays[i], _cliffDays[i]);
        }
        emit InvestorsAdded(_investors, _tokenAllocations, msg.sender);
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function _addInvestor(
        address _investor,
        uint256 _tokensAllotment,
        uint256 _initialUnlockAmount,
        uint256 _vestingDays,
        uint256 _cliffDays
    ) internal onlyOwner {
        require(_investor != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.exists = true;
        investor.initialUnlockAmount = _initialUnlockAmount;
        investor.vestingDays = _vestingDays;
        investor.cliffDays = _cliffDays;
        investors.push(_investor);
        _totalAllocatedAmount = _totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    function withdrawTokens() external onlyInvestor() initialized() {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawal");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        _pmonToken.safeTransfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev withdrawable tokens for an address
    /// @param _investor whitelisted investor address
    function withdrawableTokens(address _investor) public view returns (uint256 tokensAvailable) {
        Investor storage investor = investorsInfo[_investor];

        uint256 totalUnlockedTokens = _calculateUnlockedTokens(_investor);
        uint256 tokensWithdrawable = totalUnlockedTokens.sub(investor.withdrawnTokens);

        return tokensWithdrawable;
    }

    /// @dev calculate the amount of unlocked tokens of an investor
    function _calculateUnlockedTokens(address _investor) private view returns (uint256 availableTokens) {
        Investor storage investor = investorsInfo[_investor];

        uint256 cliffTimestamp = _initialTimestamp + investor.cliffDays * 1 days;
        uint256 vestingTimestamp = cliffTimestamp + investor.vestingDays * 1 days;

        uint256 initialDistroAmount = investor.initialUnlockAmount;

        uint256 currentTimeStamp = block.timestamp;

        if (currentTimeStamp > _initialTimestamp) {
            if (currentTimeStamp <= cliffTimestamp) {
                return initialDistroAmount;
            } else if (currentTimeStamp > cliffTimestamp && currentTimeStamp < vestingTimestamp) {
                uint256 vestingDistroAmount = investor.tokensAllotment.sub(initialDistroAmount);
                uint256 everyDayReleaseAmount = vestingDistroAmount.div(investor.vestingDays);

                uint256 noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(cliffTimestamp, currentTimeStamp);
                uint256 vestingUnlockedAmount = noOfDays.mul(everyDayReleaseAmount);
                // console.log("Current Vesting Unlock: %s", vestingUnlockedAmount);

                return initialDistroAmount.add(vestingUnlockedAmount); // total unlocked amount
            } else {
                return investor.tokensAllotment;
            }
        } else {
            return 0;
        }
    }

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}
