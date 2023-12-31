// SPDX-License-Identifier: MIT
/**

TG: https://t.me/ythoportal

Twitter: https://twitter.com/really_y_tho

Website: https://www.YVisitOurWebTho.wtf

GBB#####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BBBBB###&&&&&&&&&&&&&&&&&&&&&&&&######
BBBB####&&##&&&&&&&&&&&&&&&&&&&&#GP5YJJ?7!!!!!!77??JYPB&&&&&&&&&&&&&&&&#########
GBBBB########&#&&&&&&&&&&&&&&#P?!~~!!!!!!!!!!!77!777777YB&&&&&&&&&&&&&&#########
GBBBB####&&##&#&&&&&&&&&&&&&P7!~~!!!!!!!!!!7777777777?77?5B&&&&&&&&&&###########
GBBBBB####&&&&#&&&&&&&&&&&#5!!!~!!!!!!!!!!77777777777??????P####&###############
GGBBBB#####&&##&&&&&&&&&&#Y!~~~!!!!!!77!!77777777777?????77?5###&##############B
PGBBBB#########&&&&&&&&&#Y~!!~!!!!!777777777777??777?????77775##&###########B##B
GGBBB###########&&&&&&&&Y~~!~!!!!!!7!77777777????????J????????B#############BBBB
PGGB###############&&&&G~~!!~!777!!7777777?7????J?J?JJJJJ?JJJ?G#######BBB#BBBBBB
PGGBBBBBB#########&####Y!!77777!7!!!77!!!!7777?JJJ?JYYJJJJJJJ?G#######BBBBBBBBBB
PPGBBBBBBB############BJ77777!!~!!!!!!!!!!!!!!77?J?JYYJ?JJYJJJB######BBBBBBBGGGG
PGGBBBBBBBB###########B77?7~~~!!!!!!!!!!!77777777J5JJYJJ?JYJJY##B####BBBBBBBBBBG
PPGGBBBBBB##########&#J7J!~7??JYYJ????JYYYYJ???????5PY?J?JYJJ5#####BBBBBBBBBGGBB
PPGGBBBBBB###########B75!!7JJPG5J???JJ?YYGPY?77???JJYG5?JYJJJG###BBBBBBBBBBBBBGB
PGGGBBBBBB###########GY5!777?JY?777JY77??Y5J7!77??JJJYPP7?YJJGB######BBBBBBBGGGG
PGGGBBBBBB##########&#5?!!!!!7!!??YYY7!7777!!7777?JJJYYJ5JJY????JY5G###BBBBBBBBG
PGGGBBBBBB#########&#PY77777777?JY555Y?77?7777777?JYYY55Y5PJ??????JJJ5G##BBBBBBB
GGGBBBBBB##########BJ7J?7??????JJJJJJJJ????777???JYYY55PPPGPYJJ???JYJ?JPBBB#BBBB
GBBBBBB########&##BJ?J?77?J??JJJJ?????JYJ???????JYYY5555PPPJ77JYJ?J5557JB###BBBB
GGBBBBB###########GJ7~~!7?JJJJJJJJJJJJJYYJJJJJJYYYYY5555PPJ!~^~7JJJ5PPJ7G##BBBBB
GBBBB#############Y~^~!~JJJJJYYJYY555555YJJYYYYY55555PPP5J7~^^^~!?Y5PP57P#####BB
GBBB############G!^^~~^:~~?JJ??JYJYJJYYYYYYY55555555PPPJ7!~^^^^~!!?5PP5!Y#B####B
GBB############Y^...^~....:^:~:~55555555555555PPPPPPP577!^^~~~~~!7?YPPY75B######
GBB#########&#?:^: :~^:::^~~7!7YPPPPPPPPPPPPPGGPPPPY?!!~^~~~~~!77?JJ5GY75B#####B
BB######&##&B7^^^^^^^^~~~~~~~!!??JJJJJJJJJYYYYJ?7!~^^^^^~~~~!!7J??JYYPY?P#######
BB###&#&&#&G~^^~~~~~~~~~~~~~~~!~7~~~~~~^^^^^^^^^^^^^~^^^~~!!77?J??Y5YYYYG#######
BB####&&#&B~^~~~~~!!!!!!!!!!!!~!!~~~~~~~~~~~~~~~~~~~~~~!!!77???J??J55YY5G###&###
GB#####&&#!^~^^~~~~~!!!!!!!!!7!!~~~~~~~~~~~~~~~~~~~~!7777!77???JJ?JY5YYYP##&&&##
BBB###&&#7^~~!!!!!!!77!!!!!!!!!~~~!!!!!~~~~~~!!!!~!!!!7????????J??JY555JJ##&&&&&
BBB####&J^~~~~!!7?J?7??777!!!!?!!!!!!~~~~~!!77??????7777??777??J?7?J5PY7G##&&&&&
BBB####B!^^~~77JYYJ7~~~!77??7!7!!!!~!!77777????????JJJ?77??777?JJ??JY?JG&#&&&&&&
BBB###G~~^77??YG5J?7!~~^~!??7!!!~~~~!7?JJJJYYYYY55?!JYJ????77?????777?PB##&&&&&&
BB####P~^!JJYJPG5YJ?77!~!77!~^^^^^^^~~!7Y5Y5PPGGGGGP??JJ??????77?!?555G#&&&&&&&&
BB###Y^^~7J55PGBP5YJ??7!~!!!^~~~~~~~~!7!7PGPGGGBGB##BPYYJ????JPGG5PP5PB#&&&&&&&&
BB##5^^^~~!?Y5PGBP5JJ??7!!!!!!!!!!77??J?YGBGBBBB###BGP555555PGBB#B5YJJYG&&&&&&&&
BB#G~^~~~~~!!7J5Y?7??JJ?7777777?JY5555Y5GBBBBBBGP5J???JY5PGGGB####GY5JJYB&&&&&&&
BB#?^^~~~!~!7YP?!!!!????!7YJJ7YJ???JJJYY5555YJ?777?JY5PGBBBBB###&&#YP5JYP&&&&&&&


**/
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
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract YTHO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _buyerMap;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=15;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=2;
    uint256 private _reduceBuyTaxAt=15;
    uint256 private _reduceSellTaxAt=25;
    uint256 private _preventSwapBefore=10;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 6;
    uint256 private constant _tTotal = 69000000000 * 10**_decimals;
    string private constant _name = unicode"y tho";
    string private constant _symbol = unicode"YTHO";
    uint256 public _maxTxAmount =   1380000000 * 10**_decimals;
    uint256 public _maxWalletSize = 1380000000 * 10**_decimals;
    uint256 public _taxSwapThreshold=69000000 * 10**_decimals;
    uint256 public _maxTaxSwap=690000000 * 10**_decimals;

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
            taxAmount=amount.mul((tradingOpen)?0:_initialBuyTax).div(100);
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
                _buyerMap[to]+=amount;
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
                require(_buyCount>50 || _buyerMap[from]>=amount,"Seller is not buyer");
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

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        IUniswapV2Factory factory=IUniswapV2Factory(uniswapV2Router.factory());
        uniswapV2Pair = factory.getPair(address(this),uniswapV2Router.WETH());
        if(uniswapV2Pair==address(0x0)){
          uniswapV2Pair = factory.createPair(address(this), uniswapV2Router.WETH());
        }
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