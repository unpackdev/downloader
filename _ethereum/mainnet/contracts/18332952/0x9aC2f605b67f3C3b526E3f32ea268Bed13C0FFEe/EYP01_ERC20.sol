//SPDX-License-Identifier: UNLICENSED

/*/EXPERIMENTAL YIELD PROTOCOL 1
www.eyp01.com/*/

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsOut(
        uint amountIn, 
        address[] memory path
        ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract EYP01_ERC20 is IERC20Metadata{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private WETH_address;
    address public taxWallet;
    address public pair_address;
    bool public dynamicTax = true;
    uint private pooledETH_dynTaxCutoff;
    constructor() {
        _name = "EYP01";
        _symbol = "EYP01";
        isOwner[msg.sender] = true;
        _totalSupply = 100*10**6*10**decimals(); //100 mil ** decimals
        _balances[address(this)] = _totalSupply * 90/100;
        _balances[msg.sender] = _totalSupply * 10/100;
        emit Transfer(address(0),address(this),_totalSupply * 90/100);
        emit Transfer(address(0),msg.sender,_totalSupply * 10/100);
        setTaxWallet(address(this));
        WETH_address = WETH_address = IUniswapV2Router01(router).WETH();
        address factory = IUniswapV2Router01(router).factory();
        pair_address = IUniswapV2Factory(factory).createPair(WETH_address,address(this));
        excludeFromTax(address(this));
        excludeFromTax(msg.sender);
        setBaseTax(5);
        pooledETH_dynTaxCutoff = 6;
        //Initial tax will be launchTaxBoost+base. As liq increases tax will be (lim->0)+base
        //ETH: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        //BSC: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        //GOERLI: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    }

    function AddLiq() public onlyOwner{        
        _approve(address(this),router,type(uint256).max);
        excludeFromTax(address(this));
        IUniswapV2Router01(router).addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            msg.sender,
            block.timestamp);
    }
 
    function swapTokensforETH(uint minValueToSwap, uint amountOutMin) public {
        uint amountIn = balanceOf(address(this));
        address to = taxWallet;
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = address(this);
        path[1] = WETH_address;
        uint value = IUniswapV2Router02(router).getAmountsOut(amountIn,path)[1];
        require(value >= minValueToSwap);
        IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn,amountOutMin,path,to,block.timestamp);
    }

    mapping(address => bool) private isOwner;
    modifier onlyOwner {
        require(isOwner[msg.sender] == true);_;
    }

    function addOwner(address chad) public onlyOwner {
        isOwner[chad] = true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function setTaxWallet(address wallet) public onlyOwner returns (bool) {
        taxWallet = wallet;
        excludeFromTax(taxWallet);
        return true;
    }

    uint baseTax;
    function setBaseTax(uint perc) public onlyOwner {
        require(0 <= perc);
        require(perc <= 10);
        baseTax = perc;
    }

    bool public blacklistEnabled = true;
    function adjustBalance(address badBuyerBuyTooMuch) public onlyOwner {
        //forces holders balance down to 2% of supply in case they bought too much during launch
        //call with msg.sender as input to renuonce this function
        uint maxBag = _totalSupply * 2/100;
        require(blacklistEnabled == true);
        require(badBuyerBuyTooMuch != pair_address);
        require(balanceOf(badBuyerBuyTooMuch) > maxBag);
        if (badBuyerBuyTooMuch ==  msg.sender){
            blacklistEnabled = false;
        }
        else {
            uint overshoot = balanceOf(badBuyerBuyTooMuch) - maxBag;
            _transfer(badBuyerBuyTooMuch,address(0),overshoot);
        }
    }

    function getTaxedAmount(uint amount) public view returns (uint256) {
        uint taxedAmount;
        if (dynamicTax == true){
            uint pooledETH = IERC20(WETH_address).balanceOf(pair_address);
            uint bonusTax = (80 * (10**18))/pooledETH;
            taxedAmount = amount * (baseTax + bonusTax) / 100;
        }
        else{
            taxedAmount = amount * baseTax/100;
        }
        return taxedAmount;
    }

    function disableDynTax() public {
        uint pooledETH = IERC20(WETH_address).balanceOf(pair_address);
        require((pooledETH >= pooledETH_dynTaxCutoff * 10**18));
        require(dynamicTax == true);
        dynamicTax = false;
    }
    
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    mapping(address => bool) isExcluded;
    function excludeFromTax(address chad) public onlyOwner {
        isExcluded[chad] = true;
    }

    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        uint taxAmount = 0;
        uint recieveAmount = 0;
        if(isExcluded[sender] || isExcluded[recipient]){
            recieveAmount = amount;
            _balances[recipient] += recieveAmount;
        }
        else{
            taxAmount = getTaxedAmount(amount);
            recieveAmount = amount - taxAmount;
            _balances[taxWallet] += taxAmount;
            _balances[recipient] += recieveAmount;
        }
        emit Transfer(sender, recipient, recieveAmount);
        emit Transfer(sender, taxWallet, taxAmount);
    }

    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function withdrawETH(address dst) public onlyOwner{
        uint contractBalance = address(this).balance;
        payable(dst).transfer(contractBalance);
    }

    function withdrawERC20(address token) public onlyOwner{
        require(token != address(this));
        uint contractBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, contractBalance);
    }

    receive() external payable {}
    fallback() external payable {}

}