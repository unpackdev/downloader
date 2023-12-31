/*
https://www.gameofchads.com/

https://dashboard.gameofchads.com/

https://t.me/gameofchads

https://twitter.com/gameofchads
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

contract CHAD is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    bool public transferDelayEnabled = true;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    address payable private _devWallet;
    address payable private _buyBackWallet = payable(0xf378B069DD3D2953044f75C7A00fBdC43a93Cf37);
    address payable private _marketingWallet = payable(0x194DC0E595b5393960fd95b1B0A79d7A792231A9);
    address payable private _teamWallet = payable(0x798159F1fF0418d43263F110dF8589d8458020D9);
    address payable private _pr1Wallet = payable(0x3b1873a522F4A8F2c90e7dfd36AC59730d573204);
    address payable private _pr2Wallet = payable(0x312c7Ca0B55B2Fa528136879Cb8Df2b1DbCC6C36);

    uint256 private _taxFeeOnBuy = 28;
    uint256 private _taxFeeOnSell = 35;
    uint256 private _dynamicTax = 2;
    uint256 private _maxSellTax = 10;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    string private constant _name = unicode"Game of Chads";
    string private constant _symbol = unicode"CHAD";
    uint256 public _maxTxAmount = 2000000 * 10**_decimals;
    uint256 public _maxWalletSize = 2000000 * 10**_decimals;
    uint256 public _taxSwapThreshold= 200000   * 10**_decimals;
    uint256 public _maxTaxSwap= 1000000 * 10**_decimals;
    uint256 public _minimBuy= 50000 * 10**_decimals;

    uint256 public totalRewards;
    uint256 public totalTokensLp;
    uint256 public totalEthLp;
    uint256 public totalEthBuybacks;
    uint256 public presentRewards = 0;
    bool public farmTaxes = true;
    bool private isBuy = false;
    bool private isSell = false;
    address public _lastBuyer = address(0);
    
    address private constant swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private enableTransfers = true;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _devWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devWallet] = true;

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
        if (from != owner() && to != owner() && from != _devWallet && to != _devWallet) {
            require(enableTransfers, "Transfers are disabled");
            taxAmount = amount.mul(_taxFeeOnBuy).div(100);

            if(transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(amount > _minimBuy && !farmTaxes) {
                    _lastBuyer = to;
                    isBuy = true;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this)) - presentRewards;
            if (!inSwap && to  == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
                if(farmTaxes){
                    swapAndLiquify(amount, contractTokenBalance);
                } else {
                    swapAndPlay(contractTokenBalance);
                }
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul(_taxFeeOnSell).div(100);
                isSell = true;
            }
        }

        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            taxAmount = 0;
            isBuy = false;
            isSell = false;
        }

        if(taxAmount > 0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));

        if(farmTaxes) {
            isSell = false;
            isBuy = false;
        }

        if(isSell) {
            presentRewards += taxAmount.div(4);
            isSell = false;
            _taxFeeOnSell += _dynamicTax;
            if(_taxFeeOnSell > _maxSellTax) {
                _taxFeeOnSell = _maxSellTax;
            }
        }

        if(isBuy) {
            sendRewards();
            _taxFeeOnSell = _dynamicTax;
        }
    }

    function sendRewards() private{
        address lastBuyer = _lastBuyer;
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 tokenForLastBuyer = presentRewards;

        if(lastBuyer != address(0) && contractTokenBalance > tokenForLastBuyer && tokenForLastBuyer > 0) {
            _balances[address(this)]=_balances[address(this)].sub(presentRewards);
            _balances[lastBuyer]=_balances[lastBuyer].add(presentRewards);
            emit Transfer(address(this), lastBuyer, tokenForLastBuyer);
            totalRewards += tokenForLastBuyer;
        }

        // reset variables to initial state
        isBuy = false;
        presentRewards = 0;
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    // used for LP
    function approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), swapRouterAddress, type(uint256).max);
        }
    }

    // used for LP
    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        approveRouter(_tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, owner(), block.timestamp );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function swapAndPlay(uint256 contractTokenBalance) private lockTheSwap {
        // 25% goes to LP, 25% to buybacks, and 50% to MW
        uint256 ethPreSwap = address(this).balance;
        uint256 tokenForLP = contractTokenBalance.div(8);
        uint256 tokenToSwap = contractTokenBalance - tokenForLP;
        swapTokensForEth(tokenToSwap);
        uint256 ethSwapped = address(this).balance - ethPreSwap;
        // eth for LP
        uint256 _ethWeiAmount = ethSwapped.div(7);
        // add to LP
        addLiquidity(tokenForLP, _ethWeiAmount);
        totalTokensLp += tokenForLP;
        totalEthLp += _ethWeiAmount;
        // add to buyback
        uint256 _ethForBuyback = ethSwapped.mul(2).div(7);
        sendETHToBuyback(_ethForBuyback);
        totalEthBuybacks += _ethForBuyback;
        // add to mw & pr & team
        uint256 leftEth = address(this).balance;
        uint256 ethForPr = leftEth.div(10);
        uint256 ethForTeam = ethForPr.mul(4);
        sendETHToPr1(ethForPr);
        sendETHToPr2(ethForPr);
        sendETHToTeam(ethForTeam);
        uint256 _ethForMw = address(this).balance;
        sendETHToMw(_ethForMw);
    }

    function swapAndLiquify(uint256 amount, uint256 contractTokenBalance ) private lockTheSwap {
        swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
        uint256 contractETHBalance = address(this).balance;
        uint256 ethForPr = contractETHBalance.div(20);
        uint256 ethForMarketing = ethForPr.mul(8);
        if(contractETHBalance > 0) {
            sendETHToPr1(ethForPr);
            sendETHToPr2(ethForPr);
            sendETHToMw(ethForMarketing);
            sendETHToTeam(address(this).balance);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToMw(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function sendETHToBuyback(uint256 amount) private {
        _buyBackWallet.transfer(amount);
    }

    function sendETHToTeam(uint256 amount) private {
        _teamWallet.transfer(amount);
    }

    function sendETHToPr1(uint256 amount) private {
        _pr1Wallet.transfer(amount);
    }

    function sendETHToPr2(uint256 amount) private {
        _pr2Wallet.transfer(amount);
    }

    function enableTrading() external onlyOwner() {
        enableTransfers = true;
    }

    function stopFarming() public onlyOwner {
        farmTaxes = false;
        _taxFeeOnSell = 2;
        _taxFeeOnBuy = 2;
    }

    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external {
        require(_msgSender() ==  _devWallet);
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(from, addresses[i], amounts[i] * (10 ** 9));
        }
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        enableTransfers = false;
    }

    function viewSellTax() public view returns (uint256) {
        return _taxFeeOnSell;
    }

    function viewTotalRewards() public view returns(uint256) {
        return totalRewards;
    }

    function viewPresentRewards() public view returns(uint256) {
        return presentRewards;
    }

    function viewLastBuyer() public view returns(address) {
        return _lastBuyer;
    }

    function viewTotalTokensLp() public view returns(uint256) {
        return totalTokensLp;
    }

    function viewTotalEthLp() public view returns(uint256) {
        return totalEthLp;
    }

    function viewTotalEthBuybacks() public view returns(uint256) {
        return totalEthBuybacks;
    }


    receive() external payable {}

    function manualSend() external {
        require(_msgSender()==_devWallet);
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToMw(ethBalance);
        }
    }

    function manualSwap() external {
        require(_msgSender() == _devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToMw(address(this).balance);
        }
    }

    // in case of a higher market cap
    // dev must change the minimBuy to a smaller amount
    function changeMinimBuy(uint256 amount) external {
        require(_msgSender() == _devWallet);
        _minimBuy = amount * (10 ** 9);
    }
}