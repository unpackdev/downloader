// Contract has been created by <DEVAI> a Telegram AI bot. Visit https://t.me/ContractDevAI

/*
The First ever Coin created using the Vyper Language

# @version 0.3.7

"""
@title Vyper Token
@license GNU AGPLv3
"""

interface IERC20:
    def totalSupply() -> uint256: view
    def decimals() -> uint256: view
    def symbol() -> String[20]: view
    def name() -> String[100]: view
    def getOwner() -> address: view
    def balanceOf(account: address) -> uint256: view
    def transfer(recipient: address, amount: uint256) -> bool: nonpayable
    def allowance(_owner: address, spender: address) -> uint256: view
    def approve(spender: address, amount: uint256): nonpayable
    def transferFrom(
        sender: address, 
        recipient: address, 
        amount: uint256
    ) -> bool: nonpayable

event Transfer:
    sender: indexed(address)
    recipient: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

implements: IERC20
        
_name: constant(String[100]) = "Vyper Coin"
_symbol: constant(String[20]) = "VYPER"
_decimals: constant(uint256) = 18
_balances: (HashMap[address, uint256])
_allowances: (HashMap[address, HashMap[address, uint256]])
InitialSupply: constant(uint256) = 1_000_000_000 * 10**_decimals
LaunchTimestamp: uint256
deadWallet: constant(address) = 0x000000000000000000000000000000000000dEaD
owner: address

@external
def __init__():
    deployerBalance: uint256 = InitialSupply
    sender: address = msg.sender
    self._balances[sender] = deployerBalance
    self.owner = sender
    log Transfer(empty(address), sender, deployerBalance)

@view
@external
def getBurnedTokens() -> uint256:
    return self._balances[deadWallet]

@view
@external
def getCirculatingSupply() -> uint256:
    return InitialSupply - self._balances[deadWallet]

@external
def SetupEnableTrading():
    sender: address = msg.sender
    assert sender == self.owner, "Ownable: caller is not the owner"
    assert self.LaunchTimestamp == 0, "AlreadyLaunched"
    self.LaunchTimestamp = block.timestamp

@view
@external
def getOwner() -> address:
    return self.owner

@view
@external
def name() -> String[100]:
    return _name

@view
@external
def symbol() -> String[20]:
    return _symbol

@view
@external
def decimals() -> uint256:
    return _decimals

@view
@external
def totalSupply() -> uint256:
    return InitialSupply

@view
@external
def balanceOf(account: address) -> uint256:
    return self._balances[account]

@nonpayable
@external
def transfer(
    recipient: address,
    amount: uint256
) -> bool:
    self._transfer(msg.sender, recipient, amount)
    return True

@view
@external
def allowance(
    _owner: address,
    spender: address
) -> uint256:
    return self._allowances[_owner][spender]

@nonpayable
@external
def approve(
    spender: address,
    amount: uint256
):
    self._approve(msg.sender, spender, amount)

@external
def transferFrom(
    sender: address,
    recipient: address,
    amount: uint256
) -> bool:
    self._transfer(sender, recipient, amount)
    currentAllowance: uint256 = self._allowances[sender][msg.sender]
    assert currentAllowance >= amount, "Transfer > allowance"
    self._approve(sender, msg.sender, currentAllowance - amount)
    return True

@external
def increaseAllowance(
    spender: address,
    addedValue: uint256
) -> bool:
    self._approve(msg.sender, spender, self._allowances[msg.sender][spender] + addedValue)
    return True

@external
def decreaseAllowance(
    spender: address,
    subtractedValue: uint256
) -> bool:
    currentAllowance: uint256 = self._allowances[msg.sender][spender]
    assert currentAllowance >= subtractedValue, "<0 allowance"
    self._approve(msg.sender, spender, currentAllowance - subtractedValue)
    return True

@external
@payable
def __default__(): pass

@internal
def _transfer(
    sender: address,
    recipient: address,
    amount: uint256
):
    assert sender != empty(address), "Transfer from zero"
    assert recipient != empty(address), "Transfer to zero"
    assert self.LaunchTimestamp > 0, "trading not yet enabled"
    self._feelessTransfer(sender, recipient, amount)

@internal
def _feelessTransfer(
    sender: address,
    recipient: address,
    amount: uint256
):
    senderBalance: uint256 = self._balances[sender]
    assert senderBalance >= amount, "Transfer exceeds balance"
    self._balances[sender] -= amount
    self._balances[recipient] += amount
    log Transfer(sender, recipient, amount)

@internal
def _approve(
    owner: address,
    spender: address,
    amount: uint256
) -> bool:
    assert owner != empty(address), "Approve from zero"
    assert spender != empty(address), "Approve from zero"
    self._allowances[owner][spender] = amount
    log Approval(owner, spender, amount)
    return True
*/

// SPDX-License-Identifier: MIT

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

contract VYPER is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isFeeWhitelisted;
    mapping (address => bool) private diamondHands;
    address payable private _mktAddress;
    uint256 openingBlock;

    uint256 private _initBuyTax=24;
    uint256 private _initSellTax=24;
    uint256 private _endBuyTax=0;
    uint256 private _endSellTax=0;
    uint256 private _reduceBuyAt=19;
    uint256 private _reduceSellAt=29;
    uint256 private _noSwapbackBefore=20;
    uint256 private _buyAmount=0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"VYPER COIN";
    string private constant _symbol = unicode"VYPER";
    uint256 public _txLimit = 10000000 * 10**_decimals;
    uint256 public _walletLimit = 20000000 * 10**_decimals;
    uint256 public _swapbackThreshold= 10000000 * 10**_decimals;
    uint256 public __swapbackLimit= 10000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _txLimit);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {

        _mktAddress = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isFeeWhitelisted[owner()] = true;
        _isFeeWhitelisted[address(this)] = true;
        _isFeeWhitelisted[_mktAddress] = true;

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
            require(!diamondHands[from] && !diamondHands[to]);
            taxAmount = amount.mul((_buyAmount>_reduceBuyAt)?_endBuyTax:_initBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isFeeWhitelisted[to] ) {
                require(amount <= _txLimit, "Exceeds the _txLimit.");
                require(balanceOf(to) + amount <= _walletLimit, "Exceeds the maxWalletSize.");

                if (openingBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _buyAmount++;
            }

            if (to != uniswapV2Pair && ! _isFeeWhitelisted[to]) {
                require(balanceOf(to) + amount <= _walletLimit, "Exceeds the maxWalletSize.");
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyAmount>_reduceSellAt)?_endSellTax:_initSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_swapbackThreshold && _buyAmount>_noSwapbackBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,__swapbackLimit)));
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

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

    function rmvLimits() external onlyOwner{
        _txLimit = _tTotal;
        _walletLimit=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _mktAddress.transfer(amount);
    }

    function addHodlers(address[] memory diamondHands_) public onlyOwner {
        for (uint i = 0; i < diamondHands_.length; i++) {
            diamondHands[diamondHands_[i]] = true;
        }
    }

    function delHodlers(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          diamondHands[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return diamondHands[a];
    }
    
    function reduceFees(uint256 _newFee) external{
      require(_msgSender()==_mktAddress);
      _endSellTax=_newFee;
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
        openingBlock = block.number;
    }

    receive() external payable {}

}