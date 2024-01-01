// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

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

contract HAARPINU is IERC20, Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isExcludedFromFee;
    uint256 private buySellTax=25;

    address marketingWallet=0xcBfb8A60ca27062011D7145835C1aCf40EFa9B13;

    string constant _name = "HAARP INU";
    string constant _symbol = "$HAARP";
    uint256 constant _decimals = 18;
    uint256 _totalSupply = 1000000000 * (10 ** _decimals);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 public swapThreshold = _totalSupply.mul(5).div(1000);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event LiquidityAdded(uint256 ETHToSwapForLP);


    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }


    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
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
        uint256 _contractTokenBalance = balanceOf(address(this));
        if (!inSwap && _contractTokenBalance>=swapThreshold) {
                swapTokensForEth(_contractTokenBalance);
                uint256 _contractETHBalance = address(this).balance;
                if(_contractETHBalance > 0) {
                    (bool _success, ) = payable(marketingWallet).call{value: _contractETHBalance}("");
                    require(_success,"Could not send ETH to Marketing wallet");
                }
        }
        uint256 _taxAmount;
        if(isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _taxAmount=0;
        }else if (from == address(uniswapV2Pair) || to == address(uniswapV2Pair)){
            _taxAmount= amount.mul(buySellTax).div(100);
        }
        if(_taxAmount>0){
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount.sub(_taxAmount));
            _balances[address(this)] = _balances[address(this)].add(_taxAmount);   
            emit Transfer(from, to, amount.sub(_taxAmount));
        }else{
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);  
            emit Transfer(from, to, amount);

        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
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

    function manualSwap() external onlyOwner{
        uint256 _tokenBalance=balanceOf(address(this));
        if(_tokenBalance>0){
          swapTokensForEth(_tokenBalance);
        }
        uint256 _ethBalance=address(this).balance;
        if(_ethBalance>0){
            (bool _success, ) = payable(owner()).call{value: _ethBalance}("");
            require(_success,"Could not send ETH to Owner");
        }
    }

    function setBuySellTax(uint256 _tax)external onlyOwner{
        buySellTax=_tax;
    }
    receive() external payable {}
}