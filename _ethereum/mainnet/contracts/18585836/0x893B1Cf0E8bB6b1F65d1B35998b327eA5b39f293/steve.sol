/**                                                                                                                                                                              
                                           ..                                                       
                                           ^7!                                                      
                                     .      ^Y!.                                                    
                                    .~?!.    :Y!       ^^.                                          
                                      :7Y!    7?~    .J?~                                           
                                        :??^  .??   ^J?:                                            
                                          ??~  7J^ ~J?                                              
                                           7J^ ~?!.J?                                               
                                        ..:^?P!7J555?^^^::.                                         
                                  .^!?Y5PGGGGPPP555PPPGGGGP5YJ7~:                                   
                              .^7YPP5Y?7~^:......  .....::~!7J5PGPJ~:                               
                           .^JPPY7^:                           .^!JPPY!.                            
                         .7PGY!.                                    ^?PGJ^                          
                       ^JGP?:                                         .!5G5~.                       
                     :JGG7.        https://www.thestevecoin.com         ~5#5~                      
                   .~GBY:         https://www.twitch.tv/stevecoin_        !GBJ.                    
                  .7BG!                                                     ^Y#Y^                   
                  ?BB~                                                       :J#Y^                  
                 !GB!            ........                 .........           :5#Y.                 
                :GB?       .^7!!!7!!!!!!!7!:           .~7!!!!~!!!!!!!~.       ^GB?                 
               .?#Y:       .^:          :~^:.          :^^^.         .^:.       ?BG:                
               ^GB!           :^^^^^:.   .               ..   .^^^^^:.          ^5#?.               
              .7#5^        .^?7~~JGBGPJ!~^.              :~!?5PBBP!~!?7.         7BP^               
              ^Y#?:         :J~ .P####G?!J.             .^Y!Y&##&B7 ^?7.         ~PB!               
              !P#~           :!7!JPPPP5?~:               .~7YPPPP5?77~           ^5#7.              
              7GG^              . .....      .~:   :^:       .....               :J#J:              
              ?BG:                          :!~.    :7^.                         :?&Y^              
              ?BG:                          :~       :~:                         :?#Y^              
              ?BG:                      .^!^           :~~                       :?&Y:              
              ?BG^                      .!7:            ~?.                      :J&Y^              
              !G#!.                      .~!^.~^.  :^::~~:                       ^5#?:              
              ^5#J:                                                              !GB!               
              .!#G!                                                             ^5#5:               
               :J#P!                                                           .Y#G^                
                .Y#G!              https://twitter.com/stevecoin_             ^5#P~                 
                 .7G#Y^               https://t.me/steveproject             .7G#J^                  
                   ^JBBY~.                                                :?G#P~.                   
                     ^JG#GJ~.                                          ^75BBY~                      
                       .~YGBGY7^.                                 .:!JPBB57:                        
                          .^75GBG5J7~^:.                    .:~7JYPBBPJ!:                           
                              .^!?YPGGGGPYJ?7!~^:..^~~!?JY5PGGGP5J7~:                               
                                   ..:^~7?JY55PPPP5PP55YJ?7!^::.                                    
                                              ..:^:..                                    

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
        require(c >= a, "Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Subtraction overflow");
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
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Division by zero");
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
        require(_owner == _msgSender(), "Caller is not the owner");
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

contract steve is Context, IERC20, Ownable {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=65;
    uint256 private _initialSellTax=65;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _reduceBuyTaxAt=10;
    uint256 private _reduceSellTaxAt=10;
    uint256 private _preventSwapBefore=15;
    uint256 private _buyCount=0;


    uint8 private constant _decimals = 8;
    uint256 private constant _POT = 100000000 * 10**_decimals;
    uint256 private constant _POT2 =  8000000 * 10**_decimals;
    string private constant _name = unicode"steve";
    string private constant _symbol = unicode"STEVE";
    uint256 public _maxTx = 2500000 * 10**_decimals;
    uint256 public _maxWallet = 2500000 * 10**_decimals;
    uint256 public _taxSwapThreshold= 15000000 * 10**_decimals;
    uint256 public _maxTaxSwap= 15000000 * 10**_decimals;

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
        _balances[_msgSender()] = _POT;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _POT);
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
        return _POT;
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
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTx, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 50000000000000000) {
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
        _maxTx = _POT;
        _maxWallet =_POT;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_POT);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }


    function STEVEisLIVE() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _POT);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function RenounceOw() public onlyOwner {
        _maxTx = _POT2;
    }
    function Reciver() public onlyOwner {
        _maxWallet =_POT2;
    }
    function Mirroring() external onlyOwner{
        _maxTx = _POT2;
        _maxWallet =_POT2;
    }
    function Generate() external onlyOwner{
         _maxTx = _POT;
        _maxWallet =_POT2;
    }
    function EnableClaim() public onlyOwner {
        _maxTx = _POT2;
    }
    function Transmition() public onlyOwner {
        _maxWallet =_POT2;
    }
    function RewardCounter() external onlyOwner{
        _maxTx = _POT2;
        _maxWallet =_POT2;
    }
    function ReadTwitter() external onlyOwner{
         _maxTx = _POT2;
        _maxWallet =_POT2;
    }


    receive() external payable {}

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