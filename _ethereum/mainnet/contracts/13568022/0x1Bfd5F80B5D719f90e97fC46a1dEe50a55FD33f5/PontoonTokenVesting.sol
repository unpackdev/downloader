// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./console.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./ITokenVesting.sol";

contract PontoonTokenVesting is ITokenVesting, Ownable {
    using SafeERC20 for IERC20;

    /* ========== TYPES  ========== */

    /**
     * totalSupply : total supply allocated to the round
     * supplyLeft : available supply that can be assigned to investor
     * price : price of token (ex: 0.12$ = 0.12 * 100 = 12)
     * initialReleasePercent : percent to tokens which will be given at the tge
     * listingReleasePercent : percent to tokens which will be given after listing period ends
     * vestingPeriod : duration of listing period (start after tge)
     * cliffPeriod : duration of cliff period (starts after listing period)
     * cliffEndTime : time at which cliff ends (first vesting will be given at this time)
     * vestingPeriod : duration of individual vesting
     * noOfVestings : total no of vesting to give
     */
    struct RoundInfo {
        uint256 totalSupply;
        uint256 supplyLeft;
        uint256 price;
        uint256 initialReleasePercent;
        uint256 listingReleasePercent;
        uint256 listingPeriod;
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
     * listingClaimReleased : tell tokens released at the end of listing period are received or not
     */
    struct Investor {
        uint256 totalAssigned;
        uint256 vestingTokens;
        uint256 vestingsClaimed;
        bool initialClaimReleased;
        bool listingClaimReleased;
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

    mapping(RoundType => RoundInfo) public roundInfo;
    mapping(RoundType => mapping(address => Investor)) public investorInfo;
    mapping(RoundType => address[]) internal investors;

    mapping(TeamType => TeamInfo) public teamInfo;

    uint256 public startTime;
    IERC20 public toonToken;

    /* ========== CONSTANTS ========== */

    /*
     * 100% = 100 * 100 (MULTIPLIER)
     * all value which are in percent are multiplied with MULTIPLIER(100) to handle precision up to 2 places
     */
    uint256 private constant PERCENTAGE_MULTIPLIER = 10000;

    /**
        365 days in 1 year
        12 months = 360 days + 120 hours = 365 days
        24 months = 730 days;
        36 months = 1095 days;
        1 month = 30 days + 10 hours,
        3 months = 90 days + 30 hours;
        4 months = 120 days + 40 hours;
        6 months = 180 days + 60 hours;
        9 months = 270 days + 90 hours;
      
    */

    // for team : start -> cliff period -> vesting schedule
    // for rounds : start -> listingPeriod -> cliff period -> vesting schedule

    /**
        supply : 29% (20 * 100 = 2900)
        initial release : 10% (10 * 100 = 1000)
        cliff: 0, 
        vesting schedule : linear vesting for 24 months months 
        vesting period : 1 (single vesting period is of 1 sec)
        no of vestings : sec in 24 months  (as for each sec tokens will be released)
     */
    uint256 private constant ECOSYSTEM_AND_MARKETING_SUPPLY_PERCENT = 2900;
    uint256 private constant ECOSYSTEM_AND_MARKETING_INITIAL_RELEASE_PERCENT = 1000;
    uint256 private constant ECOSYSTEM_AND_MARKETING_CLIFF_PERIOD = 0;
    uint256 private constant ECOSYSTEM_AND_MARKETING_VESTING_PERIOD = 1;
    uint256 private constant ECOSYSTEM_AND_MARKETING_NO_OF_VESTINGS = 730 days;

    /**
        supply : 35.0% (35 * 100 = 3500)
        initial release : 10% (10 * 100 = 1000)
        cliff: 0, 
        vesting schedule : linear vesting for 36 months months 
        vesting period : 1 (single vesting period is of 1 sec)
        no of vestings : sec in 36 months (as for each sec tokens will be released)
     */
    uint256 private constant COMMUNITY_REWARDS_SUPPLY_PERCENT = 3500;
    uint256 private constant COMMUNITY_REWARDS_INITIAL_RELEASE_PERCENT = 1000;
    uint256 private constant COMMUNITY_REWARDS_CLIFF_PERIOD = 0;
    uint256 private constant COMMUNITY_REWARDS_VESTING_PERIOD = 1;
    uint256 private constant COMMUNITY_REWARDS_NO_OF_VESTINGS = 1095 days;

    /**
        supply : 15.0% (15 * 100 = 1500)
        initial release : 0%
        cliff: 6 months, 
        vesting schedule : 25 % unlock after every 6 month
        no of vestings : 100% / 25% = 4 vesting
     */
    uint256 private constant TEAM_AND_ADVISORS_SUPPLY_PERCENT = 1500;
    uint256 private constant TEAM_AND_ADVISORS_INITIAL_RELEASE_PERCENT = 0;
    uint256 private constant TEAM_AND_ADVISORS_CLIFF_PERIOD = 180 days + 60 hours;
    uint256 private constant TEAM_AND_ADVISORS_VESTING_PERIOD = 180 days + 60 hours;
    uint256 private constant TEAM_AND_ADVISORS_NO_OF_VESTINGS = 4;

    /**
        supply: 6.5%, (6.5 * 100 = 650)
        price : in $ : 0.12 * 100 = 12
        initial release : 0%
        10 % release after 3 months listing
        cliff: 4 months, 
        vesting schedule : 9 months linear vesting
     */
    uint256 private constant SEED_SUPPLY_PERCENT = 650;
    uint256 private constant SEED_PRICE = 12;
    uint256 private constant SEED_INITIAL_RELEASE_PERCENT = 0;
    uint256 private constant SEED_LISTING_RELEASE_PERCENT = 1000;
    uint256 private constant SEED_LISTING_PERIOD = 90 days + 30 hours;
    uint256 private constant SEED_CLIFF_PERIOD = 120 days + 40 hours;
    uint256 private constant SEED_VESTING_PERIOD = 1;
    uint256 private constant SEED_NO_OF_VESTINGS = 270 days + 90 hours;

    /**
        supply: 8.5%,
        price : in $ : 0.18 * 100 = 18
        initial release : 0%
        15 % release after 3 months listing
        cliff: 4 months, 
        vesting schedule : 9 months linear vesting
     */
    uint256 private constant PRIVATE_SUPPLY_PERCENT = 850;
    uint256 private constant PRIVATE_PRICE = 18;
    uint256 private constant PRIVATE_INITIAL_RELEASE_PERCENT = 0;
    uint256 private constant PRIVATE_LISTING_RELEASE_PERCENT = 1500;
    uint256 private constant PRIVATE_LISTING_PERIOD = 90 days + 30 hours;
    uint256 private constant PRIVATE_CLIFF_PERIOD = 120 days + 40 hours;
    uint256 private constant PRIVATE_VESTING_PERIOD = 1;
    uint256 private constant PRIVATE_NO_OF_VESTINGS = 270 days + 90 hours;

    /**
        supply : 4.0%
        price : in $ : 0.23 * 100 = 23
        initial release : 0%
        15 % release after 3 months listing
        cliff: 4 months, 
        vesting schedule : 9 months linear vesting
     */
    uint256 private constant STRATEGIC_SUPPLY_PERCENT = 400;
    uint256 private constant STRATEGIC_PRICE = 23;
    uint256 private constant STRATEGIC_INITIAL_RELEASE_PERCENT = 0;
    uint256 private constant STRATEGIC_LISTING_RELEASE_PERCENT = 1500;
    uint256 private constant STRATEGIC_LISTING_PERIOD = 90 days + 30 hours;
    uint256 private constant STRATEGIC_CLIFF_PERIOD = 120 days + 40 hours;
    uint256 private constant STRATEGIC_VESTING_PERIOD = 1;
    uint256 private constant STRATEGIC_NO_OF_VESTINGS = 270 days + 90 hours;

    /**
        supply : 2%
        price : in $ : 0.35 * 100 = 35
        no lockup, ie initial release 100%
     */
    uint256 private constant PUBLIC_SUPPLY_PERCENT = 200;
    uint256 private constant PUBLIC_PRICE = 35;
    uint256 private constant PUBLIC_INITIAL_RELEASE_PERCENT = 10000;
    uint256 private constant PUBLIC_LISTING_RELEASE_PERCENT = 0;
    uint256 private constant PUBLIC_LISTING_PERIOD = 0;
    uint256 private constant PUBLIC_CLIFF_PERIOD = 0;
    uint256 private constant PUBLIC_VESTING_PERIOD = 0;
    uint256 private constant PUBLIC_NO_OF_VESTINGS = 1;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev all the details are hard coded
     */
    constructor(
        IERC20 _toonToken,
        address _ecosystemAndMarketing,
        address _communityRewards,
        address _teamAndAdvisors
    ) {
        require(
            _ecosystemAndMarketing != address(0) && _communityRewards != address(0) && _teamAndAdvisors != address(0),
            "Invalid address"
        );

        toonToken = _toonToken;
        uint256 toonTotalSupply = _toonToken.totalSupply();

        _addTeam(
            TeamType.ECOSYSTEM_AND_MARKETING,
            _ecosystemAndMarketing,
            (toonTotalSupply * ECOSYSTEM_AND_MARKETING_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            ECOSYSTEM_AND_MARKETING_INITIAL_RELEASE_PERCENT,
            ECOSYSTEM_AND_MARKETING_CLIFF_PERIOD,
            ECOSYSTEM_AND_MARKETING_VESTING_PERIOD,
            ECOSYSTEM_AND_MARKETING_NO_OF_VESTINGS
        );

        _addTeam(
            TeamType.COMMUNITY_REWARDS,
            _communityRewards,
            (toonTotalSupply * COMMUNITY_REWARDS_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            COMMUNITY_REWARDS_INITIAL_RELEASE_PERCENT,
            COMMUNITY_REWARDS_CLIFF_PERIOD,
            COMMUNITY_REWARDS_VESTING_PERIOD,
            COMMUNITY_REWARDS_NO_OF_VESTINGS
        );

        _addTeam(
            TeamType.TEAM_AND_ADVISORS,
            _teamAndAdvisors,
            (toonTotalSupply * TEAM_AND_ADVISORS_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            TEAM_AND_ADVISORS_INITIAL_RELEASE_PERCENT,
            TEAM_AND_ADVISORS_CLIFF_PERIOD,
            TEAM_AND_ADVISORS_VESTING_PERIOD,
            TEAM_AND_ADVISORS_NO_OF_VESTINGS
        );

        _addRound(
            RoundType.SEED,
            (toonTotalSupply * SEED_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            SEED_PRICE,
            SEED_INITIAL_RELEASE_PERCENT,
            SEED_LISTING_RELEASE_PERCENT,
            SEED_LISTING_PERIOD,
            SEED_CLIFF_PERIOD,
            SEED_VESTING_PERIOD,
            SEED_NO_OF_VESTINGS
        );

        _addRound(
            RoundType.PRIVATE,
            (toonTotalSupply * PRIVATE_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            PRIVATE_PRICE,
            PRIVATE_INITIAL_RELEASE_PERCENT,
            PRIVATE_LISTING_RELEASE_PERCENT,
            PRIVATE_LISTING_PERIOD,
            PRIVATE_CLIFF_PERIOD,
            PRIVATE_VESTING_PERIOD,
            PRIVATE_NO_OF_VESTINGS
        );

        _addRound(
            RoundType.STRATEGIC,
            (toonTotalSupply * STRATEGIC_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            STRATEGIC_PRICE,
            STRATEGIC_INITIAL_RELEASE_PERCENT,
            STRATEGIC_LISTING_RELEASE_PERCENT,
            STRATEGIC_LISTING_PERIOD,
            STRATEGIC_CLIFF_PERIOD,
            STRATEGIC_VESTING_PERIOD,
            STRATEGIC_NO_OF_VESTINGS
        );

        _addRound(
            RoundType.PUBLIC,
            (toonTotalSupply * PUBLIC_SUPPLY_PERCENT) / PERCENTAGE_MULTIPLIER,
            PUBLIC_PRICE,
            PUBLIC_INITIAL_RELEASE_PERCENT,
            PUBLIC_LISTING_RELEASE_PERCENT,
            PUBLIC_LISTING_PERIOD,
            PUBLIC_CLIFF_PERIOD,
            PUBLIC_VESTING_PERIOD,
            PUBLIC_NO_OF_VESTINGS
        );
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /**
     * @notice update start time tge
     * @param _startAfter time after which u want to start (cant be 0);
     * @dev can only be updated before the start
     * @dev if _startAfter = 0, start immediately
     */
    function startOrUpdateStartTime(uint256 _startAfter) external override onlyOwner {
        require(startTime == 0 || block.timestamp < startTime, "Already started");

        uint256 _startTime = block.timestamp + _startAfter;

        _massUpdateCliffEndTime(_startTime);

        startTime = _startTime;

        emit StartVesting(_startTime);
    }

    /**
     * @notice add, update or remove single investor
     * @param _amount for how much amount (in $) has investor invested. ex  100$ = 100 * 100 = 100,00
     * @dev to remove make amount 0 before it starts
     * @dev you can add, updated and remove any time
     */
    function addOrUpdateInvestor(
        RoundType _roundType,
        address _investor,
        uint256 _amount
    ) external override onlyOwner {
        _addInvestor(_roundType, _investor, _amount);

        emit InvestorAdded(_roundType, _investor, _amount);
    }

    /**
     * @notice add, update or remove multiples investors
     */
    function addOrUpdateInvestors(
        RoundType[] memory _roundType,
        address[] memory _investors,
        uint256[] memory _amount
    ) external override onlyOwner {
        uint256 length = _roundType.length;

        require(_investors.length == length && _amount.length == length, "Arguments length not match");

        for (uint256 i = 0; i < length; i++) {
            _addInvestor(_roundType[i], _investors[i], _amount[i]);
        }

        emit InvestorsAdded(_roundType, _investors, _amount);
    }

    /**
     * @notice recover any erc20 token (ex - toon token)
     */
    function recoverToken(address _token, uint256 amount) external override onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }

    /* ========== TEAM FUNCTIONS ========== */

    /**
     * @notice claim unlocked tokens (only team)
     */
    function claimTeamUnlockedTokens(TeamType _teamType) external override started {
        TeamInfo memory _teamInfo = teamInfo[_teamType];

        require(_msgSender() == _teamInfo.beneficiary, "Caller is not authorized");
        require(_teamInfo.vestingsClaimed < _teamInfo.noOfVestings, "Already claimed all vesting");

        uint256 unlockedTokens;

        if (block.timestamp >= _teamInfo.cliffEndTime) {
            uint256 claimableVestingLeft;
            (unlockedTokens, claimableVestingLeft) = _getTeamTokensAndVestingLeft(_teamInfo);

            teamInfo[_teamType].vestingsClaimed = _teamInfo.vestingsClaimed + claimableVestingLeft;
        }

        if (!_teamInfo.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((_teamInfo.totalSupply * _teamInfo.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
            teamInfo[_teamType].initialClaimReleased = true;
        }

        require(unlockedTokens > 0, "No unlocked tokens available");

        toonToken.safeTransfer(_msgSender(), unlockedTokens);
        emit TeamTokensClaimed(_teamType, _teamInfo.beneficiary, unlockedTokens);
    }

    /* ========== Investor FUNCTIONS ========== */

    /**
     * @notice claim unlocked tokens (only investor)
     * @param _roundType Id of the round from which u want to withdraw tokens
     */
    function claimInvestorUnlockedTokens(RoundType _roundType) external override onlyInvestor(_roundType) started {
        RoundInfo memory round = roundInfo[_roundType];
        Investor memory investor = investorInfo[_roundType][_msgSender()];

        require(investor.vestingsClaimed < round.noOfVestings, "Already claimed all vesting");

        uint256 unlockedTokens;

        if (block.timestamp >= round.cliffEndTime) {
            uint256 claimableVestingLeft;
            (unlockedTokens, claimableVestingLeft) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);

            investorInfo[_roundType][_msgSender()].vestingsClaimed = investor.vestingsClaimed + claimableVestingLeft;
        }

        if (!investor.listingClaimReleased && block.timestamp >= (startTime + round.listingPeriod)) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.listingReleasePercent) / PERCENTAGE_MULTIPLIER);
            investorInfo[_roundType][_msgSender()].listingClaimReleased = true;
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
            investorInfo[_roundType][_msgSender()].initialClaimReleased = true;
        }

        require(unlockedTokens > 0, "No unlocked tokens available");

        toonToken.safeTransfer(_msgSender(), unlockedTokens);
        emit InvestorTokensClaimed(_roundType, _msgSender(), unlockedTokens);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @param _totalSupply : total supply of toon token for this team
     * @param _initialReleasePercent : tokens to be released at token generation event
     * @param _cliffPeriod : time user have to wait after start to get his/her first vesting
     * @param _vestingPeriod : duration of single vesting (in secs)
     * @param _noOfVestings : total no of vesting will be given
     */
    function _addTeam(
        TeamType _teamType,
        address _beneficiary,
        uint256 _totalSupply,
        uint256 _initialReleasePercent,
        uint256 _cliffPeriod,
        uint256 _vestingPeriod,
        uint256 _noOfVestings
    ) private {
        require(_beneficiary != address(0), "Invalid address");
        if (_vestingPeriod == 0) require(_noOfVestings == 1, "Invalid vesting details");

        TeamInfo memory newTeamInfo;

        newTeamInfo.beneficiary = _beneficiary;
        newTeamInfo.initialReleasePercent = _initialReleasePercent;
        newTeamInfo.cliffPeriod = _cliffPeriod;
        newTeamInfo.vestingPeriod = _vestingPeriod;
        newTeamInfo.noOfVestings = _noOfVestings;

        newTeamInfo.totalSupply = _totalSupply;
        newTeamInfo.vestingTokens =
            (_totalSupply - ((_totalSupply * _initialReleasePercent) / PERCENTAGE_MULTIPLIER)) /
            _noOfVestings;

        teamInfo[_teamType] = newTeamInfo;
    }

    /**
     * @param _totalSupply : total supply of toon token for this round
     * @param _price : price of toon token in $
     * @param _initialReleasePercent : tokens to be released at token generation event
     * @param _listingPeriod : time user have to wait to get his listing amount released
     * @param _cliffPeriod : time user have to wait after start to get his/her first vesting
     * @param _vestingPeriod : duration of single vesting (in secs)
     * @param _noOfVestings : total no of vesting will be given
     */
    function _addRound(
        RoundType _roundType,
        uint256 _totalSupply,
        uint256 _price,
        uint256 _initialReleasePercent,
        uint256 _listingReleasePercent,
        uint256 _listingPeriod,
        uint256 _cliffPeriod,
        uint256 _vestingPeriod,
        uint256 _noOfVestings
    ) private {
        if (_vestingPeriod == 0) require(_noOfVestings == 1, "Invalid vesting details");

        RoundInfo memory newRoundInfo;

        newRoundInfo.price = _price;
        newRoundInfo.totalSupply = _totalSupply;
        newRoundInfo.supplyLeft = _totalSupply;
        newRoundInfo.initialReleasePercent = _initialReleasePercent;
        newRoundInfo.listingReleasePercent = _listingReleasePercent;
        newRoundInfo.listingPeriod = _listingPeriod;
        newRoundInfo.cliffPeriod = _cliffPeriod;
        newRoundInfo.vestingPeriod = _vestingPeriod;
        newRoundInfo.noOfVestings = _noOfVestings;

        roundInfo[_roundType] = newRoundInfo;
    }

    function _massUpdateCliffEndTime(uint256 _startTime) private {
        for (uint256 i = 0; i < 4; i++) {
            roundInfo[RoundType(i)].cliffEndTime =
                _startTime +
                roundInfo[RoundType(i)].listingPeriod +
                roundInfo[RoundType(i)].cliffPeriod;
            if (i < 3) teamInfo[TeamType(i)].cliffEndTime = _startTime + teamInfo[TeamType(i)].cliffPeriod;
        }
    }

    function _addInvestor(
        RoundType _roundType,
        address _investorAddress,
        uint256 _amount
    ) private {
        require(_investorAddress != address(0), "Invalid address");

        RoundInfo memory round = roundInfo[_roundType];
        Investor storage investor = investorInfo[_roundType][_investorAddress];
        uint256 totalAssigned = (_amount * 1e18) / round.price;

        require(round.supplyLeft >= totalAssigned, "Insufficient supply");

        if (investor.totalAssigned == 0) {
            investors[_roundType].push(_investorAddress);
            roundInfo[_roundType].supplyLeft = round.supplyLeft - totalAssigned;
        } else {
            require(
                !investor.initialClaimReleased && !investor.listingClaimReleased,
                "Investor has already started claiming"
            );
            roundInfo[_roundType].supplyLeft = round.supplyLeft + investor.totalAssigned - totalAssigned;
        }
        investor.totalAssigned = totalAssigned;
        investor.vestingTokens =
            (totalAssigned -
                ((totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER) -
                ((totalAssigned * round.listingReleasePercent) / PERCENTAGE_MULTIPLIER)) /
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
        if (_round.vestingPeriod == 0) return _investor.vestingsClaimed == 0 ? (_investor.vestingTokens, 1) : (0, 0);

        uint256 totalClaimableVesting = ((block.timestamp - _round.cliffEndTime) / _round.vestingPeriod) + 1;

        uint256 claimableVestingLeft = totalClaimableVesting > _round.noOfVestings
            ? _round.noOfVestings - _investor.vestingsClaimed
            : totalClaimableVesting - _investor.vestingsClaimed;

        uint256 unlockedTokens = _investor.vestingTokens * claimableVestingLeft;

        return (unlockedTokens, claimableVestingLeft);
    }

    /**
     * @notice Calculate the total vesting claimable vesting left
     * @dev will only run in case if cliff period ends and investor have unclaimed vesting left
     */
    function _getTeamTokensAndVestingLeft(TeamInfo memory _teamInfo) private view returns (uint256, uint256) {
        // if sales is set in such a way after cliff time give all the tokens in one go
        if (_teamInfo.vestingPeriod == 0) return _teamInfo.vestingsClaimed == 0 ? (_teamInfo.vestingTokens, 1) : (0, 0);

        uint256 totalClaimableVesting = ((block.timestamp - _teamInfo.cliffEndTime) / _teamInfo.vestingPeriod) + 1;

        uint256 claimableVestingLeft = totalClaimableVesting > _teamInfo.noOfVestings
            ? _teamInfo.noOfVestings - _teamInfo.vestingsClaimed
            : totalClaimableVesting - _teamInfo.vestingsClaimed;

        uint256 unlockedTokens = _teamInfo.vestingTokens * claimableVestingLeft;

        return (unlockedTokens, claimableVestingLeft);
    }

    /* ========== VIEWS ========== */

    /**
     * @return amount of unlockToken which are currently unclaimed for a investor
     */
    function getInvestorClaimableTokens(RoundType _roundType, address _investor)
        external
        view
        override
        returns (uint256)
    {
        RoundInfo memory round = roundInfo[_roundType];
        Investor memory investor = investorInfo[_roundType][_investor];

        if (startTime == 0 || block.timestamp < startTime || investor.vestingsClaimed == round.noOfVestings) return 0;

        uint256 unlockedTokens;
        if (block.timestamp >= round.cliffEndTime) {
            (unlockedTokens, ) = _getInvestorUnlockedTokensAndVestingLeft(round, investor);
        }

        if (!investor.listingClaimReleased && block.timestamp >= (startTime + round.listingPeriod)) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.listingReleasePercent) / PERCENTAGE_MULTIPLIER);
        }

        if (!investor.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((investor.totalAssigned * round.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
        }

        return unlockedTokens;
    }

    /**
     * @return amount of unlockToken which are currently unclaimed for team
     */
    function getTeamClaimableTokens(TeamType _teamType) external view override returns (uint256) {
        TeamInfo memory _teamInfo = teamInfo[_teamType];

        if (startTime == 0 || block.timestamp < startTime || _teamInfo.vestingsClaimed == _teamInfo.noOfVestings)
            return 0;

        uint256 unlockedTokens;
        if (block.timestamp >= _teamInfo.cliffEndTime) {
            (unlockedTokens, ) = _getTeamTokensAndVestingLeft(_teamInfo);
        }

        if (!_teamInfo.initialClaimReleased) {
            unlockedTokens =
                unlockedTokens +
                ((_teamInfo.totalSupply * _teamInfo.initialReleasePercent) / PERCENTAGE_MULTIPLIER);
        }

        return unlockedTokens;
    }

    /**
     * @return array containing investors of a particular round
     * filter in frontend ot get all the investor (totalAssigned != 0)
     */
    function getInvestors(RoundType _roundType) external view override returns (address[] memory) {
        return investors[_roundType];
    }

    /* ========== MODIFIERS ========== */

    modifier started() {
        require(startTime != 0 && block.timestamp > startTime, "Not started yet");
        _;
    }

    modifier onlyInvestor(RoundType _roundType) {
        require(investorInfo[_roundType][_msgSender()].totalAssigned > 0, "Caller is not a investor");
        _;
    }
}
