// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Lockable.sol";
import "./Ownable.sol";

interface IPool {
    function updateFETHRewards(uint256 _mintBase) external;
}

contract FETH_R1 is Ownable, IERC20, Lockable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _globalPoolContract;

    // Shares of users by deposit amount
    mapping (address => uint256) private _shares;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalRewards;
    uint256 private _totalShares;
    uint256 private _totalSent;

    // Total deposited amount
    uint256 private _totalDeposit;

    address private _operator;

    address private _bscBridgeContract;

    uint256 _balanceRatio;

    //
    modifier onlyPool() {
        require(_globalPoolContract == msg.sender, "Ownable: caller is not the micropool contract");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(string memory name, string memory symbol, address globalPoolContract, address operator) public initializer {
        _globalPoolContract = globalPoolContract;
        _operator = operator;

        _name = name;
        _symbol = symbol;

        _decimals = 18;
    }

    function mint(address account, uint256 shares, uint256 sentAmount) external onlyPool {
        _shares[account] = _shares[account].add(shares);
        _totalShares = _totalShares.add(shares);
        _totalSent = _totalSent.add(sentAmount);

        emit Transfer(address(0), account, sentAmount);
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == address(_bscBridgeContract) || msg.sender == owner(), 'Not allowed');
        uint256 shares = sharesOfEth(amount);
        _shares[account] = _shares[account].add(shares);
        _totalShares = _totalShares.add(shares);
        _totalSent = _totalSent.add(amount);

        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == address(_bscBridgeContract) || msg.sender == owner(), 'Not allowed');
        uint256 shares = sharesOfEth(amount);
        _shares[account] = _shares[account].sub(shares);
        _totalShares = _totalShares.sub(shares);

        emit Transfer(account, address(0), amount);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSent.add(_totalRewards);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _shares[account].mul(_balanceRatio).div(1 ether);
    }

    function sharesOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    function sharesOfEth(uint256 amount) public view returns (uint256) {
        return amount.mul(_totalShares).div(totalSupply());
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 shares = sharesOfEth(amount);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _shares[sender] = _shares[sender].sub(shares, "ERC20: transfer shares exceeds balance");
        _shares[recipient] = _shares[recipient].add(shares);

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function totalShares() public view returns(uint256) {
        return _totalShares;
    }

    function setBscBridgeContract(address _bscBridge) public onlyOwner {
        _bscBridgeContract = _bscBridge;
    }

    function setBalanceRatio(uint256 ratio, uint256 rewards) external onlyOperator {
        _balanceRatio = ratio;
        _totalRewards = rewards;
        IPool(_globalPoolContract).updateFETHRewards(1e18 * 1e18 / _balanceRatio);
    }

    function ratio() external view returns(uint256) {
        return _balanceRatio;
    }
}
