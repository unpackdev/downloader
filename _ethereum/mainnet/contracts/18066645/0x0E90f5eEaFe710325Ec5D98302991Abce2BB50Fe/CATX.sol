// TG: t.me/cat1000xerc

pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract CATX is Context, IERC20 {
    string private constant _name = "Cat1000x";
    string private constant _symbol = "Cat1000x";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100000000000000000000000000;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _marketingFeePercentage = 2; // default to 2%
    address private _owner; // contract owner
    address private _marketingAddress; // address to receive the marketing fee

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Not the contract owner");
        _;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        _owner = _msgSender(); // set the contract deployer as the initial owner
        _marketingAddress = _msgSender(); // set the contract deployer as the initial marketing address

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function setMarketingFeePercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Fee percentage too high"); // ensure the fee isn't too high (you can adjust this limit as needed)
        _marketingFeePercentage = percentage;
    }

    function setMarketingAddress(address newMarketingAddress) external onlyOwner {
        require(newMarketingAddress != address(0), "Invalid address");
        _marketingAddress = newMarketingAddress;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 marketingFee = (amount * _marketingFeePercentage) / 100;
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[_marketingAddress] += marketingFee;
        }
        _balances[to] += amount - marketingFee;

        emit Transfer(from, _marketingAddress, marketingFee);
        emit Transfer(from, to, amount - marketingFee);
    }
}