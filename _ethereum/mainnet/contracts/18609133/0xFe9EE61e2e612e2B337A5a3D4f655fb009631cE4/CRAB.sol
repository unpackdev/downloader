// SPDX-License-Identifier: UNLICENSED
/*
    Telegram -   https://t.me/crabcoinerc20
    CRABsite -   https://crabcoinerc20.com/
    Twitter  -   https://twitter.com/crabcoinerc20
*/
/*                                                                                                        
  _              _                _              _              _             
 /  | o  _ |    /  |  _.  _ |    /  | o  _ | __ /  | o  _ |    /  |  _.  _ |  
 \_ | | (_ |<   \_ | (_| (_ |<   \_ | | (_ |<   \_ | | (_ |<   \_ | (_| (_ |< 
                                                                              
*/            
/*                                                                                                                        
                                                      ...~^7:                                       
                                                .:^~!!!~~?7?7!!~^.                                  
                                       .?7?!~~~~~^:.          .:^7?.                                
                                  :^~~~~~~~:..                    :5:                               
                               :~!~:.                             .^!!^
                             .#?          $CRAB                   .^!!^
                           .^!!^.                                ~B#.                               
                           !P~                              .^75#@B^                                
                           J:         .::^^~!7777!!!7?JYY5PB#@@&GJ^                                 
                           Y^        .^~!!^.?7??7?YGPPGB#&&&@5^.                   
                           ^GY77JP.75!:J..?.J: 7~ !!7 ^7:7!.77                  
                            .~?5PP~5Y7^?  . 7?~J:.? J:7?!7: ~~                 
                                .J!J5?!J^^!^77.7~!?^?7!!^?: ?.              
                                :?7~YJ:  ^5!?Y??~~: :!7: !7 !~                
                                 ^7557    !Y5YGG?7!~??J7~^. ~!                
                                 ^7^5!    .5YYYYYY5577JPJ^  ~!                  
                                 :? !7     J5YYYYYP^   ^G5Y7J?~:                      
                                 :JJP5..   5YYYYYYP^ ^. Y5YPBGJ7                                    
                                 .G5YP^7. ^PYYYYYYYY::.^GYYY55G?                                    
              .^~!!!?J?7~^:     ^J5YYY57?Y5YYYYYYYYYPYYGPYYYYYY5Y?~:.    .!JJ??JYJ?!~^.             
           .~J555555YYYY5YP~   !G5YYYYY5YYYYYYYYYYYYYY5YYYYYYYYYYGJ?^   .P5YYYYYYYY5555J^           
         .JP55YYYYYYYYYYY5Y.  ^P5Y555YY5555555YYYY55YYY5YYYJJ??5YJPG7!   755YYYYYYYYYYYYPJ.         
        :YPYYYYYYYYYYYYY5Y.  :5Y~~?~~!^^^?~^^~^..:^!^^^!~::!^:~~PYYYG~    .75YYYYYYYYYYYY55?:       
      .YP5YYYYYYYYYYYYYGGYJ  YP?..~.:!:::!:::!~:::^!.:.:^..: .!Y5YYYYP~   !JPGGYYYYYYYYYYYY55?      
      PGYYYYYYYYYYYYY5BPYYG! ?55J~:.:!   ^   :.    ^ ..:^~~7JY5YYYYYYYP^ .GYYY5PPYYYYYYYYYYYYP?     
     :#YYYYYYYYYYYYGP55YYYYG. ^5Y5555P5YJJJ???????JYYYYY555YYYYYYYYYYYYP.^GYYYYY5PP5YYYYYYYYYYG~    
     :BYYYYYYYYY555G5YYYYYYG.  JP55YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYP~YPYYYYYYYYPPYYYYYYYYYYP:   
     .GYYYYYYYYYP5PPYYYYYYP5 :?5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYP?~GYYYYYYYY5G5P5YYYYYYY5J   
      ?PYYYYYYYYYYYYYYYYYPY.~PYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5GG! ~G5YYYYYYY5YY55YYYYYY5J   
       ?B5YYYYYYYYYYY55YJ!~JBYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5G?: :J555YYYYYYYYYYYYYYY5:   
        ~Y555YYY5PJJYJ7?JY5PGYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5YYY55Y7^:~7Y55YYYYYYYYYYYP^    
          :~^JPYYYYJYY555PGGBYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY555PGP5YYYY5Y?!!YGPPP555555YJ^     
              7YP55555YYBP5Y5GPYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PPYJ5PGPYYYYYYYYYY5PP~^^:.       
                :^^::..YYYY5Y77GP5YYYYYYYYYYYYYYYYYYYYYYYYYY55GPY5YYY55^:!5BP5555555J!^             
                      ^PYY5?. ~GY5P5Y55YYYYYYYYYYYYYYYYY555YJ!^. ^J5YY5P   !P55P!...                
                      ~PYYP.  !GJYP~.^!?JJY555555Y55YYJ?!~:        Y5YYG.   5YY5!                   
                      !PY5?   :GYYP~       .........               Y5Y55    7PY57                   
                      :5JP^    !PJP!  ..::::::.::^^~^^:::::::::::..5YYP:    :PJ5:                   
                     .^5GBJJYPGB@#&####&&&&&&&&&@@@@@@@&&&&&&&&&&&&&B#&BBGGGG#BB~                   
                     ~Y5PPP5PPGB#####&&@@@@@@&@@@@@&&&&&&&&&&&&&&&&&&&&&&#BG5YJ?~                   
                                 .....::::::::::^::::...::::::...:::......                          
*/                                                                                                                                                                                                                                                                                                                                                                                                   
//
pragma solidity 0.8.18;

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

contract CRAB is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    mapping(address => uint256) private cooldownTimer;
    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 1;

    address payable _devWallet;

    uint256 private _initialBuyTax = 21;
    uint256 private _initialSellTax = 21;
    uint256 private _finalBuyTax = 0;
    uint256 private _finalSellTax = 0;
    uint256 private _reduceBuyTaxAt = 21;
    uint256 private _reduceSellTaxAt = 21;
    uint256 private _preventSwapBefore = 21;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000000 * 10 **_decimals;
    string private constant _name = unicode"CRAB";
    string private constant _symbol = unicode"CRAB";
    uint256 public _maxTxAmount = 20000000000 * 10 **_decimals;
    uint256 public _maxWalletSize = 20000000000 * 10 **_decimals;
    uint256 public _taxSwapThreshold = 0 * 10 **_decimals;
    uint256 public _maxTaxSwap= 15500000000 * 10 **_decimals;

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
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled. Only one purchase per block allowed.");
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
            if (from == uniswapV2Pair && buyCooldownEnabled && ! _isExcludedFromFee[to]) {
                require(
                    cooldownTimer[to] < block.timestamp,
                    "buy Cooldown exists"
                );
                cooldownTimer[to] = block.timestamp + cooldownTimerInterval;
            }
        }

        if(taxAmount>0) {
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this), taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
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
 

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }
    

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }
         function sendETHToFee(uint256 amount) private {
        _devWallet.transfer(amount);
    }

    function removeTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function transferETHToDev() external onlyOwner() {
        require(address(this).balance > 0, "No ETH to transfer");
        _devWallet.transfer(address(this).balance);
    }
}