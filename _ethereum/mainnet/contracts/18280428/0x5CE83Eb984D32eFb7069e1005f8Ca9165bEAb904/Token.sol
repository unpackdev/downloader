// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name = "HatMan"; // Token name
    string public symbol = "BENADRYL"; // Token symbol
    uint8 public decimals = 18; // Token decimals
    uint256 public totalSupply = 1000000000 * 10**uint256(decimals); // Total supply of 1,000,000,000 HIT

    uint256 public maxWalletPercent = 5; // Maximum wallet limit as a percentage of total supply
    uint256 public maxWalletBalance = (totalSupply * maxWalletPercent) / 100; // Calculate the maximum wallet balance

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public taxAddress = 0x2E70182C66672154CbcFF4035664062278f613A2;
    uint256 public taxRate = 2; // 2% tax rate

    address public owner;
    bool public taxEnabled = true; // Flag to control tax collection
    bool public maxWalletEnabled = true; // Flag to control maximum wallet limit

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier checkMaxWalletLimit(address _to, uint256 _value) {
        if (maxWalletEnabled && _to != address(0) && _to != owner) {
            require(balanceOf[_to] + _value <= maxWalletBalance, "Wallet balance exceeds maximum limit");
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TaxCollected(address indexed from, uint256 value);
    event TaxToggled(bool enabled);
    event MaxWalletToggled(bool enabled);
    event OwnershipRenounced(address indexed previousOwner);

    // Function to enable or disable tax collection, only callable by the owner
    function toggleTax(bool _enabled) public onlyOwner {
        taxEnabled = _enabled;
        emit TaxToggled(_enabled);
    }

    // Function to enable or disable maximum wallet limit, only callable by the owner
    function toggleMaxWallet(bool _enabled) public onlyOwner {
        maxWalletEnabled = _enabled;
        emit MaxWalletToggled(_enabled);
    }

    // Function to renounce ownership of the contract
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function _transfer(address _from, address _to, uint256 _value) internal checkMaxWalletLimit(_to, _value) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");

        uint256 taxAmount = 0;
        uint256 afterTaxAmount = _value;

        if (taxEnabled) {
            taxAmount = (_value * taxRate) / 100;
            afterTaxAmount = _value - taxAmount;
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += afterTaxAmount;
        balanceOf[taxAddress] += taxAmount;

        emit Transfer(_from, _to, afterTaxAmount);
        if (taxEnabled) {
            emit TaxCollected(_from, taxAmount);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}