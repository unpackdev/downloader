// SPDX-License-Identifier: MIT

/*
Website: https://www.alphafi.cloud
Telegram: https://t.me/alpha_erc_portal
Twitter: https://twitter.com/alpha_erc_port
*/

pragma solidity 0.8.19;


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
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }
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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address dexpair);
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


contract ALPHA is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = unicode"ALPHA";
    string private constant _symbol = unicode"ALPHA";

    IDexRouter dexrouter;
    address public dexpair;
    bool private tradeallow = false;
    bool private feeswapallowed = true;
    uint256 private feeswapcounter;
    bool private inswap;
    uint256 feeswapafter;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public addresstotaxexcempt;

    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    uint256 private _maxswapsize = ( _supply * 1000 ) / 100000;
    uint256 private _minswapsize = ( _supply * 10 ) / 100000;

    uint256 private _maxtxamt = ( _supply * 300 ) / 10000;
    uint256 private _maxtransfer = ( _supply * 300 ) / 10000;
    uint256 private _maxwallethold = ( _supply * 300 ) / 10000;

    uint256 private divlp = 0;
    uint256 private divmarketing = 0;
    uint256 private divdev = 100;
    uint256 private divburn = 0;

    uint256 private taxbuy = 1400;
    uint256 private taxsell = 1400;
    uint256 private taxtransfer = 1400;
    uint256 private denominator = 10000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal wallettax = 0x1Ddf5D09654adBEF1b912fCDB43F447444b696D0;
    address internal walletlp = 0x1Ddf5D09654adBEF1b912fCDB43F447444b696D0;
    address internal walletdev = 0x1Ddf5D09654adBEF1b912fCDB43F447444b696D0; 

    modifier lockenter {inswap = true; _; inswap = false;}

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        dexrouter = _router; dexpair = _pair;
        
        addresstotaxexcempt[msg.sender] = true;
        addresstotaxexcempt[walletlp] = true;
        addresstotaxexcempt[wallettax] = true;
        addresstotaxexcempt[walletdev] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}    function startTrading() external onlyOwner {tradeallow = true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function shouldtakefee(address sender, address recipient) internal view returns (bool) {
        return !addresstotaxexcempt[sender] && !addresstotaxexcempt[recipient];
    }    
    
    function swapbackandliquidifytokens(uint256 tokens) private lockenter {
        uint256 _denominator = (divlp.add(1).add(divmarketing).add(divdev)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(divlp).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(divlp));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(divlp);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(divmarketing);
        if(marketingAmt > 0){payable(wallettax).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(walletdev).transfer(contractBalance);}
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxtxamt = newTx; _maxtransfer = newTransfer; _maxwallethold = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getactualfeeamt(address sender, address recipient) internal view returns (uint256) {
        if(recipient == dexpair){return taxsell;}
        if(sender == dexpair){return taxbuy;}
        return taxtransfer;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!addresstotaxexcempt[sender] && !addresstotaxexcempt[recipient]){require(tradeallow, "tradeallow");}
        if(!addresstotaxexcempt[sender] && !addresstotaxexcempt[recipient] && recipient != address(dexpair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxwallethold, "Exceeds maximum wallet amount.");}
        if(sender != dexpair){require(amount <= _maxtransfer || addresstotaxexcempt[sender] || addresstotaxexcempt[recipient], "TX Limit Exceeded");}
        require(amount <= _maxtxamt || addresstotaxexcempt[sender] || addresstotaxexcempt[recipient], "TX Limit Exceeded"); 
        if(recipient == dexpair && !addresstotaxexcempt[sender]){feeswapcounter += uint256(1);}
        if(shouldSwapTaxFee(sender, recipient, amount)){swapbackandliquidifytokens(_maxswapsize); feeswapcounter = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !addresstotaxexcempt[sender] ? getamounttoadd(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function getamounttoadd(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (addresstotaxexcempt[recipient]) {return _maxtxamt;}
        if(getactualfeeamt(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getactualfeeamt(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(divburn > uint256(0) && getactualfeeamt(sender, recipient) > divburn){_transfer(address(this), address(DEAD), amount.div(denominator).mul(divburn));}
        return amount.sub(feeAmount);} return amount;
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexrouter.WETH();
        _approve(address(this), address(dexrouter), tokenAmount);
        dexrouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(dexrouter), tokenAmount);
        dexrouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            walletlp,
            block.timestamp);
    }

    function shouldSwapTaxFee(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minswapsize;
        bool aboveThreshold = balanceOf(address(this)) >= _maxswapsize;
        return !inswap && feeswapallowed && tradeallow && aboveMin && !addresstotaxexcempt[sender] && recipient == dexpair && feeswapcounter >= feeswapafter && aboveThreshold;
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        divlp = _liquidity; divmarketing = _marketing; divburn = _burn; divdev = _development; taxbuy = _total; taxsell = _sell; taxtransfer = _trans;
        require(taxbuy <= denominator.div(1) && taxsell <= denominator.div(1) && taxtransfer <= denominator.div(1), "taxbuy and taxsell cannot be more than 20%");
    }

    receive() external payable {}
}