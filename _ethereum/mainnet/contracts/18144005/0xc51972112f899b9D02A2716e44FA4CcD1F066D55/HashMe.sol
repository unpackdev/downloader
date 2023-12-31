//   ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣾⣿⣿⣿⣿⣷⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
//   ⠀⠀⠀⠀⠀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀
//   ⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀
//   ⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⠟⠿⠿⡿⠀⢰⣿⠁⢈⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀
//   ⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣤⣄⠀⠀⠀⠈⠉⠀⠸⠿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀
//   ⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⢠⣶⣶⣤⡀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⡆
//   ⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠼⣿⣿⡿⠃⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣷
//   ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⢀⣀⣀⠀⠀⠀⠀⢴⣿⣿⣿⣿⣿⣿⣿⣿⣿
//   ⢿⣿⣿⣿⣿⣿⣿⣿⢿⣿⠁⠀⠀⣼⣿⣿⣿⣦⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⡿
//   ⠸⣿⣿⣿⣿⣿⣿⣏⠀⠀⠀⠀⠀⠛⠛⠿⠟⠋⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⠇
//   ⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⣤⡄⠀⣀⣀⣀⣀⣠⣾⣿⣿⣿⣿⣿⣿⣿⡟⠀
//   ⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣄⣰⣿⠁⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀
//    ⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀
//   ⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀
//   ⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⠿⢿⣿⣿⣿⣿⡿⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀
//
// Built By MagicByt3 - BitcoinTalk.org 
// MagicHash: Unite to Rent Hashpower and Mine Bitcoin Blocks Collectively
// 
// Pool your Ethereum to collectively rent hashpower aimed at solving Bitcoin blocks.
// Be part of a community-driven mining operation while maintaining transparency and trust.
// Each round has a predefined maximum limit and deposit size. Once the pool is full, the
// collected Ethereum is used to rent hashpower, targeting the hardcoded Bitcoin mining address.
// Block details are recorded for verification, and users specify their BTC payout addresses at time of deposit.
// Mining is conducted on the CKSolo pool https://solo.ckpool.org/ * This project is not operated in any way by the pool!
// Mining can be tracked at the following URL https://solo.ckpool.org/users/bc1qy7xdv25rv5ejkh4vkv4m8x7ctyzagma62ef0eh
// SPDX-License-Identifier: MIT - MagicByt3 2023
pragma solidity ^0.8.18;

// MagicHash Smart Contract
contract MagicHash {
    
    // State variables
    address public owner;  // Contract owner's address
    string public miningBTCAddress;  // Hardcoded BTC mining address
    
    // Struct to store user's deposited information
    struct UserInfo {
        uint256 ethDeposited;  // Amount of ETH deposited
        string btcPayoutAddress;  // User's BTC payout address
    }

    // Struct to store information about a found block
    struct BlockFoundInfo {
        string ipfsHash;  // IPFS hash containing additional info
        string transactionID;  // Transaction ID of the found block
        string blockHeight;  // Height of the found block
        string payoutAddress;  // BTC address for the mining reward
        uint256 timestamp;  // Timestamp when the block was found
        string blockHash;  // Hash of the found block
    }

    // Struct to store round information
    struct RoundInfo {
        uint256 maxLimit;  // Maximum limit of ETH for the round
        uint256 depositSize;  // Required deposit size for the round
        uint256 currentTotal;  // Current total ETH deposited in the round
        bool isComplete;  // Whether the round is complete
    }

    // Mappings and Arrays
    mapping(address => UserInfo) public userInfo;  // Mapping of user to their info
    BlockFoundInfo[] public blockFoundDetails;  // Array to store found block details
    RoundInfo[] public rounds;  // Array to store round details
    mapping(uint256 => address[]) public roundDepositors;  // Mapping of round to its depositors

    // Track the current round
    uint256 public currentRound;

    // Events
    event Deposited(address indexed user, uint256 amount, string btcPayoutAddress);
    event WithdrawnByOwner(uint256 amount);
    event BlockFound(string ipfsHash);
    event NewRoundConfigured(uint256 maxLimit, uint256 depositSize);
    event Refunded(address indexed user, uint256 amount);

    // Constructor to initialize contract
    constructor() {
        owner = msg.sender;
        miningBTCAddress = "bc1qy7xdv25rv5ejkh4vkv4m8x7ctyzagma62ef0eh";

        // Initialize the first round
        RoundInfo memory initialRound = RoundInfo({
            maxLimit: 1 ether,
            depositSize: 0.1 ether,
            currentTotal: 0,
            isComplete: false
        });
        rounds.push(initialRound);
        currentRound = 0;
    }

    // Modifier to restrict function to only owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Function for users to deposit ETH
    function deposit(string memory btcPayoutAddress) public payable {
        require(!rounds[currentRound].isComplete, "Round is complete");
        require(msg.value == rounds[currentRound].depositSize, "Must deposit in specified size for the round");

        uint256 newTotal = rounds[currentRound].currentTotal + msg.value;
        require(newTotal <= rounds[currentRound].maxLimit, "Exceeds maximum limit for the round");

        userInfo[msg.sender].ethDeposited += msg.value;
        userInfo[msg.sender].btcPayoutAddress = btcPayoutAddress;

        rounds[currentRound].currentTotal = newTotal;

        roundDepositors[currentRound].push(msg.sender);

        emit Deposited(msg.sender, msg.value, btcPayoutAddress);
    }

    // Function for the owner to configure a new round
    function configureNewRound(uint256 maxLimit, uint256 depositSize) public onlyOwner {
        RoundInfo memory newRound = RoundInfo({
            maxLimit: maxLimit,
            depositSize: depositSize,
            currentTotal: 0,
            isComplete: false
        });
        rounds.push(newRound);
        currentRound++;

        emit NewRoundConfigured(maxLimit, depositSize);
    }

    // Function for the owner to complete a round and withdraw funds to Nicehash to start the round
    function completeRound() public onlyOwner {
        require(!rounds[currentRound].isComplete, "Round already complete");
        require(rounds[currentRound].currentTotal == rounds[currentRound].maxLimit, "Round limit not reached");

        uint256 amountToWithdraw = rounds[currentRound].currentTotal;

        rounds[currentRound].currentTotal = 0;
        rounds[currentRound].isComplete = true;

        address payable niceHashAddress = payable(0x836049EAfA2B0CD48DFBc2114eD21Ff346270986);
        niceHashAddress.transfer(amountToWithdraw);

        emit WithdrawnByOwner(amountToWithdraw);
    }

    // Function for the owner to add details of a found block
    function addBlockFoundDetails(string memory ipfsHash, string memory transactionID, string memory blockHeight, string memory payoutAddress, uint256 timestamp, string memory blockHash) public onlyOwner {
        BlockFoundInfo memory newBlockFound = BlockFoundInfo({
            ipfsHash: ipfsHash,
            transactionID: transactionID,
            blockHeight: blockHeight,
            payoutAddress: payoutAddress,
            timestamp: timestamp,
            blockHash: blockHash
        });

        blockFoundDetails.push(newBlockFound);

        emit BlockFound(ipfsHash);
    }

    // Function to refund users if a round did not reach its target
    function refundUsers() public onlyOwner {
        require(!rounds[currentRound].isComplete, "Round already complete");

        for (uint256 i = 0; i < roundDepositors[currentRound].length; i++) {
            address user = roundDepositors[currentRound][i];
            uint256 refundAmount = userInfo[user].ethDeposited;

            payable(user).transfer(refundAmount);

            emit Refunded(user, refundAmount);
        }
    }
}