// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ITokenVesting.sol";

contract LeagueTokenVesting is ITokenVesting, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== TYPES  ========== */

    /**
     * totalSupply : total supply allocated to the round
     * supplyLeft : available supply that can be assigned to investor
     * price : price of token (ex: 0.12$ = 0.12 * 100 = 12)
     * initialReleasePercent : percent to tokens which will be given at the tge
     * cliffPeriod : duration of cliff period
     * cliffEndTime : time at which cliff ends
     * vestingPeriod : duration of individual vesting
     * noOfVestings : total no of vesting to give
     */
    struct RoundInfo {
        uint256 totalSupply;
        uint256 supplyLeft;
        uint256 price;
        uint256 initialReleasePercent;
        uint256 cliffPeriod;
        uint256 cliffEndTime;
        uint256 vestingPeriod;
        uint256 noOfVestings;
    }

    /**
     * totalAssigned : total tokens assigned to the investor
     * vestingTokens : no of tokens to give at each vesting
     * vestingsClaimed : total no off vesting which will be given
     * initialClaimReleased : tell tokens released at the tge are received or not
     */
    struct Investor {
        uint256 totalAssigned;
        uint256 vestingTokens;
        uint256 vestingsClaimed;
        bool initialClaimReleased;
    }

    /**
     * beneficiary : address of account which be be able to claim tokens
     */
    struct TeamInfo {
        address beneficiary;
        uint256 cliffPeriod;
        uint256 cliffEndTime;
        uint256 vestingPeriod;
        uint256 noOfVestings;
        uint256 totalSupply;
        uint256 initialReleasePercent;
        uint256 vestingsClaimed;
        uint256 vestingTokens;
        bool initialClaimReleased;
    }

    /* ========== STATE VARIABLES  ========== */

    RoundInfo public roundInfo;
    mapping(address => Investor) public investorInfo;
    address[] public investors;

    uint256 public startTime;
    IERC20Upgradeable public leagueToken;

    /* ========== CONSTANTS ========== */

    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");

    /*
     * 100% = 100 * 100 (MULTIPLIER)
     * all value which are in percent are multiplied with MULTIPLIER(100) to handle precision up to 2 places
     */
    uint256 private constant PERCENTAGE_MULTIPLIER = 10000;

    /**
        365 days in 1 year
        1 month = 30 days + 10 hours,
        12 months = 360 days + 120 hours = 365 days
        4 months = 120 days + 40 hours;
        6 months = 180 days + 60 hours;
        9 months = 270 days + 90 hours;
    */

    /**
        supply : 100.0%
        initial release : 0%
        cliff: 0 days,
        vesting schedule : unlock new tokens each 7 days for 2 years
        no of vestings : 2 years/7 days = 104 vests
     */
    uint256 private constant SUPPLY_PERCENT = 10000;
    uint256 private constant PRICE = 1e18;
    uint256 private constant INITIAL_RELEASE_PERCENT = 0;
    uint256 private constant CLIFF_PERIOD = 0 days;
    uint256 private constant VESTING_PERIOD = 7 days;
    uint256 private constant NO_OF_VESTINGS = 100;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev all the details are hard coded
     */
    function initialize(IERC20Upgradeable _leagueToken, uint256 _startAfter) public initializer {
        require(_startAfter > 0, "Invalid startTime");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VESTER_ROLE, _msgSender());

        uint256 _startTime = block.timestamp + _startAfter;

        leagueToken = _leagueToken;
        startTime = _startTime;
        uint256 leagueTotalSupply = 460_000_000  * 10**18;

        _addRound(
            leagueTotalSupply,
            PRICE,
            INITIAL_RELEASE_PERCENT,
            CLIFF_PERIOD,
            VESTING_PERIOD,
            NO_OF_VESTINGS,
            _startTime
        );
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function addVester(address _newVester) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VESTER_ROLE, _newVester);
    }

    function removeVester(address _vesterToRemove) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VESTER_ROLE, _vesterToRemove);
    }

    /**
     * @notice update start time
     * @param _startAfter time after which u want to start (cant be 0);
     * @dev can only be updated before the start
     */
    function updateStartTime(uint256 _startAfter) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_startAfter > 0, "Invalid startTime");
        require(block.timestamp < startTime, "Already started");

        uint256 _startTime = block.timestamp + _startAfter;

        _massUpdateCliffEndTime(_startTime);

        startTime = _startTime;
    }

    /**
     * @notice recover any erc20 token (ex - nomo token)
     */
    function recoverToken(address _token, uint256 amount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }

    /* ========== VESTER FUNCTIONS ========== */

    /**
     * @notice add, update or remove single investor
     * @param _amount for how much amount (in $) has investor invested. ex  100$ = 100 * 100 = 100,00
     * @dev to remove make amount 0 before it starts
     * @dev you can add, updated and remove any time
     */
    function addOrUpdateInvestor(address _investor, uint256 _amount) external override onlyRole(VESTER_ROLE) {
        _addInvestor(_investor, _amount);

        emit InvestorAdded(_investor, _amount);
    }

    /**
     * @notice add, update or remove multiples investors
     */
    function addOrUpdateInvestors(address[] memory _investors, uint256[] memory _amount)
        external
        override
        onlyRole(VESTER_ROLE)
    {
        uint256 length = _investors.length;

        require(_amount.length == length, "Arguments length not match");

        for (uint256 i = 0; i < length; i++) {
            _addInvestor(_investors[i], _amount[i]);
        }

        emit InvestorsAdded(_investors, _amount);
    }

    /* ========== Investor FUNCTIONS ========== */

    /**
     * @notice claim unlocked tokens (only investor)
     */
    function claimInvestorUnlockedTokens() external override onlyInvestor started {
        RoundInfo memory round = roundInfo;
        Investor memory investor = investorInfo[_msgSender()];

        require(investor.vestingsClaimed < round.noOfVestings, "Already claimed all vesting");

        uint256 unlockedTokens;

        if (block.timestamp >= round.cliffEndTime) {
            uint256 claimableVestingLeft;
            (unlockedTokens, claimableVestingLeft) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);

            investorInfo[_msgSender()].vestingsClaimed = investor.vestingsClaimed + claimableVestingLeft;
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
            investorInfo[_msgSender()].initialClaimReleased = true;
        }

        require(unlockedTokens > 0, "No unlocked tokens available");

        leagueToken.safeTransfer(_msgSender(), unlockedTokens);
        emit InvestorTokensClaimed(_msgSender(), unlockedTokens);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    /**
     * @param _totalSupply : total supply of nomo token for this round
     * @param _price : price of nomo token in $
     * @param _initialReleasePercent : tokens to be released at token generation event
     * @param _cliffPeriod : time user have to wait after start to get his/her first vesting
     * @param _vestingPeriod : duration of single vesting (in secs)
     * @param _noOfVestings : total no of vesting will be given
     */
    function _addRound(
        uint256 _totalSupply,
        uint256 _price,
        uint256 _initialReleasePercent,
        uint256 _cliffPeriod,
        uint256 _vestingPeriod,
        uint256 _noOfVestings,
        uint256 _startTime
    ) internal virtual {
        RoundInfo storage newRoundInfo = roundInfo;

        newRoundInfo.price = _price;
        newRoundInfo.totalSupply = _totalSupply;
        newRoundInfo.supplyLeft = _totalSupply;
        newRoundInfo.initialReleasePercent = _initialReleasePercent;
        newRoundInfo.cliffPeriod = _cliffPeriod;
        newRoundInfo.vestingPeriod = _vestingPeriod;
        newRoundInfo.noOfVestings = _noOfVestings;
        newRoundInfo.cliffEndTime = _startTime + _cliffPeriod;
    }

    function _massUpdateCliffEndTime(uint256 _startTime) private {
        roundInfo.cliffEndTime = _startTime + roundInfo.cliffPeriod;
    }

    function _addInvestor(address _investorAddress, uint256 _amount) private {
        require(_investorAddress != address(0), "Invalid address");

        RoundInfo memory round = roundInfo;
        Investor storage investor = investorInfo[_investorAddress];
        uint256 totalAssigned = (_amount * 1e18) / round.price;

        require(round.supplyLeft >= totalAssigned, "Insufficient supply");

        if (investor.totalAssigned == 0) {
            investors.push(_investorAddress);
            roundInfo.supplyLeft = round.supplyLeft - totalAssigned;
        } else {
            roundInfo.supplyLeft = round.supplyLeft + investor.totalAssigned - totalAssigned;
        }
        investor.totalAssigned = totalAssigned;
        investor.vestingTokens =
            (totalAssigned - ((totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER)) /
            round.noOfVestings;
    }

    /**
     * @notice Calculate the total vesting claimable vesting left for investor
     * @dev will only run in case if cliff period ends and investor have unclaimed vesting left
     */
    function _getInvestorUnlockedTokensAndVestingLeft(RoundInfo memory _round, Investor memory _investor)
        private
        view
        returns (uint256, uint256)
    {
        uint256 totalClaimableVesting = ((block.timestamp - _round.cliffEndTime) / _round.vestingPeriod) + 1;

        uint256 claimableVestingLeft = totalClaimableVesting > _round.noOfVestings
            ? _round.noOfVestings - _investor.vestingsClaimed
            : totalClaimableVesting - _investor.vestingsClaimed;

        uint256 unlockedTokens = _investor.vestingTokens * claimableVestingLeft;

        return (unlockedTokens, claimableVestingLeft);
    }

    /* ========== VIEWS ========== */

    /**
     * @return amount of unlockToken which are currently unclaimed for a investor
     */
    function getInvestorClaimableTokens(address _investor) external view override returns (uint256) {
        RoundInfo memory round = roundInfo;
        Investor memory investor = investorInfo[_investor];

        if (startTime == 0 || block.timestamp < startTime || investor.vestingsClaimed == round.noOfVestings) return 0;

        uint256 unlockedTokens;
        if (block.timestamp >= round.cliffEndTime) {
            (unlockedTokens, ) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
        }

        return unlockedTokens;
    }

    function getInvestorTotalAssigned(address _investor) external view returns (uint256) {
        return investorInfo[_investor].totalAssigned;
    }

    function getInvestorVestingTokens(address _investor) external view returns (uint256) {
        return investorInfo[_investor].vestingTokens;
    }

    function getInvestorVestingsClaimed(address _investor) external view returns (uint256) {
        return investorInfo[_investor].vestingsClaimed;
    }

    function getInvestorTokensInContract(address _investor) external view returns (uint256) {
        return
            investorInfo[_investor].totalAssigned -
            (investorInfo[_investor].vestingTokens * investorInfo[_investor].vestingsClaimed);
    }

    /* ========== MODIFIERS ========== */

    modifier started() {
        require(block.timestamp > startTime, "Not started yet");
        _;
    }

    modifier onlyInvestor() {
        require(investorInfo[_msgSender()].totalAssigned > 0, "Caller is not a investor");
        _;
    }
}
