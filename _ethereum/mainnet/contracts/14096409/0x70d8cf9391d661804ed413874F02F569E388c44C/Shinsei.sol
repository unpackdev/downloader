/*
  _________.__    .__                     .__ 
 /   _____/|  |__ |__| ____   ______ ____ |__|
 \_____  \ |  |  \|  |/    \ /  ___// __ \|  |
 /        \|   Y  \  |   |  \\___ \\  ___/|  |
/_______  /|___|  /__|___|  /____  >\___  >__|
        \/      \/        \/     \/     \/    
                                              
                                    shinsei.io
*/
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract Shinsei is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public bots;
    
    uint256 private constant _totalSupply = 1e12 * 10**9;
    
    uint256 private _currentFee;

    uint256 public bFee;
    uint256 public sFee;
    uint256 public teamShare = 60;

    uint256 public maxTxAmount = _totalSupply;


    address payable private _teamAddr;
    address payable private _marketingAddr;
    
    string private constant _name = "Shiba Sensei";
    string private constant _symbol = "SHINSEI";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    
    constructor () {
        _teamAddr = payable(0xF3cB7c5B54AacA7B328B9F02B7F6984574Ce9e8c);
        _marketingAddr = payable(0x224Bf74f69F69E18106e9aFb3DA20ABC5D6D261e);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamAddr] = true;
        _isExcludedFromFee[_marketingAddr] = true;

        bFee = 14;
        sFee = 14;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0x0000000000000000000000000000000000000000), _msgSender(), _totalSupply);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to], "Error: from/to bot");
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    splitETHAndSend(address(this).balance);
                }
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(amount <= maxTxAmount, "Error: amount <= maxTxAmount");
                _currentFee = bFee;
            }else if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
                _currentFee = sFee;
            }else{
                _currentFee = 0;
            }
        }
		
        _tokenTransfer(from, to, amount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
		if (_currentFee > 0) {
		    uint256 feeAmount = amount.mul(_currentFee).div(100);
		    uint256 transferAmount = amount.sub(feeAmount);
            _balances[sender] = _balances[sender].sub(amount);
		    _balances[address(this)] = _balances[address(this)].add(feeAmount);
            _balances[recipient] = _balances[recipient].add(transferAmount);
            emit Transfer(sender, recipient, transferAmount);
		}else{
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
		}
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function splitETHAndSend(uint256 amount) private {
        uint256 getTeamShare = amount.mul(teamShare).div(100);
        _teamAddr.transfer(getTeamShare);
        _marketingAddr.transfer(amount.sub(getTeamShare));
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);

        swapEnabled = true;
        tradingOpen = true;

        maxTxAmount = _totalSupply.mul(3).div(100);

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function liftMaxTx() external onlyOwner() {
        maxTxAmount = _totalSupply;
    }
    
    function setBots(address[] memory bots_) external onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBot(address notbot) external onlyOwner() {
        bots[notbot] = false;
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _teamAddr);

        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _teamAddr);

        uint256 contractETHBalance = address(this).balance;
        splitETHAndSend(contractETHBalance);
    }

    function updateTeamShare(uint256 tShare) external {
        require(_msgSender() == _teamAddr);
        require(tShare <= 60, "Error: Team share cannot exceed 60%");
        
        teamShare = tShare;
    }
    
    function setFee(uint256 newbFee, uint256 newsFee) external {
        require(_msgSender() == _teamAddr, "Caller is not fee setter");
        require(newbFee <= 14, "Error: newbFee cannot exceed 14");
        require(newsFee <= 14, "Error: newsFee cannot exceed 14");
        
        bFee = newbFee;
        sFee = newsFee;
    }

}