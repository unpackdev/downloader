// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    mapping(address => bool) internal authorizations;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}
interface IUniswapV2Router02 {
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapV2Pair {
    function sync() external;
}

contract ERC20_BuySellTax is Ownable, IERC20 {
    IUniswapV2Router02 public router;
    IUniswapV2Pair private pairContract;

    address public pair;
    address WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address private outputAddress;

    bool liquidityAdded;
    bool inSwap;

    string public _name;
    string public _symbol;

    uint256 private constant DENOMINATOR = 10000;
    uint256 private constant SWAP_PROPORTION = 9900; //swap 99% of contract balance when swapping tax to eth
    uint256 private constant LP_PROPORTION = 9500;
    uint256 private constant DEPLOYER_PROPORTION = 500;
    uint256 public constant TOTAL_SUPPLY = 10_000_000 * 1e18;
    uint256 public maxTxAmount = 5000 * 1e18;
    uint256 public maxWalletTokens = 5000 * 1e18;
    uint256 public sellTax = 2000;
    uint256 public buyTax = 2000;
    uint256 public swapThreshold = 10_000 * 1e18;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isExemptFromFees;
    mapping(address => bool) isExemptFromMaxTx;

    event EditTax(uint8 Buy, uint8 Sell);
    event ClearStuck(uint256 amount);
    event ClearTokenAndEth(address tokenAddress, uint256 tokenAmount, uint256 ethAmount);
    event OutputAddressSet(address outputAddress);
    event MaxWalletTokensSet(uint256 maxWalletTokens);
    event SwapThresholdSet(uint256 amount);

    error InsufficientBalance();
    error TransactionLimitExceeded();
    error TransferFailed();
    
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _outputAddress,
        address _router
    ) payable {

        _name = _tokenName;
        _symbol = _tokenSymbol;
                        
        outputAddress = _outputAddress;

        router = IUniswapV2Router02(_router);
        WETH = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(
            WETH,
            address(this)
        );
        pairContract = IUniswapV2Pair(pair);
        _allowances[address(this)][address(router)] = type(uint256).max;

        //set exemptions
        isExemptFromFees[msg.sender] = true;
        isExemptFromFees[address(this)] = true;
        isExemptFromMaxTx[msg.sender] = true;
        isExemptFromMaxTx[pair] = true;
        isExemptFromMaxTx[outputAddress] = true;
        isExemptFromMaxTx[address(this)] = true;

        //transfer LP_PROPORTION of TOTAL_SUPPLY to this contract for adding to liquidity pool
        _balances[address(this)] = (TOTAL_SUPPLY * LP_PROPORTION) / DENOMINATOR;
        emit Transfer(
            address(0),
            address(this),
            (TOTAL_SUPPLY * LP_PROPORTION) / DENOMINATOR
        );

        //transfer DEPLOYER_PROPORTION of TOTAL_SUPPLY to the deployer wallet
        _balances[msg.sender] = (TOTAL_SUPPLY * DEPLOYER_PROPORTION) / DENOMINATOR;
        emit Transfer(
            address(0),
            msg.sender,
            (TOTAL_SUPPLY * DEPLOYER_PROPORTION) / DENOMINATOR
        );
    }

    modifier avoidRecursiveSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}

    //95% of TOTAL_SUPPLY to LP (will be contract balance at this point)
    function addLiquidity() external onlyOwner {
        _allowances[address(this)][address(router)] = type(uint256).max;
        emit Approval(address(this), address(router), type(uint256).max);

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        liquidityAdded = true;
    }

    //=========================================
    // TRANSFER-RELATED LOGIC
    //=========================================
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max && _allowances[sender][msg.sender] >= amount) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (
            liquidityAdded &&
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != outputAddress &&
            !isExemptFromMaxTx[recipient]
        ) {
            uint256 heldTokens = balanceOf(recipient);

            if((heldTokens + amount) > maxWalletTokens) {
                revert TransactionLimitExceeded();
            }
        }

        if (amount > maxTxAmount && !isExemptFromMaxTx[sender]) {
            revert TransactionLimitExceeded();
        }

        if (
            (sender == pair || recipient == pair) &&
            liquidityAdded &&
            !inSwap &&
            _balances[address(this)] >= swapThreshold
        ) {
            _swapBack();
        }

        if (_balances[sender] < amount) {
            revert InsufficientBalance();
        }
        _balances[sender] -= amount;

        uint256 amountReceived;
        if(isExemptFromFees[sender] || isExemptFromFees[recipient]) {
            amountReceived = amount;
        } else {
            amountReceived = _takeFee(sender, amount, recipient);
        }
        _balances[recipient] += amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if(_balances[sender] < amount) {
            revert InsufficientBalance();
        }
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFee(
        address sender,
        uint256 amount,
        address recipient
    ) internal returns (uint256) {
        uint256 thisTax = 0;
        if (recipient == pair) {
            thisTax = sellTax;
        } else if (sender == pair) {
            thisTax = buyTax;
        }

        uint256 feeAmount = (amount * thisTax) / DENOMINATOR;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function _swapBack() internal avoidRecursiveSwap {
        uint256 amountToSwap = (balanceOf(address(this)) * SWAP_PROPORTION) / DENOMINATOR;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            outputAddress,
            block.timestamp
        );
    }

    //=========================================
    // VIEW FUNCTIONS
    //=========================================
    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function totalSupply() external view override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function decimals() external pure override returns (uint8) {
        return uint8(18);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //=========================================
    // SETTERS
    //=========================================
    function removeLimits() external onlyOwner {
        maxTxAmount = TOTAL_SUPPLY;
        maxWalletTokens = TOTAL_SUPPLY;
        emit MaxWalletTokensSet(maxWalletTokens);
    }  

    function setMaxWalletAndTransactionTokens(
        uint256 _maxWalletTokens, 
        uint256 _maxTxAmount
    ) external onlyOwner {
        require(_maxWalletTokens >= 1);
        require(_maxTxAmount >= 1);
        maxWalletTokens = _maxWalletTokens;
        maxTxAmount = _maxTxAmount;
        emit MaxWalletTokensSet(_maxWalletTokens);
    }

    function setFees(
        uint256 _buyTax,
        uint256 _sellTax
    ) public onlyOwner {
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function setOutputAddress(address _outputAddress) external onlyOwner {
        outputAddress = _outputAddress;
        emit OutputAddressSet(outputAddress);
    }

    function setSwapBackSettings(uint256 _amount) external onlyOwner {
        swapThreshold = _amount;
        emit SwapThresholdSet(swapThreshold);
    }

    function manualUnclog(uint256 _percentageUnclog) external avoidRecursiveSwap onlyOwner {
        uint256 amountToSwap = (balanceOf(address(this)) * _percentageUnclog) / DENOMINATOR;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            outputAddress,
            block.timestamp
        );
    }

    function clearTokenAndEth(
        address _tokenAddress
    ) external returns (bool success) {
        uint256 contractEthBalance = address(this).balance;
        uint256 contractTokenBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );

        bool tokenTransferSuccess = IERC20(_tokenAddress).transfer(
            outputAddress,
            contractTokenBalance
        );

        (bool ethTransferSuccess, ) = payable(outputAddress).call{
            value: contractEthBalance
        }("");

        if(!tokenTransferSuccess || !ethTransferSuccess){
            revert TransferFailed();
        }
        emit ClearTokenAndEth(_tokenAddress, contractTokenBalance, contractEthBalance);
        return true;
    }
}