// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HouseMoneyRevShareContract {
    uint256 immutable public HOUSE_REVENUE_AMOUNT;
    address public owner;
    uint256 public totalSnapshotTokens;
    uint256 public snapshotTime;
    bool public isSnapshotLocked;
    bool public isFreezed; 

    mapping(address => uint256) public snapshotBalances;
    mapping(address => bool) public hasClaimed;

    event HouseMoneySnapshotLock();
    event Freeze();
    event EthClaim(address indexed claimer, uint256 amount);
    event AdminWithdraw(uint256 amount);

    constructor () payable {
        owner = msg.sender;
        HOUSE_REVENUE_AMOUNT = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
//  
    modifier after3Days() {
        require(block.timestamp > snapshotTime +  3 days, "Can withdraw unclaimed ETH after 3 days");
        _;
    }

    function uploadSnapshot(address[] calldata users, uint256[] calldata balances) external onlyOwner {
        require(users.length == balances.length, "Addresses and balances length must be equal");
        // require(users.length <= 125, "Can only upload up to 125 addresses at a time");

        // note: should not have more than one user value
        for (uint256 i = 0; i < users.length; i++) {
            snapshotBalances[users[i]] += balances[i];
            totalSnapshotTokens += balances[i];
        }
    }

    function lockSnapshot() external onlyOwner {
        require(!isSnapshotLocked, "snapshot already locked");

        snapshotTime = block.timestamp;
        isSnapshotLocked = true;

        emit HouseMoneySnapshotLock();
    }

    function freeze() external onlyOwner {
        require(!isFreezed, "Contract is already frozen");

        isFreezed = true;

        emit Freeze();
    }

    function claimETH() external {
        require(!isFreezed, "Contract is frozen");
        require(isSnapshotLocked, "Snapshot not yet locked");
        require(!hasClaimed[msg.sender], "You have already claimed your ETH");
        require(snapshotBalances[msg.sender] > 0, "You're not eligible to claim with 0 House");

        uint256 claimableAmount = (HOUSE_REVENUE_AMOUNT * snapshotBalances[msg.sender]) / totalSnapshotTokens;

        // prevent reentrancy
        hasClaimed[msg.sender] = true;

        // see https://ethereum.stackexchange.com/questions/78124/is-transfer-still-safe-after-the-istanbul-update
        (bool isSuccess,) = msg.sender.call{value: claimableAmount}("");
        require(isSuccess, "Claim amount tranfer failed");

        emit EthClaim(msg.sender, claimableAmount);
    }

    // Function to withdraw unclaimed ETH after 7 days
    function withdrawUnclaimedETH() public onlyOwner after3Days {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
        emit AdminWithdraw(amount);
    }

    receive() external payable {}
}