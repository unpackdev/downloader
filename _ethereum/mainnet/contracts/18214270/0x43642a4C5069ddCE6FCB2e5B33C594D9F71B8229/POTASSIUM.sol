// SPDX-License-Identifier: MIT

// Telegram: https://t.me/CommunityPotassium

// Twitter: https://twitter.com/Potassium_Army

// Website : https://pottoken.io


pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

contract POTASSIUM is ERC20, Ownable {
    uint256 public _feeBuy;
    uint256 public _feeSell;

    uint256 public _maxWallet;

    uint256 public swapTriggerAmount;
    bool private swapping;

    address public swapPair;
    IUniswapV2Router public swapRouter;

    mapping(address => bool) internal _maxWalletWL;
    

    constructor() ERC20("Potassium", "K") {
        _mint(_msgSender(), (390_983_000 * 10 ** decimals()));
        _feeSell = 300;
        _feeBuy = 150;
        swapTriggerAmount = 3_000_000 * 10 ** decimals();

        _maxWallet = 15_639_320 * 10 ** decimals();

        IUniswapV2Router _uniswapRouter = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        swapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );

        swapRouter = _uniswapRouter;
        _maxWalletWL[msg.sender] = true;
        _maxWalletWL[address(this)] = true;
        _maxWalletWL[swapPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!swapping) {
            if (from == owner()) {
                super._transfer(from, to, amount);
            } else {
                uint256 taxAmount;
                if (from == swapPair) {
                    taxAmount = ((amount * _feeBuy) / 1000);
                }
                if (to == swapPair) {
                    taxAmount = ((amount * _feeSell) / 1000);
                }
                super._transfer(from, to, amount - taxAmount);
                super._transfer(from, (address(this)), taxAmount);
                if (
                    _balances[address(this)] >= swapTriggerAmount &&
                    from == swapPair
                ) {
                    swapping = true;
                    _swapTokensForEth();
                    swapping = false;
                }
            }
        } else {
            super._transfer(from, to, amount);
        }
        if (!_maxWalletWL[to]) {
            require(_balances[to] <= _maxWallet);
        }
    }

    function _swapTokensForEth() private {
        uint256 tokenAmount = _balances[address(this)];
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            owner(),
            (block.timestamp)
        );
    }

    function updateFees(uint256 buyFee, uint256 sellFee) public onlyOwner {
        _feeBuy = buyFee;
        _feeSell = sellFee;
        _swapTokensForEth();
    }

    function autoPilot() external onlyOwner {
        _feeBuy = 20;
        _feeSell = 20;
        _swapTokensForEth();
    }
}