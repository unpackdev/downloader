/**

Twitter     : https://x.com/derp_erc
Telegram    : https://t.me/derpyportal
Website     : https://derpy.world/


#####    #######  ######   ######
 ## ##    ##   #   ##  ##   ##  ##
 ##  ##   ##       ##  ##   ##  ##
 ##  ##   ####     #####    #####
 ##  ##   ##       ## ##    ##
 ## ##    ##   #   ## ##    ##
#####    #######  #### ##  ####


**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

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

contract DerpyCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable public _taxWallet;
    bool public isTransferTaxActive; 

    uint256 public taxRate;
    uint256 private minimumTokensBeforeSwapBackToLP;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 13_370_000 * 10**_decimals;
    string private constant _name = unicode"Derpy World";
    string private constant _symbol = unicode"DERP";
    uint256 public _maxTxAmount =  _tTotal * 200 / 10000;  // 267,400 (2% max) max amt of tokens in a single transaction
    uint256 public _maxWalletSize = _tTotal * 400 / 10000; // 534,800 (4% max) max amt of tokens in wallet
    address public uniswapV2PairAddress;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private inOpenTrading = false;
    bool private inRescueETH = false;                                       
    bool private inRescueTokens = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(0xC740a0Bc8A40c31932162C5131930D32c1B95e15);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        isTransferTaxActive = true;
        taxRate = 30;
        minimumTokensBeforeSwapBackToLP = 40000000000000;

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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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

        uint256 taxAmount=0;
        // if not in special states and not owner, enforce restrictions
        if (!inOpenTrading && !inRescueETH && !inRescueTokens && from != owner() && to != owner() && from != _taxWallet && to != _taxWallet) {

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) { // buy
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            if (to == uniswapV2Pair && from != address(this) && from != address(uniswapV2Router)) { // sell
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            }

            if(isTransferTaxActive) { //if tax is on
                 taxAmount = amount.mul(taxRate).div(100);
            }
        }

        if(taxAmount>0){
            if(taxRate == 2) { //when final tax 2/2
                uint256 halfToWalletTax = taxAmount.div(2); // split the 2%
                uint256 otherHalfToLPTax = taxAmount.sub(halfToWalletTax); // split the 2%

                _balances[_taxWallet] = _balances[_taxWallet].add(halfToWalletTax); // 1% tax to the tax wallet
                emit Transfer(from, _taxWallet,halfToWalletTax);

                _balances[address(this)]=_balances[address(this)].add(otherHalfToLPTax); // 1% tax to the contract
                emit Transfer(from, address(this),otherHalfToLPTax);

                // convert tokens back to LP 
                uint256 contractTokenBalance = this.balanceOf(address(this));
                if (contractTokenBalance >= minimumTokensBeforeSwapBackToLP && !inSwap && swapEnabled && to == uniswapV2Pair) { // minimum amount of tokens needed before swapping
                    inSwap = true;
                    uint256 liquidityTaxForSwap = contractTokenBalance / 2;
                    uint256 liquidityTaxForTokens = contractTokenBalance - liquidityTaxForSwap;

                    uint256 initialBalance = address(this).balance;
                    swapTokensForEth(liquidityTaxForSwap);
                    uint256 newBalance = address(this).balance - initialBalance;
                    addLiquidity(liquidityTaxForTokens, newBalance);
                    inSwap = false;
                }

            } else { //when other tax %
                 _balances[_taxWallet] = _balances[_taxWallet].add(taxAmount);
                emit Transfer(from, _taxWallet,taxAmount);
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private lockTheSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0), // LP tokens are burned, making sure it stays in the pool permanently
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        inOpenTrading = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        inOpenTrading = false;
        uniswapV2PairAddress = uniswapV2Pair;
    }

    function massTransfer(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
        require(_addresses.length == _amounts.length, "Array length not the same");

        for (uint256 i = 0; i < _addresses.length; i++) {
            bool sent = transfer(_addresses[i], _amounts[i]);
            require(sent, "Token transfer failed");
        }
    }

    function setIsTransferTaxActive(bool _isActive) public onlyOwner {
        isTransferTaxActive = _isActive;
    }
    
    function setTaxes(uint16 _taxRate) public onlyOwner {
        taxRate = _taxRate;
    }

    function setMinimumTokensBeforeSwapBackToLP(uint256 _minimumTokensBeforeSwapBackToLP) public onlyOwner {
        minimumTokensBeforeSwapBackToLP = _minimumTokensBeforeSwapBackToLP;
    }

    function rescueLostETH() external {
        require(_msgSender() == _taxWallet, "Only the taxWallet can call this function.");
        inRescueETH = true;
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) {
            payable(_taxWallet).transfer(ethBalance);
        }
        inRescueETH = false;
    }

    function rescueLostTokens() external {
        require(_msgSender() == _taxWallet, "Only the taxWallet can call this function.");
        inRescueTokens = true;
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance > 0){
           _transfer(address(this), _taxWallet, contractTokenBalance);
        }
        inRescueTokens = false;
    }

    receive() external payable {}

    fallback() external payable {}
}