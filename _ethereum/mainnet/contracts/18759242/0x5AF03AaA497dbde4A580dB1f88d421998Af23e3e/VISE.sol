//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

interface IERC20 {
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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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


    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

  
    function _tokengeneration(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: generation to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = amount;
        _balances[account] = amount;
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

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



interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract ERC20Burnable is Context, ERC20, Ownable{
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount * 10**decimals());
    }

   
}

contract VISE is ERC20, Ownable, ERC20Burnable {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool public tradingEnabled = false;

    uint256 public ThresholdAmount = 1e6 * 10**18;
    

    address public marketingWallet;
    address public teamWallet;
	address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    struct Taxes {
        uint256 marketing;
        uint256 team;
        uint256 liquidity;       
    }

    Taxes public buyTaxes = Taxes(0, 0, 0);
    Taxes public sellTaxes = Taxes(0, 0, 0);

    mapping(address => bool) public exemptFee;


constructor(address _marketingWallet, address _teamWallet) ERC20("VISE", "VISE") {
    require(_marketingWallet != address(0), "Marketing wallet cannot be zero address");
    require(_teamWallet != address(0), "Team wallet cannot be zero address");

    _tokengeneration(msg.sender, 1e9 * 10**decimals());

    IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

    router = _router;
    pair = _pair;
    marketingWallet = _marketingWallet;
    teamWallet = _teamWallet;
    exemptFee[address(this)] = true;
    exemptFee[owner()] = true;
    exemptFee[marketingWallet] = true;
    exemptFee[teamWallet] = true;
    exemptFee[deadWallet] = true;
}


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom( 
        address sender, 
        address recipient, 
        uint256 amount 
    ) public override returns (bool) { 
        uint256 currentAllowance = _allowances[sender][_msgSender()]; 
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance"); 
        _approve(sender, _msgSender(), currentAllowance - amount); 
 
        _transfer(sender, recipient, amount); 
         
        return true; 
    } 

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer( 
        address sender, 
        address recipient, 
        uint256 amount 
    ) internal override { 
        require(amount > 0, "Transfer amount must be greater than zero"); 
 
        if (!exemptFee[sender] && !exemptFee[recipient]) { 
            require(tradingEnabled, "Trading not enabled"); 
        } 
 
        uint256 feeswap; 
        uint256 fee; 
        Taxes memory currentTaxes; 
 
        if (exemptFee[sender] || exemptFee[recipient] || (sender != pair && recipient != pair)) {
            fee = 0; 
        } else {
            if (recipient == pair) { 
            feeswap = sellTaxes.marketing + sellTaxes.team + sellTaxes.liquidity; 
            currentTaxes = sellTaxes; 
        } else { 
            feeswap = buyTaxes.marketing + buyTaxes.team + buyTaxes.liquidity; 
            currentTaxes = buyTaxes; 
        } 
            fee = ((amount * feeswap) / 10000); 
        } 
 
        if (sender != pair) handle_fees(feeswap, currentTaxes); 
 
        super._transfer(sender, recipient, amount - fee); 
         
        if (feeswap > 0) { 
            super._transfer(sender, address(this), fee); 
        } 
    } 

function handle_fees(uint256 feeswap, Taxes memory swapTaxes) private {

    if(feeswap == 0){
        return;
    }   

    uint256 contractBalance = balanceOf(address(this));
    if (contractBalance >= ThresholdAmount) {
        if (ThresholdAmount > 1) {
            contractBalance = ThresholdAmount;
        }

        
        uint256 denominator = feeswap * 2;
        uint256 tokensToAddLiquidityWith = (contractBalance * swapTaxes.liquidity) / denominator;
        uint256 AmountToSwap = contractBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(AmountToSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - swapTaxes.liquidity);
        uint256 bnbToAddLiquidityWith = (unitBalance * swapTaxes.liquidity);

        if (bnbToAddLiquidityWith > 0) {
            
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        uint256 marketingAmt = (unitBalance * 2 * swapTaxes.marketing);
        if (marketingAmt > 0) {
            payable(marketingWallet).sendValue(marketingAmt);
        }

        uint256 teamAmt = (unitBalance * 2 * swapTaxes.team);
        if (teamAmt > 0) {
            payable(teamWallet).sendValue(teamAmt);
        }

    }
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
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        _approve(address(this), address(router), tokenAmount);

       
        router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, 
            0, 
            deadWallet,
            block.timestamp
        );
    }

    function updateTreshhold(uint256 new_amount) external onlyOwner {
        ThresholdAmount = new_amount * 10**decimals();
    }

    function SetBuyTaxes(
        uint256 _marketing,
        uint256 _team,
        uint256 _liquidity
    ) external onlyOwner {
        require((_marketing + _team + _liquidity ) <= 2500, "Must keep fees at 25% or less");
        buyTaxes.marketing = _marketing;
        buyTaxes.team = _team;
        buyTaxes.liquidity = _liquidity;
    }

    function SetSellTaxes(
        uint256 _marketing,
        uint256 _team,
        uint256 _liquidity
    ) external onlyOwner {
        require((_marketing  + _team + _liquidity ) <= 2500, "Must keep fees at 25% or less");
        sellTaxes.marketing = _marketing;
        sellTaxes.team = _team;
        sellTaxes.liquidity = _liquidity;
    }


    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner {
        router = IRouter(newRouter);
        pair = newPair;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function disableTrading() external onlyOwner {
        require(tradingEnabled, "Trading is already disabled");
        tradingEnabled = false;
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Fee Address cannot be zero address");
        require(newWallet != address(this), "Fee Address cannot be CA");
        marketingWallet = newWallet;
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Fee Address cannot be zero address");
        require(newWallet != address(this), "Fee Address cannot be CA");
        teamWallet = newWallet;
    }

    function updateExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }

    function bulkExemptFee(address[] memory accounts, bool state) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = state;
        }
    }

    function rescueETH() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(owner()).transfer(contractETHBalance);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    // fallbacks
    receive() external payable {}
}