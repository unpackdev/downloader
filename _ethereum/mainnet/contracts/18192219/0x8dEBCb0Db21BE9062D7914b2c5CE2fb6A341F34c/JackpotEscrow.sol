// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;
pragma solidity ^0.8.19;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "SafeMath.sol";

contract UniqueAddressSet {
    mapping(address => bool) private addressExists;
    address[] private uniqueAddresses;

    function addUniqueAddress(address _address) external {
        if (!addressExists[_address]){
            addressExists[_address] = true;
            uniqueAddresses.push(_address);
        }
    }

    function getUniqueAddressCount() external view returns (uint256) {
        return uniqueAddresses.length;
    }

    function getUniqueAddressByIndex(uint256 index) external view returns (address) {
        require(index < uniqueAddresses.length, "Index out of range");
        return uniqueAddresses[index];
    }
}

contract JackpotEscrow {
    address public admin;
    address public winner; // Store the winner's address
    uint256 public estimatedDepositEndBlock;
    uint256 public depositStartBlock;
    uint256 private totalDeposits;
    bool public depositEnded;
    UniqueAddressSet private addressSet;
    mapping(address => uint256) public balances;
    ERC20 public token;

    constructor(address wagerAddress) {
        admin = msg.sender;
        token = ERC20(wagerAddress); // Initialize the ERC20 token contract
        depositEnded = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyDuringDeposit() {
        require(!depositEnded, "Deposit period has ended");
        _;
    }

    modifier onlyWinner() {
        require(msg.sender == winner, "Only winner can call this function");
        _;
    }

    modifier onlyAfterDepositEnd() {
        require(depositEnded,"Deposit period hasn't ended yet");
        _;
    }

    function selectWinner() internal {
        if (addressSet.getUniqueAddressCount() == 0) {
            winner = admin;
            return;
        }
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % totalDeposits;
        uint256 cumulativeDeposits = 0;
        uint256 currentBalance = 0;
        for (uint256 i = 0; i < addressSet.getUniqueAddressCount(); i++) {
            address userAddress = addressSet.getUniqueAddressByIndex(i);
            uint256 depositAmount = balances[userAddress];
            if (cumulativeDeposits+depositAmount >= randomValue) {
                winner = userAddress;
                break;
            }
            cumulativeDeposits = cumulativeDeposits+depositAmount;
        }
    }

    function depositToken(uint256 amount) external onlyDuringDeposit {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        token.transferFrom(msg.sender, address(0), amount); // Transfer the deposited tokens to this contract
        // ERC20Burnable(address(token)).burn(amount); // Error here
        addressSet.addUniqueAddress(msg.sender);
        balances[msg.sender] += amount;
        totalDeposits += amount;
    }

    function startDepositPeriod() external payable onlyAdmin {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(depositEnded, "Deposit period has already started");
        addressSet = new UniqueAddressSet();
        depositEnded = false;
        depositStartBlock = block.number;
        estimatedDepositEndBlock = depositStartBlock + 20000;
        totalDeposits = 0;
    }

    function endDepositPeriod() external onlyAdmin {
        depositEnded = true;
        depositStartBlock = 0;
        estimatedDepositEndBlock = 0;
        selectWinner();
        for (uint256 i = 0; i < addressSet.getUniqueAddressCount(); i++) {
            address userAddress = addressSet.getUniqueAddressByIndex(i);
            delete balances[userAddress];
        }
    }

    function withdraw() external onlyWinner onlyAfterDepositEnd {
        require(winner != address(0), "Winner has not been selected yet");
        require(address(this).balance > 0, "No reward available for withdrawal");
        (bool success, ) = winner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
        winner = address(0);
    }
}