// SPDX-License-Identifier: UNLICENSED
import "./IERC20Upgradeable.sol";
import "./Math.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";

pragma solidity ^0.8.4;

/**
 * @title ERC20 Claiming Vesting Vault for holders
 * @dev This vault is a claiming contract that allows users to register for
 * token vesting based on ETH sent into the vault.
 */
contract PresaleVault is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // ERC20 token being held by this contract
    IERC20Upgradeable public token;
    uint256 public tokensPerWei;

    uint256 public intervalDuration; // ie once a day, once a week etc where balances change.
    uint256 public totalIntervals; // ie total number of intervals AFTER initial claim;
    uint256 public initialIntervalsClaimed; // ie how many intervals to release immediately;

    uint256 public totalRegisteredTokens; // How many tokens have already been registered for.
    uint256 public totalTransferredOut; // total amount claimed and transferred

    uint256 public vestingStarted; // Added to track whether vesting has started

    mapping(address => bool) public isBlacklisted;

    mapping(address => uint256) public userPregisteredAmount;

    struct UserInfo {
        uint256 totalTokens;
        uint256 intervalsClaimed;
        uint256 claimStart;
    }

    mapping(address => UserInfo) public users;

    receive() external payable {}

    function initialize(
        address _vestingToken
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(_vestingToken);
        initialIntervalsClaimed = 3;
        totalIntervals = 10;
        intervalDuration = 172800; // 2 days
        vestingStarted = 0; // Initialize vesting as not started
    }

    /***********************/
    /***********************/
    /*** ADMIN FUNCTIONS ***/
    /***********************/
    /***********************/
    function setToken(address _tokenAddr) external onlyOwner {
        token = IERC20Upgradeable(_tokenAddr);
    }

    function blacklistUser(address blacklistedAddress) public onlyOwner {
        isBlacklisted[blacklistedAddress] = true;
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

    function setVestingStarted() public onlyOwner {
        require(vestingStarted == 0, "Vesting has already started");

        // Calculate tokens per ETH based on the ETH collected at vesting start time
        uint256 totalRegisteredETH = address(this).balance;
        uint256 totalRegisteredTokens = token.balanceOf(address(this));
        tokensPerWei = totalRegisteredTokens / totalRegisteredETH;

        vestingStarted = block.timestamp; // Mark vesting as started
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
        require(!isBlacklisted[msg.sender], "Blacklisted");
        UserInfo memory user = users[msg.sender];
        (
            uint256 totalClaimableThisRound,
            uint256 intervalsElapsed
        ) = totalClaimable(msg.sender);

        require(vestingStarted > 0, "Vesting has not started yet");
        require(
            user.intervalsClaimed > 0 || userPregisteredAmount[msg.sender] > 0,
            "Address not registered"
        );

        if (userPregisteredAmount[msg.sender] > 0) {
            // First claim - initialize user.
            user = UserInfo({
                totalTokens: userPregisteredAmount[msg.sender] * tokensPerWei,
                intervalsClaimed: 0,
                claimStart: vestingStarted
            });
            userPregisteredAmount[msg.sender] = 0;

            totalClaimableThisRound =
                (intervalsElapsed * user.totalTokens) /
                totalIntervals;
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
        require(
            vestingStarted == 0,
            "Registrations are closed because vesting has started"
        );

        require(msg.value == amount);

        userPregisteredAmount[msg.sender] += amount;
        totalRegisteredTokens += amount;
    }

    /***********************/
    /***********************/
    /*** VIEW FUNCTIONS ***/
    /***********************/
    /***********************/

    function totalClaimable(
        address userAddress
    )
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

    function nextClaimTime(
        address userAddress
    ) public view returns (uint256 timestamp) {
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

    function _intervalsElapsed(
        uint256 startTime
    ) internal view returns (uint256 intervalsElapsed) {
        intervalsElapsed = ((block.timestamp - startTime) / intervalDuration);
    }

    function _claimableIntervals(
        uint256 startTime,
        UserInfo memory user
    ) internal view returns (uint256 claimableIntervals) {
        uint256 maxIntervalsClaimable = _maxIntervalsClaimable(); // 14

        // calculate claimable intervals no max.
        claimableIntervals =
            _intervalsElapsed(
                user.claimStart == 0 ? vestingStarted : user.claimStart
            ) +
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
