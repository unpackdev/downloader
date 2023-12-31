//SPDX-License-Identifier: MIT

// WEB: https://www.babaerc.com
// X: https://twitter.com/babacoineth
// TELEGRAM: https://t.me/BabaErc


pragma solidity 0.8.20;


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

    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) external returns (bool);

}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;

    string private _symbol;

    constructor(string memory name_, string memory symbol_) {

        _name = name_;

        _symbol = symbol_;

    }

    function name() public view virtual override returns (string memory) {

        return _name;

    }

    function symbol() public view virtual override returns (string memory) {

        return _symbol;

    }

    function decimals() public view virtual override returns (uint8) {

        return 18;

    }

    function totalSupply() public view virtual override returns (uint256) {

        return _totalSupply;

    }

    function balanceOf(address account) public view virtual override returns (uint256) {

        return _balances[account];

    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {

        address owner = _msgSender();

        _transfer(owner, to, amount);

        return true;

    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {

        return _allowances[owner][spender];

    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {

        address owner = _msgSender();

        _approve(owner, spender, amount);

        return true;

    }

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) public virtual override returns (bool) {

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        _transfer(from, to, amount);

        return true;

    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        address owner = _msgSender();

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;

    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        address owner = _msgSender();

        uint256 currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {

            _approve(owner, spender, currentAllowance - subtractedValue);

        }

        return true;

    }

    function _transfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {

        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {

            _balances[from] = fromBalance - amount;

            _balances[to] += amount;

        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);

    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;

        unchecked {

            _balances[account] += amount;

        }

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);

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
    function _spendAllowance(

        address owner,

        address spender,

        uint256 amount

    ) internal virtual {

        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {

            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            unchecked {

                _approve(owner, spender, currentAllowance - amount);

            }

        }

    }
    function _beforeTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}
    function _afterTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

}

interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}



contract baba is ERC20, Ownable {
    
    mapping(address => bool) private excluded;

    address treasuryWallet = 0x362c074fba4475571a71907bCafb5D2a7110bBF7;
    address public devWallet = 0x5c55C8B8442102fd533ED047122Ce37eA47418B5;
    DexRouter public immutable uniswapRouter;
    address public immutable pairAddress;

    bool public tradingEnabled = false;
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;

    uint256 public constant _totalSupply = 1000000 * 1e18;

    struct taxes {
    uint256 marketingTax;
    }

    taxes public transferTax = taxes(0);
    taxes public buyTax = taxes(15);
    taxes public sellTax = taxes(15);

    uint256 public maxWallet = 2;
    uint256 public swapTokensAtAmount = (_totalSupply * 5) / 1000;


    event BuyFeesUpdated(uint256 indexed _trFee);
    event SellFeesUpdated(uint256 indexed _trFee);
    event devWalletChanged(address indexed _trWallet);
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Exclude(address indexed _target, bool indexed _status);
    event MaxWalletChanged(uint256 percentage);

    constructor() ERC20("baba", "BABA") {


       uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        excluded[msg.sender] = true;
        excluded[address(this)] = true; 
        excluded[address(treasuryWallet)] = true;
        excluded[address(devWallet)] = true;
        excluded[address(uniswapRouter)] = true;      
        
        _mint(msg.sender, _totalSupply);
 
    }

    function tradeEnable() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function handleTaxes(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (excluded[_from] || excluded[_to]) {
            return _amount;
        }

        uint256 totalTax = transferTax.marketingTax;

        if (_to == pairAddress) {
            totalTax = sellTax.marketingTax;
        } else if (_from == pairAddress) {
            totalTax = buyTax.marketingTax;
        }


        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }


    function internalSwap() internal {
        isSwapping = true;
        uint256 taxAmount = balanceOf(address(this)); 
        if (taxAmount == 0) {
            return;
        }
        swapToETH(balanceOf(address(this)));
        uint256 marketingSwapAmount = (address(this).balance)/2;
        uint256 treasurySwapAmount = (address(this).balance)/2;
       payable(devWallet).transfer(marketingSwapAmount);
       payable(treasuryWallet).transfer(treasurySwapAmount);
        isSwapping = false;
    }


    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(
    address _from,
    address _to,
    uint256 _amount
) internal virtual override {
    require(_from != address(0), "transfer from address zero");
    require(_to != address(0), "transfer to address zero");
    require(_amount > 0, "Transfer amount must be greater than zero");

    // Calculate the maximum wallet amount based on the total supply and the maximum wallet percentage
    uint256 maxWalletAmount = _totalSupply * maxWallet / 100;

    // Check if the transaction is within the maximum wallet limit
    if (!excluded[_from] && !excluded[_to] && _to != address(0) && _to != address(this) && _to != pairAddress) {
        require(balanceOf(_to) + _amount <= maxWalletAmount, "Exceeds maximum wallet amount");
    }

    uint256 toTransfer = handleTaxes(_from, _to, _amount);

    bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
    if (!excluded[_from] && !excluded[_to]) {
        require(tradingEnabled, "Trading not active");
        if (pairAddress == _to && swapAndLiquifyEnabled && canSwap && !isSwapping) {
            internalSwap();
        }
    }

    super._transfer(_from, _to, toTransfer);
}

    function disableLimits() external onlyOwner{
        maxWallet = 100;
        transferTax.marketingTax = 0;
    }

    function setsellTax(uint256 _marketingTax) external onlyOwner {
        sellTax.marketingTax = _marketingTax;
        require(_marketingTax <= 20, "Can not set sell fees higher than 20%");
        emit SellFeesUpdated(_marketingTax);
    }

    function setbuyTax(uint256 _marketingTax) external onlyOwner {
        buyTax.marketingTax = _marketingTax;
        require(_marketingTax <= 20, "Can not set buy fees higher than 20%");
        emit BuyFeesUpdated(_marketingTax);
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount > 0 && _newAmount <= (_totalSupply * 5) / 1000,
            "Minimum swap amount must be greater than 0 and less than 0.5% of total supply!"
        );
        swapTokensAtAmount = _newAmount;
        emit SwapThresholdUpdated(swapTokensAtAmount);
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
    maxWallet = amount;
    emit MaxWalletChanged(amount);
    }

    function setExcludedAddress(
        address _address,
        bool _stat
    ) external onlyOwner {
        excluded[_address] = _stat;
        emit Exclude(_address, _stat);
    }

    function checkExcluded(address _address) external view returns (bool) {
        return excluded[_address];
    }

    function withdrawStuckToken() external {
        require(msg.sender == devWallet);
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawStuckETH() external {
        require(msg.sender == devWallet);
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }


    receive() external payable {}
}