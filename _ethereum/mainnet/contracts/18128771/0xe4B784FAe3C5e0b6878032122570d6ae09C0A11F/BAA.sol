// SPDX-License-Identifier: MIT

/*
The Babylona Protocol has been crafted as a means to enhance the versatility and liquidity of SUSD (snxUSD) within Synthetix Protocol's V3. This is achieved by establishing a lending market based on vaults, enabling users to engage in lending and borrowing of sUSD(v3) with a wide range of collateral options. Additionally, it offers opportunities for yield farming in Convex LP positions.

Website: https://babylona.pro
Twitter: https://twitter.com/babylona_pro
Telegram: https://t.me/babylona_pro
Medium: https://medium.com/@babylona.protocol
*/

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IDexFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract BAA is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Babylona Protocol";
    string private constant _symbol = unicode"BAA";

    uint8 private constant _decimals = 9;
    uint256 private _tSupply = 1000000000 * (10 ** _decimals);

    IDexRouter routerV2;
    address public pair;

    bool private enabledTrading = false;
    bool private swapActive = true;
    bool private swapping;
    uint256 private taxSwapTimes;
    uint256 private taxSwapAt;

    uint256 private taxSwapLimit = ( _tSupply * 1000 ) / 100000;
    uint256 private taxSwapMin = ( _tSupply * 10 ) / 100000;
    
    uint256 private lpFee = 0;
    uint256 private mktFee = 0;
    uint256 private devFee = 100;
    uint256 private burnFee = 0;

    uint256 private buyFee = 1700;
    uint256 private sellFee = 1700;
    uint256 private transferFee = 1700;
    uint256 private denominator = 10000;

    modifier lockEnter {swapping = true; _; swapping = false;}

    address internal devAdd = 0xFce8Ad9D6E65A0dd99C7c1fc4ac806c6379e5D4a; 
    address internal mktAdd = 0xFce8Ad9D6E65A0dd99C7c1fc4ac806c6379e5D4a;
    address internal lpAdd = 0xFce8Ad9D6E65A0dd99C7c1fc4ac806c6379e5D4a;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _maxTxSz = ( _tSupply * 340 ) / 10000;
    uint256 private _maxSellSz = ( _tSupply * 340 ) / 10000;
    uint256 private _maxHoldingSz = ( _tSupply * 340 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExclude;

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        routerV2 = _router; pair = _pair;

        isFeeExclude[lpAdd] = true;
        isFeeExclude[msg.sender] = true;
        isFeeExclude[mktAdd] = true;
        isFeeExclude[devAdd] = true;
        _balances[msg.sender] = _tSupply;
        emit Transfer(address(0), msg.sender, _tSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function startTrading() external onlyOwner {enabledTrading = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function totalSupply() public view override returns (uint256) {return _tSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tSupply.mul(_buy).div(10000); uint256 newTransfer = _tSupply.mul(_sell).div(10000); uint256 newWallet = _tSupply.mul(_wallet).div(10000);
        _maxTxSz = newTx; _maxSellSz = newTransfer; _maxHoldingSz = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function shouldSwapFeeBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= taxSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= taxSwapLimit;
        return !swapping && swapActive && enabledTrading && aboveMin && !isFeeExclude[sender] && recipient == pair && taxSwapTimes >= taxSwapAt && aboveThreshold;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpFee = _liquidity; mktFee = _marketing; burnFee = _burn; devFee = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAdd,
            block.timestamp);
    }

    function getFinalAmountAfterFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isFeeExclude[recipient]) {return _maxTxSz;}
        if(getFeeDenom(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeDenom(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getFeeDenom(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function swapFeeBack(uint256 tokens) private lockEnter {
        uint256 _denominator = (lpFee.add(1).add(mktFee).add(devFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mktFee);
        if(marketingAmt > 0){payable(mktAdd).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAdd).transfer(contractBalance);}
    }

    function getFeeDenom(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isFeeExclude[sender] && !isFeeExclude[recipient]){require(enabledTrading, "enabledTrading");}
        if(!isFeeExclude[sender] && !isFeeExclude[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxHoldingSz, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= _maxSellSz || isFeeExclude[sender] || isFeeExclude[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxSz || isFeeExclude[sender] || isFeeExclude[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isFeeExclude[sender]){taxSwapTimes += uint256(1);}
        if(shouldSwapFeeBack(sender, recipient, amount)){swapFeeBack(taxSwapLimit); taxSwapTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isFeeExclude[sender] ? getFinalAmountAfterFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}