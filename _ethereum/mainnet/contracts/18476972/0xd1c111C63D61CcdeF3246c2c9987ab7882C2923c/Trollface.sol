// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address owner_) {
        _owner = owner_;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract Trollface is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public _excludeFromFee;

    uint256 private _totalSupply;
    IDexRouter public router;
    address public uniswapV2Pair;
    address public feeWallet;
    address public teamWallet;
    bool private fee;
    uint256 public tax = 30;
    uint256 public percentDivider = 1_000;

    string private _name = "Trollface";
    string private _symbol = "$TROLL";

    constructor(
        address _owner,
        address _feeWallet,
        address _teamWallet
    ) Ownable(_owner) {
        address router_ = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IDexRouter(router_);
        uniswapV2Pair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        feeWallet = _feeWallet;
        teamWallet = _teamWallet;
        _mint(_owner, 89_250_000_000 * 1e18);
        _mint(teamWallet, 10_750_000_000 * 1e18);
        _excludeFromFee[address(this)] = true;
        _excludeFromFee[_feeWallet] = true;
        _excludeFromFee[_owner] = true;
        _excludeFromFee[_teamWallet] = true;
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        uint256 amountReceived;
        if (
            _excludeFromFee[sender] ||
            _excludeFromFee[recipient] ||
            (sender != uniswapV2Pair && recipient != uniswapV2Pair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == uniswapV2Pair) {
                feeAmount = (amount * (tax)) / (percentDivider);
                amountReceived = amount - (feeAmount);
                _takeFee(sender, feeAmount);
            }
            if (recipient == uniswapV2Pair) {
                feeAmount = (amount * (tax)) / (percentDivider);
                amountReceived = amount - (feeAmount);
                _takeFee(sender, feeAmount);
            }
        }
        _balances[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);
    }

    function _takeFee(address sender, uint256 feeAmount) internal {
        _balances[feeWallet] = _balances[feeWallet] + (feeAmount);
        emit Transfer(sender, feeWallet, feeAmount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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

    function excludeFromFee(address _address) public onlyOwner {
        _excludeFromFee[_address] = true;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        require(_fee >= 0 && _fee <= 100, "Fee can only be in between 0 to 10");
        tax = _fee;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}