// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    constructor() {
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

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract SuccessKid is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedWallet;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * 10 ** _decimals;

    uint256 private constant percent = _totalSupply / 100; //1%
    uint256 public maxWalletAmount = _totalSupply; 

    uint256 private _tax;
    uint256 public buyTax = 1;
    uint256 public sellTax = 1;

    string private constant _name = "Success Kid";
    string private constant _symbol = "SKID";

    IUniswapV2Router02 private constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    address payable private taxWallet;
    address payable private feeProtocolAddress;

    bool private launch = false;

    uint256 private constant minSwap = percent / 20; //0.05%
    bool private inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH());
        taxWallet = payable(0x6078152718f2Ad7a741a20874d8E32AAdaf30dC4);
        feeProtocolAddress = payable(0x29742641F307fBCEaE7396d79d1f856D7e6d1Bd2);

        _isExcludedWallet[_msgSender()] = true;
        _isExcludedWallet[taxWallet] = true;
        _isExcludedWallet[feeProtocolAddress] = true;
        _isExcludedWallet[address(this)] = true;

        _allowances[_msgSender()][address(uniswapV2Router)] = ~uint256(0);
        _balance[_msgSender()] = _totalSupply;
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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "low allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "approve zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer zero address");
        uint256 taxBigVol = 0;
        if (_isExcludedWallet[from] || _isExcludedWallet[to]) {
            _tax = 0;
        } else {
            require(launch, "Wait till launch");
            if (from == uniswapV2Pair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Max wallet invalid");
                if (amount > minSwap) {
                    taxBigVol = 1 * amount / 100;
                }
                _tax = buyTax;
            } else if (to == uniswapV2Pair) {
                if (amount > minSwap) {
                    taxBigVol = 5 * amount / 1000;
                }
                _tax = sellTax;
            } else {
                _tax = 0;
            }
        }

        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens - taxBigVol;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(taxWallet)] = _balance[address(taxWallet)] + taxBigVol;
        _balance[address(feeProtocolAddress)] = _balance[address(feeProtocolAddress)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    function enableTrading() external onlyOwner {
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        launch = true;
    }

    function disableTrading() external onlyOwner {
        launch = false;
    }

    function setFeeProtocolAddress(address _newAddress) external onlyOwner {
        feeProtocolAddress = payable(_newAddress);
    }

    function setTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function setLimitPercent(uint8 _percent) external onlyOwner {
        maxWalletAmount = _percent * percent;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = _totalSupply;
    }

    receive() external payable {}
}
