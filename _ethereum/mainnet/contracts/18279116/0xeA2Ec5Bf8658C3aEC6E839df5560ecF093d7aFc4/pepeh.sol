/*

Website: https://halloweenpepe.biz
Telegram: https://t.me/PepeHPortal
Twitter: https://twitter.com/PEPEHeth


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGP5YYJJJJYY5PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&BPJ?7!!!!77????????77!!!!7?JPB&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&GJ7~!7?JYYY555555YYYY55555YYYYJ?7!!7JG&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#57~!?JY55YYYYYYYYYYYYYYYYYYY555YYYYYYYJ?!~75#@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&5!~!JY55YYYYYYYYYYYYYYYYYYYYYY5GGBP555PP5Y55YJ!~7P&@@@@@@@@@@@@@@
@@@@@@@@@@@@#J^~JY5YYYYYYYYYYYYYYYYYYYYYYYYYYYYY55GP5PPP5YYYY5Y?~~J#@@@@@@@@@@@@
@@@@@@@@@@#?^!Y5YYY5PP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5Y!^?#@@@@@@@@@@
@@@@@@@@@Y^!5GBGPPPGGGPYYYYYYYYYYYYYYYYYY55P5YYYYYYYYYYYYYYYYYYYYY5Y!^Y@@@@@@@@@
@@@@@@@B~^J555555PPYYYYYYYYYYYYYYYYYYYYYY5PPPPYYYYYYYYYYYYYYYYYYYYYY5J^~B@@@@@@@
@@@@@@5:75YYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJY5PP5YJJYYYYYYYYYYYYYYYYYYYY57:5@@@@@@
@@@@@J.J5YYYYYYYYYYYYYYYYYYYYYYYYYYYYJ??????JJ??????JY5YYYYYYYYYYYYYYYY5J.J@@@@@
@@@@?.J5YYYYYYYYYYYYYYYYYYYYYYYYYYYJ????77!~~~!7?77!!!?YYYYYYYYYYYYYYYYY5J.J@@@@
@@@Y.J5YYYYYYYYYYYYYYYYYYYY55555YJJ???!:    ^?..:   .?~ ?YYYYYYYYYYYYYYYY5J.5@@@
@@B.?5YYYYYYYYYYYYYYYY5PPPPPPPP5JJ????77!^::^!^!!^^:^!!!YYYYYYYYYYYYYYYYYY57.#@@
@@!^5YYYYYYYYYYYYYYYPGPP555555YJJJ????????????????????YPPGP555YYYYYYYYYYYYY5:!@@
@B JYYYYYYYYYYYYYYYGGP55555555JJJ?????????????????????J55Y77?JY5YYYYYYYYYYY5? B@
@J:YYYYYYYYYYYYYYYYPGPPP555555JJJ?????YYYYYYYJJJJJJJJYYY??~!!:^!5YYYYYYYYYYYY.J@
@!~5YYYYYYYYYYYYYYYY5GGPPP55555J???????JJJYYYYYYYY55YY57~!77!^^~Y5YYYYYYYYYY5^!@
@^!5YYYYYYYYYYYYYY5PPPGBGPPPPP&#PYJ????7777777??J?77?JG5J7!~?!^!5YYYYYYYYYYY5~^@
@^!5YYYYYYYYYYYYY5BJ?5GBBBBGGPGB#BBBBGGGPPPPPPG#B5YYPP55PJ??JJ?Y5PBBGP5YYYYY5~~@
@!~5YYYYYY55PP5YYYGPGBGGGGGBBBGGB5YGBBY?J##BPGGBPPG5P5?5PGPJJPPGGGP55YYYYYYY5^!@
@J:YYYYYY5PGGBBPP5PBBBBGGGGGGGGBGGBP5G5J5P7:!?JJJYP5YP5GJ5GBPPPGPYYYYYYYYYYYY.Y@
@B ?YYYYYYYYYY5PGGPPPPGGGGGBBBBBGGBPPGGGP?!7J5J???????YYJY5Y5PYYYYYYYYYYYYY5?.#@
@@!^5YYYYYYYYYYYYYYYYYYYYY5BGGBGGGGGGGBG????YBG5???????JJ????5PYYYYYYYYYYYY5:7@@
@@B.75YYYYYYYYYYYYYYYYYYYYGBGGBGGGGGGGB5????J5YJ??????YBPY???YGYYYYYYYYYYY57.#@@
@@@5.J5YYYYYYYYYYYYYYYYYYPBGGBBGGGGGGPBP????5B5PGP55??J55YY5JJ5P5YYYYYYYY5J.5@@@
@@@@J.J5YYYYYYYYYYYYYYYYYGBGGBBGGGGGG5GBY?JJ?5GP5555PBB5??GJ!!!5PYYYYYYY5J.J@@@@
@@@@@J.J5YYYYYYYYYYYYYYYPBGGGBBGGGGGGGGBGPGPYYJYY55555J???YP5Y5PYYYYYYY5?.Y@@@@@
@@@@@@5:75YYYYYYYYYYYYYYBBGGGBBBBBBBBBBBBBBBBBGP5Y55YJJYJJ5P555YYYYYYY57:5@@@@@@
@@@@@@@B~^J5YYYYYYYYYYY5BGGGGGBGGGGGGGGBGGGGGGGGBBBBGGBGPP5YYYYYYYYY5J^~B@@@@@@@
@@@@@@@@@Y^!Y5YYYYYYYYYYPGBBBGBBGGGGGGBBBGGGGGGGBGBBBBPYYYYYYYYYYY5Y!^Y@@@@@@@@@
@@@@@@@@@@#?^!Y5YYYYYYYYYY5PPGGBGGGGGGBBBBGGGGGBGGPP55YYYYYYYYYY5J!^J&@@@@@@@@@@
@@@@@@@@@@@@#J~~?Y5YYYYYYYYYYYYPBGGGGBP5PBGGGGBPYYYYYYYYYYYYY5Y?~~J#@@@@@@@@@@@@
@@@@@@@@@@@@@@&P7~!JY55YYYYYYYYYPGBBBGP55GBBBGPYYYYYYYYYY55YJ!~7P&@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#57~!7JY55YYYYYYY55555555555YYYYYYY555YJ7!~75#@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&GJ7!!7?JYYY555YYYYYYYYY5555YYYJ?7!!7YG&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&BPY?7!!!!777??????777!!!!7?YP#&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BGP55YYJJYY55PGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/
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

contract pepeh is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _buyerMap;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=18;
    uint256 private _initialSellTax=35;
    uint256 private _finalBuyTax=2;
    uint256 private _finalSellTax=2;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=30;
    uint256 private _preventSwapBefore=30;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 400000000000000 * 10**_decimals;
    string private constant _name = unicode"Halloween Pepe";
    string private constant _symbol = unicode"PEPEH";
    uint256 public _maxTxAmount =   1200000000000 * 10**_decimals;
    uint256 public _maxWalletSize = 8000000000000 * 10**_decimals;
    uint256 public _taxSwapThreshold=1000000000000 * 10**_decimals;
    uint256 public _maxTaxSwap=3200000000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
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
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_buyCount<_preventSwapBefore){
                  require(!isContract(to));
                }
                _buyCount++;
                _buyerMap[to]=true;
            }


            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            if(to == uniswapV2Pair && from!= address(this) ){
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
                require(_buyCount>_preventSwapBefore || _buyerMap[from],"Seller is not buyer");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
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

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function boo() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    
    
    
}