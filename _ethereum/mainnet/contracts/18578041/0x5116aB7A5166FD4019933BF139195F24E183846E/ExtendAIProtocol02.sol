// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ExtendAIProtocol02 is Context, IERC20, IERC20Metadata, Ownable {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public uniswapPair;
    address public lpWallet;
    mapping(address => bool) public excludeFromTax;
    uint16 public taxBps;
    uint256 public VERSION = 2;

    constructor(uint256 totalSupply_, address lpWallet_) {
        require(lpWallet_!=address(0));

        _name = "ExtendAI Protocol";
        _symbol = "GPU";
        lpWallet = lpWallet_;

        excludeFromTax[msg.sender] = true;
        excludeFromTax[lpWallet_] = true;

        // No further minting possible
        _mint(msg.sender, totalSupply_);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if ((from==uniswapPair || to==uniswapPair) &&
            !excludeFromTax[from] &&
            !excludeFromTax[to]) {
            uint256 tax = amount * taxBps / 10000;
            uint256 receiveAmount = amount - tax;

            _balances[from] = fromBalance - amount;

            _balances[to] += receiveAmount;
            emit Transfer(from, to, receiveAmount);

            if (tax > 0) {
                require(lpWallet!=address(0));

                _balances[lpWallet] += tax;
                emit Transfer(from, lpWallet, tax);
            }
        }
        else {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function initUniswapPair(IUniswapV2Router02 router) public onlyOwner {
        require(address(router)!=address(0));
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        uniswapPair = factory.createPair(address(this), router.WETH());
    }

    function setUniswapPair(address uniswapPair_) public onlyOwner {
        require(uniswapPair_!=address(0));
        uniswapPair = uniswapPair_;
    }

    function setTax(uint16 taxBps_) public onlyOwner {
        require(taxBps_ <= 10000);

        taxBps = taxBps_;
    }

    function setExcludeFromFees(address account, bool value) public onlyOwner {
        excludeFromTax[account] = value;
    }

    function setLpWallet(address lpWallet_) public onlyOwner {
        require(lpWallet_!=address(0));
        lpWallet = lpWallet_;
        excludeFromTax[lpWallet_] = true;
    }
}