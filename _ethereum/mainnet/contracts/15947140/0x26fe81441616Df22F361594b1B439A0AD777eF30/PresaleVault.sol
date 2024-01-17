// SPDX-License-Identifier: UNLICENSED
import "./IERC20Upgradeable.sol";
import "./Math.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";

pragma solidity ^0.8.4;

/**
    IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at 
    https://highstack.co in a contractor capacity.
    
    Highstack is not responsible for any malicious use or losses arising from using 
    or interacting with this smart contract.
**/

/**
 * @title ERC20 Claiming Vesting Vault for holders
 * @dev This vault is a claiming contract that allows users to register for
 * token vesting based on ETH sent into the vault.
 */

contract PresaleVault is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // ERC20 token being held by this contract
    IERC20Upgradeable public token;

    uint256 public tokensPerWei; // price expressed in wei.
    uint256 public openTime; // Time that registrations open
    uint256 public closeTime; // Time that registrations close
    uint256 public intervalDuration; // ie once a day, once a week etc where balances change.
    uint256 public totalIntervals; // ie total number of intervals AFTER initial claim;
    uint256 public initialIntervalsClaimed; // ie how many intervals to release immediately.

    uint256 public totalPresaleTokens; // total presale tokens up for grabs.
    uint256 public totalRegisteredTokens; // How many tokens have already been registerd for.
    uint256 public maxAllocPerUser; // max amount users can register for.
    uint256 public totalTransferredOut; // total amount claimed and transferred

    bool public globalVestingStarted;

    mapping(address => uint256) public userPregisteredAmount;

    struct UserInfo {
        uint256 totalTokens;
        uint256 intervalsClaimed;
        uint256 claimStart;
    }

    mapping(address => UserInfo) public users;

    receive() external payable {}

    function initialize(
        address _vestingToken,
        uint256 _tokensPerWei,
        uint256 _openTime
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(_vestingToken);
        tokensPerWei = _tokensPerWei;
        openTime = _openTime;
        initialIntervalsClaimed = 6;
        totalIntervals = 20;
        intervalDuration = 129600;
    }

    /***********************/
    /***********************/
    /*** ADMIN FUNCTIONS ***/
    /***********************/
    /***********************/
    function setToken(address _tokenAddr) external onlyOwner {
        token = IERC20Upgradeable(_tokenAddr);
    }

    function setPrice(uint256 price) external onlyOwner {
        tokensPerWei = price;
    }

    function setTime(uint256 _openTime, uint256 _closeTime) external onlyOwner {
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function blacklistUser(address blacklistedAddress) public onlyOwner {
        // sets users token balance to zero but marks them as registered.
        // so future claims are all zero.
        users[blacklistedAddress] = UserInfo({
            totalTokens: 0,
            intervalsClaimed: 1,
            claimStart: block.timestamp
        });
    }

    function setVestingVariables(
        uint256 _intervalDuration,
        uint256 _totalIntervals,
        uint256 _initialIntervalsClaimed
    ) public onlyOwner {
        intervalDuration = _intervalDuration;
        totalIntervals = _totalIntervals;
        initialIntervalsClaimed = _initialIntervalsClaimed;
    }

    function setGlobalVestingStarted(bool _globalVestingStarted)
        public
        onlyOwner
    {
        globalVestingStarted = _globalVestingStarted;
    }

    function markContractFunded(uint256 _maxAllocPerUser) public onlyOwner {
        // HANDLE SETTING AUTO VARIABLES
        uint256 tokBalance = token.balanceOf(address(this));
        uint256 increase = tokBalance +
            totalTransferredOut -
            totalPresaleTokens;

        totalPresaleTokens = totalPresaleTokens + increase;

        // HANDLE USER ALLOCATIONS
        require(
            _maxAllocPerUser <= tokBalance,
            "Cannot set allocation to more than current balance"
        );
        maxAllocPerUser = _maxAllocPerUser;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /***********************/
    /***********************/
    /*** PUBLIC FUNCTIONS **/
    /***********************/
    /***********************/

    function claim() public nonReentrant {
        UserInfo memory user = users[msg.sender];
        (
            uint256 totalClaimableThisRound,
            uint256 intervalsElapsed
        ) = totalClaimable(msg.sender);

        require(globalVestingStarted, "Vesting has not started yet");
        require(
            user.intervalsClaimed > 0 || userPregisteredAmount[msg.sender] > 0,
            "Address not registered"
        );

        if (userPregisteredAmount[msg.sender] > 0) {
            // First claim - initialize user.
            user = UserInfo({
                totalTokens: userPregisteredAmount[msg.sender],
                intervalsClaimed: 0,
                claimStart: block.timestamp
            });
            userPregisteredAmount[msg.sender] = 0;

            totalClaimableThisRound =
                (initialIntervalsClaimed * user.totalTokens) /
                totalIntervals;
            intervalsElapsed = initialIntervalsClaimed;
        }
        
        require(
            totalIntervals - user.intervalsClaimed > 0,
            "All tokens fully vested and claimed"
        );
        require(totalClaimableThisRound > 0, "Nothing to claim");

        user.intervalsClaimed += intervalsElapsed;
        users[msg.sender] = user;

        totalTransferredOut += totalClaimableThisRound;
        token.transfer(msg.sender, totalClaimableThisRound);
    }

    function presaleRegister(uint256 amount) public payable nonReentrant {
        require(amount <= msg.value * tokensPerWei, "Value below price");
        require(block.timestamp > openTime, "Registrations not open");
        require(block.timestamp < closeTime, "Registrations window passed");
        require(totalPresaleTokens > 0, "Admin has not funded vault yet");
        require(amount <= maxAllocPerUser, "Allocation exceeded");
        require(users[msg.sender].intervalsClaimed == 0, "Already Registered!");
        require(userPregisteredAmount[msg.sender] == 0, "Already Registered!");
        require(
            totalPresaleTokens - totalRegisteredTokens > amount,
            "Not enough tokens remaining"
        );
        
        userPregisteredAmount[msg.sender] = amount;
        totalRegisteredTokens += amount;
    }

    /***********************/
    /***********************/
    /*** VIEW FUNCTIONS ***/
    /***********************/
    /***********************/

    function totalClaimable(address userAddress)
        public
        view
        returns (uint256 totalClaimableThisRound, uint256 claimableIntervals)
    {
        UserInfo memory user = users[userAddress];

        uint256 initialClaimAmount = (user.totalTokens *
            initialIntervalsClaimed) / totalIntervals;

        uint256 amountPerInterval = user.totalTokens / totalIntervals;

        claimableIntervals = _claimableIntervals(user.claimStart, user);

        totalClaimableThisRound = amountPerInterval * claimableIntervals;
    }

    function nextClaimTime(address userAddress)
        public
        view
        returns (uint256 timestamp)
    {
        UserInfo memory user = users[userAddress];

        uint256 intervalsElapsed = _intervalsElapsed(user.claimStart);
        // we want elabsed intervals

        if (
            (intervalsElapsed) >= _maxIntervalsClaimable() ||
            user.totalTokens == 0
        ) {
            timestamp = 0;
        } else {
            timestamp =
                user.claimStart +
                ((intervalsElapsed + 1) * intervalDuration);
        }
    }

    /***********************/
    /***********************/
    /** HELPER FUNCTIONS ***/
    /***********************/
    /***********************/

    function _intervalsElapsed(uint256 startTime)
        internal
        view
        returns (uint256 intervalsElapsed)
    {
        intervalsElapsed = ((block.timestamp - startTime) / intervalDuration);
    }

    function _claimableIntervals(uint256 startTime, UserInfo memory user)
        internal
        view
        returns (uint256 claimableIntervals)
    {
        uint256 maxIntervalsClaimable = _maxIntervalsClaimable(); // 14

        // calculate claimable intervals no max.
        claimableIntervals =
            _intervalsElapsed(user.claimStart) +
            initialIntervalsClaimed -
            user.intervalsClaimed;

        // set max of claimable intervals vs max claimable intervals
        claimableIntervals = Math.min(
            claimableIntervals,
            totalIntervals - user.intervalsClaimed
        );
    }

    function _maxIntervalsClaimable()
        internal
        view
        returns (uint256 maxIntervalsClaimable)
    {
        maxIntervalsClaimable = totalIntervals - initialIntervalsClaimed;
    }
}
