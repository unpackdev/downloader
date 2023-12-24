// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";

contract LabelProtocol is IERC20, IERC20Metadata, Context, Ownable {
    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public excludeFromFees;

    string public constant llmVersion = "v22";

    uint256 private _totalSupply;

    uint16 public feeBpsTotal;
    uint16 public feeBpsToLp;
    uint16 public maxBpsPerWallet;

    address public feeWallet;
    address public lpWallet;

    address public uniswapPair;

    constructor(
        address feeWallet_,
        address lpWallet_,
        uint16 feeBpsTotal_,
        uint16 feeBpsToLp_,
        uint16 maxBpsPerWallet_)
    {
        require(feeWallet_!=address(0));
        require(lpWallet_!=address(0));
        require(feeBpsTotal_ <= 10000);
        require(feeBpsToLp_ <= feeBpsTotal_);

        _name = "Label Protocol";
        _symbol = "LABEL";

        excludeFromFees[msg.sender] = true;
        excludeFromFees[feeWallet_] = true;
        excludeFromFees[lpWallet_] = true;

        feeWallet = feeWallet_;
        lpWallet = lpWallet_;
        feeBpsTotal = feeBpsTotal_;
        feeBpsToLp = feeBpsToLp_;
        maxBpsPerWallet = maxBpsPerWallet_;

        IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        uniswapPair = factory.createPair(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        _mint(msg.sender, 10_000_000 * (10**18));
    }

    function setFeeWallet(address feeWallet_) public onlyOwner {
      require(feeWallet_!=address(0));
      feeWallet = feeWallet_;
      excludeFromFees[feeWallet_] = true;
    }

    function setLpWallet(address lpWallet_) public onlyOwner {
      require(lpWallet_!=address(0));
      lpWallet = lpWallet_;
      excludeFromFees[lpWallet_] = true;
    }

    function setFees(uint16 feeBptsTotal_, uint16 feeBpsToLp_) public onlyOwner {
      require(feeBptsTotal_ <= 10000);
      require(feeBpsToLp_ <= feeBptsTotal_);

      feeBpsTotal = feeBptsTotal_;
      feeBpsToLp = feeBpsToLp_;
    }

    function setMaxBpsPerWallet(uint16 maxBpsPerWallet_) public onlyOwner {
      require(maxBpsPerWallet_ <= 10000);
      maxBpsPerWallet = maxBpsPerWallet_;
    }

    function setExcludeFromFees(address account, bool value) public onlyOwner {
      excludeFromFees[account] = value;
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
            !excludeFromFees[from] &&
            !excludeFromFees[to]) {
            uint256 feeTotal = amount * feeBpsTotal / 10000;
            uint256 feeToLp = amount * feeBpsToLp / 10000;
            require(feeToLp <= feeTotal); // Sanity check
            uint256 feeRemaining = feeTotal - feeToLp;

            uint256 receiveAmount = amount - feeTotal;

            _balances[from] = fromBalance - amount;

            require(
                to==uniswapPair ||
                maxBpsPerWallet == 0 ||
                (_balances[to]+receiveAmount) <= (_totalSupply * maxBpsPerWallet / 10000)
            );

            _balances[to] += receiveAmount;
            emit Transfer(from, to, receiveAmount);

            if (feeRemaining > 0) {
                require(feeWallet!=address(0));

                _balances[feeWallet] += feeRemaining;
                emit Transfer(from, feeWallet, feeRemaining);
            }
            if (feeToLp > 0) {
                require(address(lpWallet)!=address(0));

                _balances[address(lpWallet)] += feeToLp;
                emit Transfer(from, lpWallet, feeToLp);
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

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
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
}