// SPDX-License-Identifier: MIT

// Telegram: https://t.me/CommunityPotassium

// Twitter: https://twitter.com/Potassium_Army

// Website : https://pottoken.io


pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IDexSwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDexSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract POTASSIUM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "Potassium";
    string private _symbol = "K";
    uint8 private _decimals = 18;


    address public DistributionWallet;

    uint256 public totalBuyFee = 150;
    uint256 public totalSellFee = 300;
    uint256 feedenominator = 1000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isExcludedFromFee;


    uint256 private _totalSupply = 390_983_000 * 10 ** _decimals;
    uint256 public swapThreshold = 3_000_000 * 10 ** _decimals;

    bool public swapEnabled = true;


    IDexSwapRouter public DexRouter;
    address public DexPair;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapTokensForETH(uint256 amountIn, address[] path);

    constructor() {

        DistributionWallet = msg.sender;

        IDexSwapRouter _dexRouter = IDexSwapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        DexPair = IDexSwapFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        DexRouter = _dexRouter;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(DexRouter)] = true;


        isMarketPair[address(DexPair)] = true;

        _allowances[address(this)][address(DexRouter)] = ~uint256(0);
        _allowances[address(this)][address(DexPair)] = ~uint256(0);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "Potassium: decreased allowance below zero"
            )
        );
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Potassium: approve from the zero address");
        require(spender != address(0), "Potassium: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "Potassium: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        require(sender != address(0), "Potassium: transfer from the zero address");
        require(recipient != address(0), "Potassium: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >=
                swapThreshold;

            if (
                overMinimumTokenBalance &&
                !inSwap &&
                !isMarketPair[sender] &&
                swapEnabled
            ) {
                swapBack(contractTokenBalance);
            }

            uint256 senderBalance = _balances[sender];
            _balances[sender] = senderBalance - amount;

            uint256 finalAmount = shouldNotTakeFee(sender, recipient)
                ? amount
                : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);

            return true;
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Potassium:Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldNotTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return true;
        } else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        } else {
            return false;
        }
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint feeAmount;

        unchecked {
            if (isMarketPair[sender]) {
                feeAmount = amount.mul(totalBuyFee).div(feedenominator);
            } else if (isMarketPair[recipient]) {
                feeAmount = amount.mul(totalSellFee).div(feedenominator);
            }

            if (feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    feeAmount
                );
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
    }

    function swapBack(uint contractBalance) internal swapping {
        uint256 totalShares = totalBuyFee.add(totalSellFee);

        if (totalShares == 0) return;

        swapTokensForEth(contractBalance);
        uint256 amountReceived = address(this).balance;

        if (amountReceived > 0) {
            payable(DistributionWallet).transfer(amountReceived);
        }
    }



    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DexRouter.WETH();

        _approve(address(this), address(DexRouter), tokenAmount);

        DexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this), 
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function setFee(uint _newBuy, uint _newSell) external onlyOwner {
        require(_newBuy <= 250, "Buy fees cannot be more than 25%");
        require(_newSell <= 250, "Sell fees cannot be more than 25%");
        totalBuyFee = _newBuy;
        totalSellFee = _newSell;
    }



    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    ) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
}