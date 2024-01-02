/**
Creating enduring liquidity for the world of tokenization.
Pokemak creates sustainable DeFi liquidity and capital efficient markets through a convenient decentralized market making protocol.

Web: https://pokemak.xyz
dApp: https://app.pokemak.xyz
Tg: https://t.me/pokemak_official
X: https://twitter.com/pokemak_tech
Docs: https://medium.com/@pokemak
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

abstract contract ContextLib {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMathLib {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathLib: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathLib: subtraction overflow");
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
        require(c / a == b, "SafeMathLib: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathLib: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMathLib: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface FactoryInterface {
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

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface RouterInterface {
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

contract Ownable is ContextLib {
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

contract POKE is ContextLib, ERC20Interface, Ownable {
    using SafeMathLib for uint256;
    
    string private _name = "Pokemak Protocol";
    string private _symbol = "POKE";
        
    uint8 private _decimals = 9;
    uint256 private _tSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxSz = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshAmount = 10 ** 4 * 10 ** 9; 

    uint256 public feeDividedToLp = 0;
    uint256 public feeDividedToMkt = 10;
    uint256 public feeDividedToDev = 0;
    uint256 public feeDividedToTotal = 10;

    uint256 public lpSellTaxs = 0;
    uint256 public mktSellTax = 23;
    uint256 public devSellTax = 0;
    uint256 public sellFee = 23;

    uint256 public lpbuyTaxs = 0;
    uint256 public mktbuyTaxs = 23;
    uint256 public devbuyTaxs = 0;
    uint256 public buyFee = 23;

    address payable private teamAddress1;
    address payable private teamAddress2;

    RouterInterface public routerInstance;
    address public pairAddress;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromLimit;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;
    mapping (address => bool) public isPairAddress;
    
    bool swapping;
    bool public swapFeeEnabled = true;
    bool public hasMaxTxLimit = false;
    bool public maxMaxWalletEnabled = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _tSupply;
        RouterInterface _uniswapV2Router = RouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = FactoryInterface(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        routerInstance = _uniswapV2Router;
        _allowances[address(this)][address(routerInstance)] = _tSupply;
        teamAddress1 = payable(0x2a05eD8379753016D40604895c9fc5A406C790F5);
        teamAddress2 = payable(0x2a05eD8379753016D40604895c9fc5A406C790F5);
        buyFee = lpbuyTaxs.add(mktbuyTaxs).add(devbuyTaxs);
        sellFee = lpSellTaxs.add(mktSellTax).add(devSellTax);
        feeDividedToTotal = feeDividedToLp.add(feeDividedToMkt).add(feeDividedToDev);
        
        isExcludedFromLimit[owner()] = true;
        isExcludedFromLimit[teamAddress1] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(pairAddress)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[teamAddress1] = true;
        isExcludedFromMaxTx[address(this)] = true;
        isPairAddress[address(pairAddress)] = true;
        emit Transfer(address(0), _msgSender(), _tSupply);
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
        return _tSupply;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerInstance.WETH();

        _approve(address(this), address(routerInstance), tokenAmount);

        // make the swapTaxxed
        routerInstance.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getFinalTokens(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(isPairAddress[sender]) {fee = amount.mul(buyFee).div(100);}
        else if(isPairAddress[recipient]) {fee = amount.mul(sellFee).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    receive() external payable {}
    
    function sendEthFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxSz = _tSupply;
        maxMaxWalletEnabled = false;
        mktbuyTaxs = 3;
        mktSellTax = 3;
        buyFee = 3;
        sellFee = 3;
    }
    
    function swapTaxxed(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(feeDividedToLp).div(feeDividedToTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = feeDividedToTotal.sub(feeDividedToLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(feeDividedToLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(feeDividedToDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendEthFee(teamAddress1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendEthFee(teamAddress2, amountETHDevelopment);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(swapping)
        { 
            return _transferInternal(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTx[sender] && !isExcludedFromMaxTx[recipient]) {
                require(amount <= maxTxSz, "Transfer amount exceeds the maxTxSz.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= swapThreshAmount;
            
            if (minimumSwap && !swapping && isPairAddress[recipient] && swapFeeEnabled && !isExcludedFromLimit[sender] && amount > swapThreshAmount) 
            {
                if(hasMaxTxLimit)
                    swapAmount = swapThreshAmount;
                swapTaxxed(swapAmount);    
            }

            uint256 finalAmount;                                         
            if (isExcludedFromLimit[sender] || isExcludedFromLimit[recipient]) {
                finalAmount = amount;
            } else {
                finalAmount = getFinalTokens(sender, recipient, amount);
            }
            if(maxMaxWalletEnabled && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            uint256 amountToReduce = (!maxMaxWalletEnabled && isExcludedFromLimit[sender]) ? amount.sub(finalAmount) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
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
                
    function _transferInternal(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}