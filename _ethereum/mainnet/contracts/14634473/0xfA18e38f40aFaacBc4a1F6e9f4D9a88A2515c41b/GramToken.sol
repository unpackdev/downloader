pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IBEP20.sol";

contract GramToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address private MasterChef;

    uint256 private _tTotal = 850000000 * 10**9; // 850M supply
    uint256 private _masterChefShare = 0;
    uint256 private constant MAX_STAKING_SHARE = 150000000 * 10**9;

    string private _name = 'SafeGRAM';
    string private _symbol = 'GRAM';
    uint8 private _decimals = 9;

    constructor () public {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "SafeError: : transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "SafeError: : decreased allowance below zero"));
        return true;
    }

    function setMasterChef(address _masterChef) external onlyOwner {
        require(_masterChef != address(0), "SafeError: : MasterChef cannot be the zero address");
        MasterChef = address(_masterChef);
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "SafeError: : approve from the zero address");
        require(spender != address(0), "SafeError: : approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "SafeError: : transfer from the zero address");
        require(recipient != address(0), "SafeError: : transfer to the zero address");
        require(amount > 0, "SafeError: Transfer amount must be greater than zero");
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function mint(address account, uint256 amount) external returns (bool) {
        require(msg.sender == MasterChef, "GRAM: wut?");
        require(MasterChef != address(0), "GRAM: Staking is not started");
        require(_masterChefShare.add(amount) <= MAX_STAKING_SHARE, "GRAM: Staking has been finished");

        _mint(account, amount);
        _masterChefShare = _masterChefShare.add(amount);

        return true;

    }

    function isMintable(uint256 amount) external view returns (bool) {
        return _masterChefShare.add(amount.mul(110).div(100)) <= MAX_STAKING_SHARE;
    }

      /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _tTotal += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}
