// SPDX-License-Identifier: MIT
//https://t.me/soggycoin
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IPancakeRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}


contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyOwner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract SoggyCoin is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address=>bool) MarketMakerPair;
    mapping(address=>bool) isAllowed;
    address routerAddress;
    address factoryAddress;
    IPancakeFactory private pancakefactory;
    IPancakeRouter private pancakerouter;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint8 public buytax=10;
    uint8 public selltax=10; 
    address public marketing;
    event changewallet(address,address);
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_,address _marketing) payable{
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;


        if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        }
        else if (block.chainid==97){
            routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; //Mainnet
        } 
        else if (block.chainid == 1 || block.chainid == 4) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet

        } else {   
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet 
        }
        
        pancakerouter = IPancakeRouter(routerAddress);
        pancakefactory = IPancakeFactory(pancakerouter.factory());
        isAllowed[address(this)] = true;
        isAllowed[owner()] = true;
        isAllowed[_marketing] = true;
        marketing = _marketing;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public  view override returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool)  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 fees;
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapping;
        bool takefee=true;
        address pancakeswapV2Pair = pancakefactory.getPair(address(this), pancakerouter.WETH());
        bool canSwap = contractTokenBalance > 0;
        if(isAllowed[sender] || isAllowed[recipient])
        takefee=false;
        if(canSwap)
        if(!swapping)
        if(takefee)  
        {
            swapping = true;
            swapTokensForEth();
            swapping = false;
        }
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        //SELL
        if(takefee){
        if(selltax!=0)
        if(recipient==pancakeswapV2Pair)
        {
                fees = amount.mul(selltax).div(100);
        }
        // BUY
        if(buytax!=0)
        if(sender==pancakeswapV2Pair)
        {
            fees = amount.mul(buytax).div(100);
        }
        }
        amount = amount.sub(fees);
        _balances[recipient] = _balances[recipient].add(amount);
        _balances[address(this)] = _balances[address(this)].add(fees);

        // Converts the tokens to the WETH and Transfer the fee to the marketing wallet!!!
        
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    require(_balances[_msgSender()] >= amount, "Insufficient Balance");
    return _transfer(_msgSender(), recipient, amount);
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(),spender,amount);
        return true;
    }

    function excludeformFee(address _wallet,bool _val) external onlyOwner{
        isAllowed[_wallet] = _val;
    }

    function changeMarketingwallet(address _newwallet) external onlyOwner{
        marketing = _newwallet;
        emit changewallet(marketing,_newwallet);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function swapTokensForEth() private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakerouter.WETH();

        uint256 tokenAmount = balanceOf(address(this));

        _approve(address(this), address(routerAddress), tokenAmount);

        // make the swap
        try pancakerouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(marketing),
            block.timestamp
        ) {} catch {}
        
    }


    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
    require(_allowances[sender][_msgSender()] >= amount, "No Allowances");
    return _transfer(sender, recipient, amount);
    
    }

    function changeTax(uint8 _buy, uint8 _sell) external onlyOwner{
        //owner cant make tax higher than 10%
        require(_buy<=10,"SAFU");
        require(_sell<=10,"SAFU");
        buytax = _buy;
        selltax = _sell;

    }

    function claimStruck() external onlyOwner{
        _transfer(address(this), address(marketing), balanceOf(address(this)));
    }

    // function _setAutomatedMarketMakerPair(address _pair,bool val) external onlyOwner {
    //     MarketMakerPair[_pair] = val;
    // }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}