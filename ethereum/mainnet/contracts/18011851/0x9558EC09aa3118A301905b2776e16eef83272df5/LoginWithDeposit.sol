// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title LoginWithDeposit
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract LoginWithDeposit {
    address public owner;
    uint256 public totalBalance;
    uint256 public cap;

    uint256 public winnerPercent;

    mapping(string => bool) public registered;
    mapping(string => uint256) public deposits;

    event Deposited(string userID, uint256 amount);
    event Ended(
        address winner,
        string userID,
        uint256 winnerShare,
        address owner,
        uint256 ownerShare
    );
    event ContractInitialized(uint256 cap1, uint256 winnerPercent1);

    constructor(uint256 cap1, uint256 winnerPercent1) {
        require(winnerPercent <= 100, "Winner Percent must be less than 100%");

        owner = msg.sender;
        cap = cap1;
        winnerPercent = winnerPercent1;

        emit ContractInitialized(cap1, winnerPercent1);
    }

    function deposit(string memory userID) public payable {
        require(!registered[userID], "User ID already registered");
        require(msg.value == cap, "Deposit amount does not match the cap");

        registered[userID] = true;
        deposits[userID] = msg.value;

        totalBalance = address(this).balance;

        emit Deposited(userID, msg.value);
    }

    function query(string memory userID) public view returns (bool) {
        return registered[userID];
    }

    function end(address payable winner, string memory userID) public {
        require(msg.sender == owner, "Only owner can end the contract");
        require(registered[userID], "Winner user ID is not registered");

        address payable ownerAddress = payable(owner);

        uint256 total = address(this).balance;
        uint256 winnerShare = (total * winnerPercent) / 100;
        uint256 ownerShare = total - winnerShare;

        winner.transfer(winnerShare);
        ownerAddress.transfer(ownerShare);

        totalBalance = 0;

        emit Ended(winner, userID, winnerShare, owner, ownerShare);
    }
}