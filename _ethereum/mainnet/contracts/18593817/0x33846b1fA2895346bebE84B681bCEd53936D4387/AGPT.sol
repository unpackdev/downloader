// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AGPT is IERC20 {
    string public name = "AGPT";
    string public symbol = "AGPT";
    uint256 public totalSupply = 21000000000 * 10**18; // 21,000,000,000 
    uint8 public decimals = 18; // Using 18 decimals by default

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    uint256 public taxRate; // Updated tax rate

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Burn(address indexed burner, uint256 value);
    event TaxRateChanged(uint256 newTaxRate); // Event for tax rate changes

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        taxRate = 0; // Initial tax rate set to 0%
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid transfer to the zero address");
        require(_value > 0, "Invalid transfer value");

        // Calculate tax amount
        uint256 tax = (_value * taxRate) / 100;
        uint256 netTransferAmount = _value - tax;

        // Transfer tokens excluding tax
        balanceOf[_from] -= _value;
        balanceOf[_to] += netTransferAmount;

        // Burn the tax
        totalSupply -= tax;

        emit Transfer(_from, _to, netTransferAmount);
        emit Burn(_from, tax);
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
        require(_value <= allowance[_from][msg.sender], "Transfer amount exceeds allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance to burn");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
    }

    function setTaxRate(uint256 newTaxRate) public onlyOwner {
        require(newTaxRate <= 100, "Tax rate cannot exceed 100%");
        taxRate = newTaxRate;
        emit TaxRateChanged(newTaxRate);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}
