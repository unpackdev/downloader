// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 Interface
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

// Ownable Contract
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// HodlHog Contract
contract HodlHog is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    // Marketing wallet address
    address public marketingWallet = 0x362F4E7cB14a8c00f02eb808162Ff8A50a62d0d3;

    // Developer wallet address
    address public devWallet = 0x5c84724eeAbb972dDe78F991db3A0e47D09e9eD2;

    // Burn wallet address
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;

    // Tax rates
    uint256 public buyTaxRate = 3; // 3% buy tax
    uint256 public sellTaxRate = 3; // 3% sell tax

    // Telegram link
    string public telegramLink = "https://t.me/hodlhog";

    // Website link
    string public websiteLink = "http://www.hodlhog.live";

    // Twitter link
    string public twitterLink = "https://twitter.com/HodlHog88";

    // Events
    event Buy(address indexed buyer, uint256 amount, uint256 taxAmount);
    event Sell(address indexed seller, uint256 amount, uint256 taxAmount);

    uint public agr1;
    uint public agr2;

    // Constructor to initialize the ERC20 token and additional parameters
    constructor(address initialOwner, uint _agr1, uint _agr2) Ownable(initialOwner) {
        _mint(initialOwner, 8000000000000000000000000000); // 8 trillion initial supply

        // Set additional parameters
        agr1 = _agr1;
        agr2 = _agr2;
    }

    // ERC20 Functions

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    // Internal transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");

        uint256 taxAmount = (amount * sellTaxRate) / 100;
        uint256 transferAmount = amount - taxAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[marketingWallet] += taxAmount * 5 / 6; // 5% of total tax to marketing wallet
        _balances[devWallet] += taxAmount / 6; // 1% of total tax to dev wallet

        emit Transfer(sender, recipient, transferAmount);
        emit Sell(sender, transferAmount, taxAmount);
    }

    // Internal approve function
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal mint function
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Function to renounce ownership of the contract
    function renounceContractOwnership() external onlyOwner {
        renounceOwnership();
    }
}