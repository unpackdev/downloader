// SPDX-License-Identifier: MIT
//https://sandwich.bot/
//https://twitter.com/SandwichERC20
//https://t.me/SandwichChat
//https://archives.sandwich.bot/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, " multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() payable {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract Sandwich is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balance;
    mapping(address => bool) private _isExcludedWallet;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 5_000_000 * 10 ** _decimals;

    string private constant _name = "Sandwich";
    string private constant _symbol = "Sandwich";

    uint256 public buyFee = 10;
    uint256 public sellFee = 10;
    uint256 public maxAmountPerTx = (_totalSupply * 1) / 100;
    uint256 public maxAmountPerWallet = (_totalSupply * 1) / 100;
    uint256 public phoenixPercent = 20;
    uint256 private maxSwapTokenAmount = 250_000 * 10 ** _decimals;

    IUniswapV2Router02 private constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    address public stakingWallet;
    address payable private taxWallet;
    address payable private phoenixWallet;
    address payable private devWallet1;
    address payable private devWallet2;

    bool private swapEnabled = false;
    bool private inSwapAndLiquify = false;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address owner,
        address _taxWallet,
        address _phoenixWallet
    ) payable {
        taxWallet = payable(_taxWallet);
        phoenixWallet = payable(_phoenixWallet);
        devWallet1 = payable(0xb5ef669ffB567d9fc6dBa54934fcf8618Edc003d);
        devWallet2 = payable(0xDb26CD2AB5968e7189201e50F332b80d1f9e2efc);
        address cexWallet = 0xbE51c0Aa0Fe35A16bDD1dB48c8Ef335B518c7912;
        stakingWallet = 0x687d8E292CecA0cB77d71490ed9682ccba71E27C;
        _isExcludedWallet[_msgSender()] = true;
        _isExcludedWallet[address(this)] = true;
        _isExcludedWallet[taxWallet] = true;
        _isExcludedWallet[phoenixWallet] = true;
        _isExcludedWallet[devWallet1] = true;
        _isExcludedWallet[devWallet2] = true;
        _isExcludedWallet[owner] = true;
        _mint(_msgSender(), _totalSupply);
        _transfer(_msgSender(), stakingWallet, _totalSupply.mul(11).div(100));
        _transfer(_msgSender(), cexWallet, _totalSupply.mul(9).div(100));

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "low allowance")
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(
            owner != address(0) && spender != address(0),
            "approve zero address"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 _tax = 0;
        if (from != owner() && to != owner()) {
            require(swapEnabled, "Trading is not allowed");
        }
        if (!_isExcludedWallet[from] && !_isExcludedWallet[to]) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(
                    _balance[to] + amount <= maxAmountPerWallet ||
                        maxAmountPerWallet == 0,
                    "Exceed max amount per wallet"
                );
                require(
                    amount <= maxAmountPerTx || maxAmountPerTx == 0,
                    "Exceed max amount per tx"
                );
                _tax = buyFee;
            } else if (to == uniswapV2Pair) {
                require(
                    amount <= maxAmountPerTx || maxAmountPerTx == 0,
                    "Exceed max amount per tx"
                );
                _tax = sellFee;
            } else {
                _tax = 0;
            }
        }

        uint256 taxAmount = amount.mul( _tax).div(100);
        uint256 transferAmount = amount.sub(taxAmount);

        _balance[from] = _balance[from].sub(amount);
        _balance[address(this)] = _balance[address(this)] + taxAmount;

        uint256 cAmount = _balance[address(this)];
        if (
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            to == uniswapV2Pair &&
            swapEnabled
        ) {
            if (cAmount >= maxSwapTokenAmount) {
                swapTokensForEth(cAmount);
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    sendETHToFee(ethBalance);
                }
            }
        }

        _balance[to] = _balance[to] + transferAmount;

        if (taxAmount > 0) {
            emit Transfer(from, address(this), taxAmount);
        }

        emit Transfer(from, to, transferAmount);
    }

    function _mint(address to, uint256 amount) private {
        _balance[to] = amount;
        emit Transfer(address(0), to, amount);
    }

    function swapTokensForEth(uint256 _tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function buyBackAndBurn() public payable {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, _msgSender(), block.timestamp);
        uint256 burnAmount = _balance[_msgSender()];
        _burn(_msgSender(), burnAmount);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function _burn(address account, uint256 value) internal {
        require(_balance[account] >= value, "Invalid amount");
        unchecked {
            _totalSupply -= value;
            _balance[account] -= value;
        }

        emit Transfer(account, address(0), value);
    }
 
    function sendETHToFee(uint256 _amount) private {
        uint256 phoenixAmount = (_amount * phoenixPercent) / 100;
        uint256 feeAmount = _amount.sub(phoenixAmount);
        phoenixWallet.transfer(phoenixAmount);
        devWallet1.transfer(feeAmount * 19 / 100);
        devWallet2.transfer(feeAmount * 31 / 100);
        taxWallet.transfer(feeAmount * 50 / 100);
    }

    function manualSwap() external {
        require(
            _msgSender() == owner() ||
                _msgSender() == taxWallet ||
                _msgSender() == devWallet1 ||
                _msgSender() == devWallet2,
            "Invalid permission"
        );

        uint256 tokenBalance = _balance[address(this)];
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    function openTrading() public onlyOwner {
        require(!swapEnabled, "token is already enabled for trading");
        swapEnabled = true;
    }

    function _setFee(uint256 _buyFee, uint256 _sellFee) private {
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function _setMaxAmountPerTx(uint256 _maxAmountPerTx) private {
        maxAmountPerTx = _maxAmountPerTx;
    }

    function _setMaxAmountPerWallet(uint256 _maxAmountPerWallet) private {
        maxAmountPerWallet = _maxAmountPerWallet;
    }

    function _setMaxSwapTokenAmount(uint256 _maxSwapTokenAmount) private {
        maxSwapTokenAmount = _maxSwapTokenAmount;
    }

    function _setPhoenixPercent(uint256 _phoenixPercent) private {
        phoenixPercent = _phoenixPercent;
    }

    function setFee(uint256 _buyFee, uint256 _sellFee) external {
        require(
            _msgSender() == owner() ||
            _msgSender() == taxWallet ||
            _msgSender() == devWallet1 ||
            _msgSender() == devWallet2,
            "Invalid permission"
        );
        require(_buyFee <= 5 && _sellFee <=5, "limited to 5 percent" );
        _setFee(_buyFee, _sellFee);
    }

    function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyOwner {
        require (_maxAmountPerTx >= _totalSupply.mul(5).div(1000), "maxTx is limited to 0.5%");
        _setMaxAmountPerTx(_maxAmountPerTx);
    }

    function setMaxAmountPerWallet(
        uint256 _maxAmountPerWallet
    ) external onlyOwner {
        require (_maxAmountPerWallet >= _totalSupply.mul(5).div(1000), "maxWallet is limited to 0.5%");
        _setMaxAmountPerWallet(_maxAmountPerWallet);
    }

    function setPhoenixPercent(uint256 _phoenixPercent) external {
        require(
            _msgSender() == owner() || _msgSender() == phoenixWallet,
            "Invalid permission"
        );
        _setPhoenixPercent(_phoenixPercent);
    }

    function setMaxSwapTokenAmount(
        uint256 _maxSwapTokenAmount
    ) external {
        require(
            _msgSender() == owner() ||
            _msgSender() == taxWallet ||
            _msgSender() == devWallet1 ||
            _msgSender() == devWallet2,
            "Invalid permission"
        );
        _setMaxSwapTokenAmount(_maxSwapTokenAmount);
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        taxWallet = payable(_taxWallet);
    }

    function setPhoenixWallet(address _phoenixWallet) external onlyOwner {
        phoenixWallet = payable(_phoenixWallet);
    }

    function setDevWallet1(address _devWallet) external {
        require(_msgSender() == devWallet1);
        devWallet1 = payable(_devWallet);
    }

    function setDevWallet2(address _devWallet) external {
        require(_msgSender() == devWallet2);
        devWallet2 = payable(_devWallet);
    }

    receive() external payable {}
}

contract Factory is Context, Ownable {
    Sandwich public sandwich;
    IUniswapV2Router02 private constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event SandwichTokenDeployed(address tokenAddress);

    constructor(address _taxWallet, address _phoenixWallet) payable {
        sandwich = new Sandwich(_msgSender(), _taxWallet, _phoenixWallet); // creating new contract inside another parent contract
        emit SandwichTokenDeployed(address(sandwich));
        sandwich.approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(sandwich),
            sandwich.balanceOf(address(this)),
            0,
            0,
            _msgSender(),
            block.timestamp
        );
        sandwich.transferOwnership(_msgSender());
    }
}
