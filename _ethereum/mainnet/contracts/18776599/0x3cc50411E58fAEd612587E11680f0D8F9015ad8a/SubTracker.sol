// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title User Deposit, Owner and Partner Withdrawal Contract with Username Clearing
/// @author 5thWeb.io
/// @notice This contract allows users to deposit Ethereum and record their username.
contract SubTracker {

    error NoZeros();
    error IncorrectPayment();

    address private partnerAddress;
    address private partnerAddress1;
    address[] public userAddresses;  // Array to keep track of all addresses

    struct User {
        string username;
        uint256 deposit;
        uint256 timestamp;
        uint256 tier;
        uint256 subscriptionEnd;
    }

    mapping(address => User) public users;

    struct Tier {
        uint256 dailyPayment;
        uint256 oneWeekPayment;
        uint256 oneMonthPayment;
    }

    mapping(uint256 => Tier) public tiers;
    mapping(uint256 => uint256) public tierUserCounts;
    mapping(uint256 => uint256) public tierMaxCounts;

    event Deposited(address indexed user, uint256 amount, string username, uint256 timestamp);
    event Withdrawn(uint256 partnerAmount1, uint256 partnerAmount);
    event UsernameCleared(address indexed user);
    event PaymentAmountsUpdated(uint256 tier, uint256 newDailyPayment, uint256 newOneWeekPayment, uint256 newOneMonthPayment);

    constructor() {
        partnerAddress1 = msg.sender;
        partnerAddress = address(0xA9740DB88d870B42919E9410b61Cd0d528395049);

        tiers[1] = Tier(0.03 ether, 0.15 ether, 0.5 ether);
        tiers[2] = Tier(0.05 ether, 0.25 ether, 0.8 ether);
        tierMaxCounts[1] = 25;
        tierMaxCounts[2] = 25;
    }

    modifier onlyOwner() {
        require(msg.sender == partnerAddress1 || msg.sender == partnerAddress, "Only the owner can perform this action");
        _;
    }

    function setPaymentAmounts(uint256 _tier, uint256 newDailyPayment, uint256 newOneWeekPayment, uint256 newOneMonthPayment) external onlyOwner {
        if (newDailyPayment == 0 || newOneWeekPayment == 0 || newOneMonthPayment == 0) {
            revert NoZeros();
        }
        tiers[_tier] = Tier(newDailyPayment, newOneWeekPayment, newOneMonthPayment);
        emit PaymentAmountsUpdated(_tier, newDailyPayment, newOneWeekPayment, newOneMonthPayment);
    }

    function setMaxUsersForTier(uint256 _tier, uint256 _maxUsers) external onlyOwner {
        tierMaxCounts[_tier] = _maxUsers;
    }

    /**
     * @dev User deposits native, records username, days, and tier
     * @param _username The telegram username of the depositor
     * @param _days The number of days the depositor is subscribing for
     * @param _tier The tier of the depositor
     */
    function deposit(string memory _username, uint256 _days, uint256 _tier) external payable {
        require(_days >= 3, "Minimum subscription period is 3 days");
        require(tiers[_tier].dailyPayment > 0, "Invalid tier");
        require(tierUserCounts[_tier] < tierMaxCounts[_tier], "Maximum number of users for this tier reached");

        uint256 requiredPayment;
        if (_days == 7) {
            requiredPayment = tiers[_tier].oneWeekPayment;
        } else if (_days == 30) {
            requiredPayment = tiers[_tier].oneMonthPayment;
        } else {
            requiredPayment = tiers[_tier].dailyPayment * _days;
        }
        require(msg.value == requiredPayment, "Incorrect payment amount");

        if (users[msg.sender].deposit == 0) {
            userAddresses.push(msg.sender);
        }

        users[msg.sender] = User(_username, msg.value, block.timestamp, _tier, block.timestamp + _days * 1 days);
        tierUserCounts[_tier]++;

        emit Deposited(msg.sender, msg.value, _username, block.timestamp);
    }

    function clearUser(address userAddress) internal {
        User memory user = users[userAddress];
        if (block.timestamp > user.subscriptionEnd) {
            tierUserCounts[user.tier]--;
            delete users[userAddress];
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoZeros();
        }

        for (uint i = 0; i < userAddresses.length; i++) {
            clearUser(userAddresses[i]);
        }

        uint256 halfBalance = balance / 2;
        payable(partnerAddress1).transfer(halfBalance);
        payable(partnerAddress).transfer(halfBalance);

        emit Withdrawn(halfBalance, halfBalance);
    }

    // Function to get all user data
    function getAllUsers() external view returns (address[] memory, string[] memory, uint256[] memory, uint256[] memory) {
        string[] memory allUsernames = new string[](userAddresses.length);
        uint256[] memory allDeposits = new uint256[](userAddresses.length);
        uint256[] memory allTimestamps = new uint256[](userAddresses.length);

        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            allUsernames[i] = users[userAddress].username;
            allDeposits[i] = users[userAddress].deposit;
            allTimestamps[i] = users[userAddress].timestamp;
        }

        return (
            userAddresses, 
            allUsernames, 
            allDeposits, 
            allTimestamps);
    }

    function getActiveSubscriptions(uint256 _tier) external view returns (address[] memory, string[] memory, uint256[] memory, uint256[] memory) {
        uint256 activeCount = 0;
        for (uint i = 0; i < userAddresses.length; ++i) {
            User memory user = users[userAddresses[i]];
            if (user.tier == _tier && block.timestamp <= user.subscriptionEnd) {
                activeCount++;
            }
        }

        address[] memory activeAddresses = new address[](activeCount);
        string[] memory activeUsernames = new string[](activeCount);
        uint256[] memory activeDeposits = new uint256[](activeCount);
        uint256[] memory activeTimestamps = new uint256[](activeCount);

        uint256 j = 0;
        for (uint i = 0; i < userAddresses.length; ++i) {
            User memory user = users[userAddresses[i]];
            if (user.tier == _tier && block.timestamp <= user.subscriptionEnd) {
                activeAddresses[j] = userAddresses[i];
                activeUsernames[j] = user.username;
                activeDeposits[j] = user.deposit;
                activeTimestamps[j] = user.timestamp;
                j++;
            }
        }

        return (
            activeAddresses, 
            activeUsernames, 
            activeDeposits, 
            activeTimestamps
        );
    }

    function getUserTier(address userAddress) external view returns (uint256) {
        return users[userAddress].tier;
    }
}