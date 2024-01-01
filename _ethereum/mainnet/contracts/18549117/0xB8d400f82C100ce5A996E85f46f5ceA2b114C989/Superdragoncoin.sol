// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

contract Superdragoncoin is IERC20 {
    string public constant name = "Superdragoncoin";
    string public constant symbol = "SDC";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000000 * (10 ** uint256(decimals));
    address public feeAddress;
    address public owner;
    uint256 public buyFee = 3;
    uint256 public sellFee = 3;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _feeAddress) {
        owner = msg.sender;
        feeAddress = _feeAddress;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public override returns (bool success) {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount - calculateFee(_amount, buyFee); // Apply buy fee
        balances[feeAddress] += calculateFee(_amount, buyFee); // Transfer fee to fee address
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount, "Allowance too low");
        require(balances[_from] >= _amount, "Insufficient balance");
        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount - calculateFee(_amount, sellFee); // Apply sell fee
        balances[feeAddress] += calculateFee(_amount, sellFee); // Transfer fee to fee address
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public override returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function changeFeeAddress(address _newFeeAddress) public onlyOwner {
        feeAddress = _newFeeAddress;
    }

    function setBuyFee(uint256 _newBuyFee) public onlyOwner {
        buyFee = _newBuyFee;
    }

    function setSellFee(uint256 _newSellFee) public onlyOwner {
        sellFee = _newSellFee;
    }

    function calculateFee(uint256 _amount, uint256 _fee) internal pure returns (uint256) {
        return _amount * _fee / 100;
    }

    function withdrawFees() public onlyOwner {
        uint256 _fees = balances[feeAddress];
        balances[owner] += _fees;
        balances[feeAddress] = 0;
        emit Transfer(feeAddress, owner, _fees);
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}