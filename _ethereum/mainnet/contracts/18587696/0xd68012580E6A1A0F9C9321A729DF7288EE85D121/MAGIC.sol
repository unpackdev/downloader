/*
Telegram: https://t.me/PepeMagicerc
Twitter : https://x.com/PepeMagicerc
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

interface IDexSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexSwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

error ERC20InvalidSender(address sender);
error ERC20InvalidReceiver(address receiver);
error ERC20InvalidApprover(address approver);
error ERC20InvalidSpender(address spender);
error ERC20TransferFailed();
error ERC20ZeroTransfer();
error PaymentFailed();

contract MAGIC is Context, IERC20, Ownable {

    using SafeMath for uint256;

    address private developmentWallet;

    uint256 initalBuyTax  = 30;
    uint256 initalSellTax = 30;
    uint256 finalBuyTax   = 2;
    uint256 finalSellTax   = 2;
    
    string private _name = "PEPE MAGIC";
    string private _symbol = "MAGIC";
    uint8 private _decimals = 18; 

    uint256 private _totalSupply = 1_000_000_000 * 10**_decimals;

    // Max Tx amount on buy and sell
    uint256 public maxBuyAmount = _totalSupply.mul(2).div(100);            // 2%   max buy tx
    uint256 public maxSellAmount = _totalSupply.mul(5).div(1000);          // 0.5% max sell tx

    uint256 public maxWalletLimit = _totalSupply.mul(2).div(100);          // 2%   max wallet limit
    
    uint256 public swapThreshold = _totalSupply.mul(1).div(100);    // 1%   swap protection

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isPair;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxWallet;
    mapping(address => uint256) public _holderCooldownTimer; 

    bool swapEnabled = true;
    bool swapbylimit = true;
    bool DumpProtected = true;

    uint public buyTax;    
    uint public sellTax;

    IDexSwapRouter public dexRouter;
    address public dexPair;

    uint256 public cooldownTime  = 30 minutes;
    bool inSwap;   

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor() {

        developmentWallet = msg.sender;

        IDexSwapRouter _dexRouter = IDexSwapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        dexPair = IDexSwapFactory(_dexRouter.factory())
            .createPair(address(this), _dexRouter.WETH());

        dexRouter = _dexRouter;

        buyTax = initalBuyTax;    
        sellTax = initalSellTax;  

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(dexRouter)] = true;

        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[address(dexPair)] = true;
        _isExcludedFromMaxWallet[address(_dexRouter)] = true;
        _isExcludedFromMaxWallet[address(0xdead)] = true;
        _isExcludedFromMaxWallet[address(msg.sender)] = true;
        
        isPair[address(dexPair)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
       return _balances[account];     
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: Exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        if (sender == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (recipient == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        if(amount == 0) {
            revert ERC20ZeroTransfer();
        }
    
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            if (!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
                
                bool restricted;

                if (isPair[recipient]) {   //sell
                    require(
                        amount <= maxSellAmount,
                        "maxSellAmount Exceeded!"
                    );
                    restricted = true;
                } 
                else if (isPair[sender]) {  // buy
                    require(
                        amount <= maxBuyAmount,
                        "maxBuyAmount Exceeded!"
                    );
                    restricted = false;
                }
                else {
                    restricted = true;
                }

                if (!_isExcludedFromMaxWallet[recipient]) {
                    require(
                        amount + balanceOf(recipient) <= maxWalletLimit,
                        "Max Wallet Exceeded!"
                    );
                }

                if(restricted && DumpProtected) {
                    require(
                          _holderCooldownTimer[tx.origin] < block.timestamp,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderCooldownTimer[tx.origin] = block.timestamp + cooldownTime;
                }

            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (
                overMinimumTokenBalance && 
                !inSwap && 
                !isPair[sender] && 
                swapEnabled &&
                !isExcludedFromFee[sender] &&
                !isExcludedFromFee[recipient]
                ) {
                swapBack(contractTokenBalance);
            }
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;

        }

    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return true;
        }
        else if (isPair[sender] || isPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;

        unchecked {

            if(isPair[sender]) { 
                feeAmount = amount.mul(buyTax).div(100);
            } 
            else if(isPair[recipient]) { 
                feeAmount = amount.mul(sellTax).div(100);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    function swapBack(uint contractBalance) internal swapping {
        if(swapbylimit) contractBalance = swapThreshold;
        swapTokensForEth(contractBalance,developmentWallet);
    }

    function swapTokensForEth(uint256 tokenAmount, address _recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(_recipient), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function rescueFunds() external { 
        require(msg.sender == developmentWallet,"Unauthorized!");
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        if(!os) revert PaymentFailed();
    }

    function rescueTokens(address _token,address recipient,uint _amount) external {
        require(msg.sender == developmentWallet,"Unauthorized!");
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  recipient, _amount));
        if(!success) revert ERC20TransferFailed();
    }

    function setTxLimit(uint onBuy, uint onSell) external onlyOwner {   
        maxBuyAmount = onBuy * 10**_decimals;
        maxSellAmount  = onSell * 10**_decimals;
    }

    function setMaxWalletLimit(uint _newLimit) external onlyOwner {   
        maxWalletLimit = _newLimit * 10**_decimals;
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function setFee(uint _buySide, uint _sellSide) external onlyOwner {    
        buyTax = _buySide;
        sellTax = _sellSide;
    }

    function excludeFromFee(address _adr,bool _status) external onlyOwner {
        isExcludedFromFee[_adr] = _status;
    }
    
    function setDevelopmentWallet(address _newWallet) external onlyOwner {
        developmentWallet = _newWallet;
    }

    function setSwapBackSettings(uint _threshold, bool _enabled, bool _dProtection, bool _limited)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapbylimit = _limited;
        DumpProtected = _dProtection;
        swapThreshold = _threshold * 10 ** _decimals;
    }

}