// SPDX-License-Identifier: MIT

/**

			░░░░░██╗██╗░░░██╗██╗░█████╗░███████╗
			░░░░░██║██║░░░██║██║██╔══██╗██╔════╝
			░░░░░██║██║░░░██║██║██║░░╚═╝█████╗░░
			██╗░░██║██║░░░██║██║██║░░██╗██╔══╝░░
			╚█████╔╝╚██████╔╝██║╚█████╔╝███████╗
			░╚════╝░░╚═════╝░╚═╝░╚════╝░╚══════╝


                                                  ▒▒▒▒                                
                                                ▒▒▒▒▒                            
                                              ██▒▒▒▒                                    
                                          ████░░▒▒██                                    
                                    ██████░░░░░░▒▒░░████                                
                              ██████░░░░░░░░░░░░░░██████                                
                              ██░░██░░░░░░░░██████░░░░██                                
                              ██░░░░██░░████░░░░░░░░░░██                                
                              ██░░░░░░██░░░░░░░░░░░░░░██                                
                              ██░░░░░░██░░░░░░▓▓░░░░░░██                                
                              ██░░░░░░██░░▒▒▒▒░░▓▓░░░░██                                
                              ██░░░░░░██░░░░░░▒▒▒▒▒▒░░██                                
                              ██░░░░░░██░░░░▒▒▒▒▒▒▒▒▒▒██                                
                              ██░░░░░░██░░░░▒▒▒▒▒▒▒▒▒▒██                                
                              ██░░░░░░██░░░░▒▒▒▒▒▒▒▒▒▒██                                
                              ██░░░░░░██░░░░░░▒▒▒▒▒▒░░██                                
                                ██░░░░██░░░░░░░░░░████                                  
                                  ██░░██░░░░██████                                      
                                    ████████                                            
                                                                                        


                                                            
Socials:
https://www.juice-coin.com/
https://t.me/Juice_Coin
https://twitter.com/Juice_erc20
 
TotalSupply = 50000000
maxTransactionAmount =  1% from total supply
maxWallet =  1% from total supply
Final buy/sell and transfer fee = %5
Tax can be dynamic, but has a ceiling of %15, it's hardcoded, refer to line 321-323.

*/

pragma solidity = 0.8.19;

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
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
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}



//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//--- Contract v2 ---//
contract Juice is Context, Ownable, IERC20 {

    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }


    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    mapping (address => bool) private liquidityAdd;
    mapping (address => bool) private isLpPair;
    mapping (address => uint256) private balance;


   
       uint256 public  maxTransactionAmount = _totalSupply * 1 / 100;  // 1% from total supply maxTransactionAmountTxn
      uint256 public   maxWallet = _totalSupply* 1 / 100; // 1% from total supply maxWallet


    uint256 constant public _totalSupply = 50000000 * 10**18;
    uint256 constant public swapThreshold = _totalSupply / 5_00;
    uint256  public buyfee = 15;
    uint256  public sellfee = 15;
    uint256  public transferfee = 15;
    uint256 constant public fee_denominator = 1_00;
    bool private canSwapFees = true;
    address payable private marketingAddress = payable(0x6da849A5bE2Ba9EdBF8a530a12EB7Fd3be86be87);


    IRouter02 public swapRouter;
    string constant private _name = "Juice";
    string constant private _symbol = "Juice";
    uint8 constant private _decimals = 18;
    address public lpPair;
    bool public isTradingEnabled = true;
    bool private inSwap;

        modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }


  


    constructor () {
        _noFee[msg.sender] = true;

        if (block.chainid == 1 || block.chainid == 5) {
            swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }
        liquidityAdd[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        
     

        lpPair = IFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
        isLpPair[lpPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);
    }
    
    receive() external payable {}

        function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

        function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

        function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
    }

        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
    function isExemptWallet(address account) external view returns(bool) {
        return _noFee[account];
    }

    function setExemptWallet(address account, bool enabled) public onlyOwner {
        _noFee[account] = enabled;
    }

      function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        maxTransactionAmount = newNum * (10 ** 18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        maxWallet = newNum * (10 ** 18);
    }

    function isLimitedAddress(address ins, address out) internal view returns (bool) {

        bool isLimited = ins != owner()
            && out != owner() && msg.sender != owner()
            && !liquidityAdd[ins]  && !liquidityAdd[out] && out != address(0) && out != address(this);
            return isLimited;
    }

      function updateFees(
        uint256 buyfee_,
        uint256 sellfee_,
        uint256 transferfee_
    ) external onlyOwner {
           require(buyfee_ <= 15, " fee on buy cannot be more than 15%");
        require(sellfee_ <= 15, " fee on sell cannot be more than 15%");
            require(transferfee_ <= 15, " fee on transfer cannot be more than 15%");
        buyfee = buyfee_;
        sellfee = sellfee_;
        transferfee = transferfee_;
    }




    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    } 

    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isLimitedAddress(from,to)) {
            require(isTradingEnabled,"Trading is not enabled");
        }

   if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) 
             
            ) {


                     if (
                    isLpPair[from] &&
                    !_noFee[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    isLpPair[to] &&
                    !_noFee[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_noFee[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }

            }




     




        if(is_sell(from, to) &&  !inSwap) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapThreshold) { internalSwap(contractTokenBalance); }
        }

        if (_noFee[from] || _noFee[to]){
            takeFee = false;
        }

        balance[from] -= amount; uint256 amountAfterFee = (takeFee) ? takeTaxes(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);

        return true;

    }


    function takeTaxes(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = buyfee;  else if (issell)  fee = sellfee;  else  fee = transferfee; 
        if (fee == 0)  return amount;
        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) {

            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
            
        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }
        bool success;

        if(address(this).balance > 0) {(success,) = marketingAddress.call{value: address(this).balance, gas: 35000}("");}

    }    
}

//10 21 9 3 5 
//JUICE DEV//