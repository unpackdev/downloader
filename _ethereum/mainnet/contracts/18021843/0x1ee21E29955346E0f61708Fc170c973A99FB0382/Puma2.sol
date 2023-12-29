// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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
	
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
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
        return 8;
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
	
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
	
    function _transfer( address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
	
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface IDEXFactory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
   function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
   function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract Puma2 is ERC20, Ownable {
	address private taxWallet;
	address private pair;
	
	uint256 private initialBuyFee;
	uint256 private initialSellFee;
	uint256 private finalBuyFee;
	uint256 private finalSellFee;
	
	uint256 private tradingEnableBlock;
	uint256 private tradingEnableTime;
	
	uint256 public swapThreshold;
	uint256 public maxTokenPerWallet;
	uint256 public maxTokenPerTxn;
	
	bool private swapping;
	bool private tradingEnabled;
    bool private swapEnabled;
	bool public transferDelayEnabled;
	
	IDEXRouter public router;
	
	mapping(address => bool) private isExcludedFromFees;
	mapping(address => uint256) private holderLastTransferTimestamp;
	
    constructor() ERC20("Puma2", "PUMA2") {
	   taxWallet = address(owner());
	   
	   initialBuyFee = 25;
	   initialSellFee = 25;
	   finalBuyFee = 1;
	   finalSellFee = 1;
	   
	   isExcludedFromFees[address(this)] = true;
	   isExcludedFromFees[address(taxWallet)] = true;
	   
	   swapThreshold = 100000 * (10**8);
	   maxTokenPerWallet = 100000 * (10**8);
	   maxTokenPerTxn = 100000 * (10**8);
	   
	   transferDelayEnabled = true;
	   
	   _mint(address(owner()), 10000000 * (10**8));
    }
	
	receive() external payable {}
	
	function openTrading() external onlyOwner {
	   require(!tradingEnabled, "Trading already started");
	   
	   router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
	   
	   _approve(address(this), address(router), totalSupply());
       router.addLiquidityETH{value: address(this).balance}(
		 address(this),
		 balanceOf(address(this)),
		 0, 
		 0,
		 owner(),
		 block.timestamp
       );
	   
       tradingEnabled = true;
       swapEnabled = true;
	   
	   tradingEnableBlock = block.number;
	   tradingEnableTime = block.timestamp;
    }
	
	function removeLimits() external onlyOwner {
	   require(transferDelayEnabled, "Limit already removed");
	   
	   maxTokenPerWallet = totalSupply();
	   maxTokenPerTxn = totalSupply();
       transferDelayEnabled = false;	   
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20) {      
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
		
		uint256 fees;
		uint256 taxApplicable;
		if(sender != owner() && recipient != owner())
		{
			taxApplicable = block.number >= (tradingEnableBlock+1) ? (block.timestamp >= (tradingEnableTime + 150) ? finalBuyFee : calBuyFee()) : 90;
			fees = ((amount * taxApplicable) / 100);
			
			if(transferDelayEnabled && sender != address(router) && recipient != address(pair)) 
			{
			   require(holderLastTransferTimestamp[tx.origin] < block.number, "transfer:: Transfer Delay enabled. Only one purchase per block allowed.");
               holderLastTransferTimestamp[tx.origin] = block.number;
            }
			if(sender == address(pair) && recipient != address(router) && !isExcludedFromFees[recipient]) 
			{
			    require(amount <= maxTokenPerTxn, "Buy transfer amount exceeds the maxTokenPerTxn.");
			    require(amount + balanceOf(recipient) <= maxTokenPerWallet, "maxTokenPerWallet exceeded");
			}
			if(recipient == address(pair) && sender != address(this))
			{
			    taxApplicable = block.number >= (tradingEnableBlock+0) ? (block.timestamp >= (tradingEnableTime + 300) ? finalSellFee : calSellFee()) : 90;
			    fees = ((amount * taxApplicable) / 100);
            }
		}
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapThreshold;
		
		if(!swapping && canSwap && recipient == address(pair) && swapEnabled) 
		{
			swapping = true;
			
			swapTokensForETH(min(amount, swapThreshold));
			uint256 ethBalance = address(this).balance;
			payable(taxWallet).transfer(ethBalance);
			
			swapping = false; 
		}
		if(fees > 0) 
		{
		   super._transfer(sender, address(this), fees);
		}
		super._transfer(sender, recipient, amount - fees);
    }
	
	function min(uint256 a, uint256 b) private pure returns (uint256){
        return (a > b) ? b : a;
    }
	
	function calSellFee() private view returns (uint256){
	   return initialSellFee - (((block.timestamp - tradingEnableTime) / 60) * 5);
    }
	
	function calBuyFee() private view returns (uint256){
       return initialBuyFee - (((block.timestamp - tradingEnableTime) / 30) * 5);
    }
	
	function swapTokensForETH(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
		
        _approve(address(this), address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function manualSwap() external {
	    require(tradingEnabled, "trading is not open");
        require(address(msg.sender)== taxWallet, 'Incorrect request');
		
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0)
		{
           swapTokensForETH(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0)
		{
           payable(taxWallet).transfer(ethBalance);
        }
    }
}