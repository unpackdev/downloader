// https://www.begeth.com/
// https://t.me/begerc20

// SPDX-License-Identifier: Unlicensed

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
        require(newOwner != address(0), "new owner is the zero address");
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
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
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
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract BEG is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromAll;
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10_000_000_000 * 10**_decimals;
    string private constant _name = "BEG";
    string private constant _symbol = "BEG";
    uint256 private buyTax=0;
    uint256 private sellTax=0;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable private collection;
    bool private launched;
    uint256 private launchedAt;

    uint256 private constant maxSwap = _totalSupply / 100 / 3;
    uint256 private constant minSwap = _totalSupply / 100 / 20;
    uint256 public maxWalletAmount = (_totalSupply / 100) * 5;
    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        collection = payable(0xd8dB926568275f976b6918D303C4028CA7989c25);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        address boss = 0x4A2443877aBf999AA421f84d0751cb8dD471F09E;

        _isExcludedFromAll[boss] = true;
        _isExcludedFromAll[collection] = true;
        _isExcludedFromAll[address(this)] = true;

        _allowances[boss][address(uniswapV2Router)] = _totalSupply;
        _balance[boss] = _totalSupply;
        emit Transfer(address(0), address(boss), _totalSupply);
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

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function setAt(uint256 a) external onlyOwner {
         launchedAt = a;
     }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"Low allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "Approve zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableTrading() external onlyOwner() {
        require(!launched,"trading is already open");
        launched = true;
        launchedAt = launchedAt+block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer zero address");
        uint256 _tax = 0;
        if (_isExcludedFromAll[from] || _isExcludedFromAll[to]) {
            //pre-launch transfers
        } else {
            require(launched, "Wait DEX launch");
            if (block.number<launchedAt) {_tax=99;} else {
                if (from == uniswapV2Pair) {
                    require(balanceOf(to) + amount <= maxWalletAmount, "over max wallet");
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    _tax = sellTax;
                    uint256 tokensToSwap = balanceOf(address(this));
                    if (tokensToSwap > minSwap && !inSwap) {
                        swapTokensForEth( tokensToSwap > maxSwap ? maxSwap : tokensToSwap);
                    }
                }
            }
        }
        uint256 taxTokens = _tax==99 ? ((amount * 9999) / 10000) : ((amount * _tax) / 100); 
        uint256 transferAmount = amount - taxTokens;
        _balance[from] = _balance[from] - amount;
        if(taxTokens > 0){
            _balance[address(this)] = _balance[address(this)] + taxTokens;
            emit Transfer(from, address(this), taxTokens);
        }
        _balance[to] = _balance[to] + transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function excludeFromAll(address wallet, bool boolean) external onlyOwner {
        _isExcludedFromAll[wallet] = boolean;
    }

    function newTaxes(uint256 bTax, uint256 sTax) external onlyOwner {
        buyTax = bTax;
        sellTax = sTax;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            collection,
            block.timestamp
        );
    }

    function sendEthToCollection() external {
        collection.transfer(address(this).balance);
    }

    function removeAllLimits() external onlyOwner {
        maxWalletAmount = _totalSupply;
    }

    receive() external payable {}
}