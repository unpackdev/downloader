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

contract GREENToken is IERC20 {
    string public name = "Green Green";            
    string public symbol = "GREEN";         
    uint8 public decimals = 18;              
    uint256 private _totalSupply;           

    address public usdtContractAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 

    address private _owner; 
    uint256 public constant usdtToGreenRate = 1000; 

    uint256 public totalUSDTReceived; 
    uint256 public totalGREENIssued; 

    address public usdtReceiverAddress = 0x14B3d9F67Ebcb12121DF0E3705F800A129Ec2B30;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _totalSupply = 1111111000 * 10 ** uint256(decimals); 
        _balances[address(this)] = _totalSupply; 
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(address(this), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(address(this), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approval from the zero address");
        require(spender != address(0), "Approval to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function renounceAdmin() public onlyOwner {
        _owner = address(0); 
    }

    function receiveUSDTAndSendGREEN(uint256 usdtAmount) external {
        require(msg.sender != address(0), "Sender address must not be zero");
        require(usdtAmount > 0, "USDT amount must be greater than zero");
        
        (bool usdtTransferSuccess, ) = usdtContractAddress.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, usdtReceiverAddress, usdtAmount)
        );

        require(usdtTransferSuccess, "USDT transfer failed");
        
        uint256 grinAmount = usdtAmount * usdtToGreenRate*(10**12);

        totalUSDTReceived += usdtAmount;
        totalGREENIssued += grinAmount;
        
        _transfer(address(this), msg.sender, grinAmount);
    }
}