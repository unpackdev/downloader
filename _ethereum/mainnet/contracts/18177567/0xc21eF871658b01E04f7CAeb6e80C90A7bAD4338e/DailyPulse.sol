/******************************************************************

    Telegram : https://t.me/dailypulseErc
    Bot : https://t.me/DailyPulseBot
    Web : https://dailypulseerc.com/
    Medium : http://medium.com/@dailypulse
    X: https://twitter.com/DailypulseErc
    Whitepaper : https://dailypulseerc.com/Whitepaper.pdf

******************************************************************/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract DailyPulse is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private constant _name = "Daily pulse";
    string private constant _symbol = "DP";
    uint256 private constant _totalSupply = 630_000_000 * 10**18;
    uint256 public minSwap = 100_000 * 10**18; 
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address immutable uniswapV2Pair;
    address immutable WETH;
 
    address payable public marketingWallet;
    address payable public DevWallet;
    address payable public teamWallet;
    uint256 public BuyTax;
    uint256 public SellTax;
    uint8 private inSwapAndLiquify;
    
    uint256 public taxChangeInterval = 4 minutes;
    uint256 public lastTaxChangeTimestamp;
    uint8 public currentTaxPeriod = 0;
    bool public finalTaxSet = false;
    
    bool public TradingEnabled = false;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    constructor() {
        uniswapV2Router = IUniswapV2Router02( 
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        //initial tax values
        BuyTax = 10;
        SellTax = 25;

        marketingWallet = payable(0xfa81dd2d40e255af376384f99302A122713F367e); //Marketing Wallet Address
        DevWallet = payable(0x88037D907ee464D88691245eaAdb369aeA3c42aB); // Dev Wallet Address
        teamWallet = payable(0xfDdCD734f67f696Ce534A770eA4ac990d9880681); // Team Wallet Address
        _balance[msg.sender] = _totalSupply;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(uniswapV2Router)] = true;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256)
            .max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;
        _allowances[marketingWallet][address(uniswapV2Router)] = type(uint256)
            .max;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function ExcludeFromFees(address holder, bool exempt) external onlyOwner {
        _isExcludedFromFees[holder] = exempt;
    }
    
    function ChangeMinSwap(uint256 NewMinSwapAmount) external onlyOwner {
        minSwap = NewMinSwapAmount * 10**18;
    }

    function ChangeMarketingWalletAddress(address newAddress) external onlyOwner() {
        marketingWallet = payable(newAddress);
    }
    
    function ChangeDevWalletAddress(address newAddress) external onlyOwner() {
        DevWallet = payable(newAddress);
    }
    
    function EnableTrading() external onlyOwner {
        TradingEnabled = true;
        lastTaxChangeTimestamp = block.timestamp;
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 1e9, "Min transfer amt");
        require(TradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Not Enabled");
        
        
        uint256 elapsedTime = block.timestamp - lastTaxChangeTimestamp;
        
        if (elapsedTime >= taxChangeInterval && currentTaxPeriod < 4) {
            currentTaxPeriod++;
                if (currentTaxPeriod == 1) {
                    // After 4 minutes, set buyTax to 10% and sellTax to 25%
                    BuyTax = 10;
                    SellTax = 25;
                } else if (currentTaxPeriod == 2) {
                    // After 4 more minutes, set buyTax to 10% and sellTax to 15%
                    BuyTax = 10;
                    SellTax = 15;
                } else if (currentTaxPeriod == 3) {
                    // After 4 more minutes, set buyTax to 5% and sellTax to 10%
                    BuyTax = 5;
                    SellTax = 10;
                } else if (currentTaxPeriod == 4) {
                    // After 4 more minutes, set buyTax and sellTax to 5%
                    BuyTax = 5;
                    SellTax = 5;
                }
                // Update the last tax change timestamp    
                lastTaxChangeTimestamp = block.timestamp;
            }


        uint256 _tax;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            _tax = 0;
        } else {

            if (inSwapAndLiquify == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                    _tax = BuyTax;
            } else if (to == uniswapV2Pair) {
                uint256 tokensToSwap = _balance[address(this)];
                if (tokensToSwap > minSwap && inSwapAndLiquify == 0) {
                    inSwapAndLiquify = 1;
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );
                    inSwapAndLiquify = 0;
                }
                    _tax = SellTax;

            } else {
                _tax = 0;
            }
        }
        

        //Is there tax for sender|receiver?
        if (_tax != 0) {
            //Tax transfer
            uint256 taxTokens = (amount * _tax) / 100;
            uint256 transferAmount = amount - taxTokens;

            _balance[from] -= amount;
            _balance[to] += transferAmount;
            _balance[address(this)] += taxTokens;
            emit Transfer(from, address(this), taxTokens);
            emit Transfer(from, to, transferAmount);
        } else {
            //No tax transfer
            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }

    uint256 amountReceived = address(this).balance;

    uint256 amountETHMarketing = amountReceived.mul(60).div(100); // 60% to marketing wallet
    uint256 amountETHTeam = amountReceived.mul(20).div(100); // 20% to team wallet
    uint256 amountETHDev = amountReceived.mul(20).div(100); // 20% to dev wallet
    
    
    if (amountETHMarketing > 0)
    transferToAddressETH(marketingWallet, amountETHMarketing);
    
    if (amountETHTeam > 0)
    transferToAddressETH(teamWallet, amountETHTeam);
    
    if (amountETHDev > 0)
    transferToAddressETH(DevWallet, amountETHDev);
    }

    receive() external payable {}
}