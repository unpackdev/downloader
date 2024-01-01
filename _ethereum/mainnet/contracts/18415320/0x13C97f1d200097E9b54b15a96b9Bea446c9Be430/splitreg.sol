// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title User Deposit, Owner and Partner Withdrawal Contract with Username Clearing
/// @author 5thWeb.io
/// @notice This contract allows users to deposit Ethereum and record their username.
contract SubTracker {

    error NoZeros();
    error IncorrectPayment();

    address private partnerAddress;
    address private partnerAddress1;
    address[] public userAddresses;  // Array to keep track of all addresses
    mapping(address => string) public usernames;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public timestamp;
    uint256 public oneWeekPayment = 0.15 ether;
    uint256 public oneMonthPayment = 0.5 ether;

    event Deposited(address indexed user, uint256 amount, string username, uint256 timestamp);
    event Withdrawn(uint256 partnerAmount1, uint256 partnerAmount);
    event UsernameCleared(address indexed user);
    event PaymentAmountsUpdated(uint256 newOneWeekPayment, uint256 newOneMonthPayment);

    constructor(address _partnerAddress1, address _partnerAddress) {
        if (_partnerAddress1 == address(0) || _partnerAddress == address(0)) {
            revert NoZeros();
        }
        partnerAddress1 = _partnerAddress1;
        partnerAddress = _partnerAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == partnerAddress1 || msg.sender == partnerAddress, "Only the owner can perform this action");
        _;
    }

    function setPaymentAmounts(uint256 newOneWeekPayment, uint256 newOneMonthPayment) external onlyOwner {
        if (newOneWeekPayment == 0 || newOneMonthPayment == 0) {
            revert NoZeros();
        }
        oneWeekPayment = newOneWeekPayment;
        oneMonthPayment = newOneMonthPayment;
        emit PaymentAmountsUpdated(newOneWeekPayment, newOneMonthPayment);
    }

    function deposit(string memory _username) external payable {
        if (msg.sender == address(0)) {
            revert NoZeros();
        }
        if (msg.value != oneWeekPayment && msg.value != oneMonthPayment) {
            revert IncorrectPayment();
        }

        if (deposits[msg.sender] == 0) {
            userAddresses.push(msg.sender);
        }

        usernames[msg.sender] = _username;
        deposits[msg.sender] += msg.value;
        timestamp[msg.sender] = block.timestamp;

        emit Deposited(msg.sender, msg.value, _username, block.timestamp);
    }

    function ownerAddPayer(address paidAddress, string memory _username, uint256 paidValue, uint256 _timestamp) external onlyOwner {
        if (deposits[paidAddress] == 0) {
            userAddresses.push(paidAddress);
        }
        
        usernames[paidAddress] = _username;
        deposits[paidAddress] += paidValue;
        timestamp[paidAddress] = _timestamp;

        emit Deposited(paidAddress, paidValue, _username, _timestamp);
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoZeros();
        }

        uint256 halfBalance = balance / 2;
        payable(partnerAddress1).transfer(halfBalance);
        payable(partnerAddress).transfer(halfBalance);

        emit Withdrawn(halfBalance, halfBalance);
    }

    function clearUsername(address userAddress) external onlyOwner {
        if (bytes(usernames[userAddress]).length == 0) {
            revert NoZeros();
        }

        delete usernames[userAddress];

        emit UsernameCleared(userAddress);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to get all user data
    function getAllUsers() external view returns (address[] memory, string[] memory, uint256[] memory, uint256[] memory) {
        string[] memory allUsernames = new string[](userAddresses.length);
        uint256[] memory allDeposits = new uint256[](userAddresses.length);
        uint256[] memory allTimestamps = new uint256[](userAddresses.length);

        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            allUsernames[i] = usernames[userAddress];
            allDeposits[i] = deposits[userAddress];
            allTimestamps[i] = timestamp[userAddress];
        }

        return (userAddresses, allUsernames, allDeposits, allTimestamps);
    }
}
