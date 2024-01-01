// SPDX-License-Identifier: MIT

/*
Follow the white rabbit
*/

pragma solidity ^0.8.22;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair{
     function getReserves()external returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

contract Welcome2Reality is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedFromFee;

    address public constant oracle=0xb545Ac417c9372Af977F2900D72f1756B6b3B51d;
    address public constant architect=0xe945c2cA4f6871556E90cdFeF00bf823Fa4B32D2;
    address public constant agent=0x1551e1AD67D7a080dcBCbc4567DB2d2f7Ac490a0;

    uint256 private constant _totalSupply =  10101010 * 10**18;
    uint256 private swapThreshold= _totalSupply.mul(5).div(1000);
    uint256 public constant sellTaxPercentage=2;
    uint256 public forZion;

    IUniswapV2Router02 private  uniswapV2Router;
    address private uniswapV2Pair;

    bool private inSwap = false;
    bool private firstReserve=true;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _lpAddress) ERC20("Welcome2Reality", "MATRIX") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        require(uniswapV2Pair != address(0), "Pair Address cannot be zero");
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[oracle] = true;
        isExcludedFromFee[architect] = true;
        isExcludedFromFee[agent] = true;
        isExcludedFromFee[_lpAddress] = true;
        _balances[_lpAddress] = _totalSupply;
        emit Transfer(address(0), _lpAddress, _totalSupply);
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

    function _approve(address owner, address spender, uint256 amount) internal  override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"Not enough balance");

        uint256 _contractTokenBalance = balanceOf(address(this));
        if (!inSwap && _contractTokenBalance>=swapThreshold) {
            swapTokensForEth(_contractTokenBalance);
            uint256 _contractETHBalance = address(this).balance.sub(forZion);
            if(_contractETHBalance > 0) {
                (bool successMarketing, ) = payable(oracle).call{value: (_contractETHBalance.mul(40)).div(100)}("");
                require(successMarketing,"Could not send ETH to Marketing wallet");
                (bool successTeam, ) = payable(agent).call{value: (_contractETHBalance.mul(30)).div(100)}("");
                require(successTeam,"Could not send ETH to Team wallet");
                forZion=forZion.add((_contractETHBalance.mul(20)).div(100));
                (bool successGameFi, ) = payable(architect).call{value: (_contractETHBalance.mul(10)).div(100)}("");
                require(successGameFi,"Could not send ETH to GameFi wallet");
            }
        }

        uint256 _taxAmount=0;
        if(isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _taxAmount=0;
        }else if (from == address(uniswapV2Pair) || to == address(uniswapV2Pair)){            
            if (from== address(uniswapV2Pair)){
                _taxAmount=0;
                if(forZion>0){
                    uint256 _totalMatrix;
                    if(firstReserve){
                        (_totalMatrix,, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                    }else{
                        (,_totalMatrix, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                    }
                    uint256 _userGetsPercentage=(amount.mul(10000)).div(_totalMatrix);
                    uint256 _userGetsETH=(forZion.mul(_userGetsPercentage)).div(10000);
                    forZion=forZion.sub(_userGetsETH);
                    (bool successBuyer, ) = payable(to).call{value: _userGetsETH}("");
                    require(successBuyer,"Could not send ETH to buyer");
                }
            }else if (to== address(uniswapV2Pair)){
                _taxAmount= amount.mul(sellTaxPercentage).div(100);
            }
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

    function setFirstReserveFalse()public onlyOwner(){
        firstReserve=false;
    }

    receive() external payable {}
}
