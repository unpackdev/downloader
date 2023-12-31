// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./Ownable.sol";

contract Presale is Ownable {
    event DepositEvent(address from, IERC20Metadata token, string symbol, uint amount);

    struct Deposit {
        address participant;
        IERC20Metadata token;
        string symbol;
        uint amount;
    }

    struct Config {
        address marketing;

        uint saleStart;
        uint saleEnd;
        uint minAmount;
        uint maxAmount;
    }

    uint public total;
    Config public config;

    address[] internal tokens;
    mapping(address => bool) internal allowedTokens;

    mapping(address => Deposit) internal participants;

    Deposit[] internal deposits;

    constructor() {
        transferOwnership(tx.origin);
    }

    function setConfig(Config memory _config) public onlyOwner {
        config = _config;
    }

    // Get tokens list
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    // Get participants list
    function getParticipants() external view returns (address[] memory) {
        address[] memory list = new address[](deposits.length);

        for (uint i = 0; i < deposits.length; i++) {
            list[i] = deposits[i].participant;
        }

        return list;
    }

    // Get participant
    function getDepositByWallet(address wallet) external view returns (Deposit memory) {
        return participants[wallet];
    }

    // Get deposit by index
    function getDepositByIndex(uint index) external view returns (Deposit memory) {
        return deposits[index];
    }

    // Get all deposits
    function getDeposits() external view returns (Deposit[] memory) {
        return deposits;
    }

    // Deposit funds
    function deposit(IERC20Metadata token, uint256 amount) public {
        uint transferAmount = amount * (10 ** token.decimals());

        require(tx.origin == msg.sender, "Not allowed");
        require(participants[msg.sender].amount == 0, "No second chance");
        require(amount >= config.minAmount, "Min amount limit");
        require(amount <= config.maxAmount, "Max amount limit");
        require(block.timestamp >= config.saleStart, "Not started");
        require(block.timestamp <= config.saleEnd, "Ended");
        require(allowedTokens[address(token)] == true, "Unknown token");

        // Transfer tokens
        require(token.transferFrom(msg.sender, config.marketing, transferAmount), "Insufficient funds");

        string memory symbol = token.symbol();

        Deposit memory depositData = Deposit({
            participant: msg.sender,
            token: token,
            symbol: symbol,
            amount: amount
        });

        participants[msg.sender] = depositData;
        deposits.push(depositData);

        total += amount;

        emit DepositEvent(msg.sender, token, symbol, amount);
    }

    // Set Marketing account
    function setMarketing(address _marketing) public onlyOwner {
        config.marketing = _marketing;
    }

    // Set Min Amount
    function setMin(uint _minAmount) public onlyOwner {
        config.minAmount = _minAmount;
    }

    // Set Max Amount
    function setMax(uint _maxAmount) public onlyOwner {
        config.maxAmount = _maxAmount;
    }

    // Set Sale Start
    function setSaleStart(uint _saleStart) public onlyOwner {
        config.saleStart = _saleStart;
    }

    // Set Sale End
    function setSaleEnd(uint _saleEnd) public onlyOwner {
        config.saleEnd = _saleEnd;
    }

    // Add token to allowed
    function addToken(address token) public onlyOwner {
        tokens.push(address(token));
        allowedTokens[token] = true;
    }

    // Remove token from allowed
    function removeToken(address token) public onlyOwner {
        allowedTokens[token] = false;
    }

    // Set total value
    function setTotal(uint _total) public onlyOwner {
        total = _total;
    }

    // Withdraw funds
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;

        require(balance > 0, "Balance is 0");

        payable(owner()).transfer(balance);
    }
}
