// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IUniswapRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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


interface ISOONToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function getOwner() external view returns (address);
    function getCirculatingSupply() external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function setOwner(address owner) external;
    function setInitialDistributionFinished(bool value) external;
    function clearStuckBalance(address receiver) external;
    function rescueToken(address tokenAddress, uint256 tokens) external returns (bool success);
    function setPresaleFactory(address presaleFactory) external;
    function setAutoRebase(bool autoRebase) external;
    function setRebaseFrequency(uint256 rebaseFrequency) external;
    function setRewardYield(uint256 rewardYield, uint256 rewardYieldDenominator) external;
    function setNextRebase(uint256 nextRebase) external;
    function manualRebase() external;
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

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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



contract SOONPresale is Ownable {
    ISOONToken _SOONAddress;
    IERC20 _USDCAddress;
    IUniswapRouter02 public _Uniswap02Router;

    uint256 private constant USDC_DECIMAL = 6;

    // min/max cap
    uint256 public minCapUSDC                                       = 1 * 10 **  USDC_DECIMAL;
    uint256 public maxCapUSDC                                       = 10000 * 10 ** USDC_DECIMAL;
    uint256 public pTokenPrice_USDC                                 = 1 * 10 ** (USDC_DECIMAL - 5);
    
    // presale period
    uint256 public start_time;
    uint256 public end_time;

    // owner address token receive
    address payable fundAddress                             = payable(0x7Ad696FC88B9Cc87c138859F0623872feFa08F56);

    mapping (address => uint256) private _userPaidUSDC;

    constructor(address _router, address _SOON, address _USDC) {
        _Uniswap02Router = IUniswapRouter02(_router);
        _SOONAddress = ISOONToken(_SOON);
        _USDCAddress = IERC20(_USDC);
    }

    function buyTokensByUSDC(uint256 _amountPrice) external {
        require(block.timestamp >= start_time && block.timestamp <= end_time, "SOONPresale: Not presale period");

        // token amount user want to buy
        uint256 tokenAmount = _amountPrice / pTokenPrice_USDC * 10 ** 18;

        uint256 currentPaid = _userPaidUSDC[msg.sender];
        require(currentPaid + _amountPrice >= minCapUSDC && currentPaid + _amountPrice <= maxCapUSDC, "SOONPresale: The price is not allowed for presale.");
        
        // transfer USDC to owners
        _USDCAddress.transferFrom(msg.sender, fundAddress, _amountPrice);

        // transfer SOON token to user
        _SOONAddress.transfer(msg.sender, tokenAmount);
        
        // add USDC user bought
        _userPaidUSDC[msg.sender] += _amountPrice;

        emit Presale(address(this), msg.sender, tokenAmount);
    }

    function buyTokensByETH() external payable {
        require(block.timestamp >= start_time && block.timestamp <= end_time, "SOONPresale: Not presale period");
        
        require(msg.value > 0, "Insufficient ETH amount");
        uint256 amountPrice = getLatestETHPrice (msg.value);
 
        // token amount user want to buy
        uint256 tokenAmount = amountPrice / pTokenPrice_USDC * 10 ** 18;

        uint256 currentPaid = _userPaidUSDC[msg.sender];
        require(currentPaid + amountPrice >= minCapUSDC && currentPaid + amountPrice <= maxCapUSDC, "SOONPresale: The price is not allowed for presale.");
        
        // transfer ETH to owner
        fundAddress.transfer(msg.value);

        // transfer SOON token to user
        _SOONAddress.transfer(msg.sender, tokenAmount);

        // add USDC user bought
        _userPaidUSDC[msg.sender] += amountPrice;

        emit Presale(address(this), msg.sender, tokenAmount);
    }

    function getLatestETHPrice(uint256 _amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _Uniswap02Router.WETH();
        path[1] = address(_USDCAddress);

        uint256[] memory price_out = _Uniswap02Router.getAmountsOut(_amount, path);
        uint256 price_round = price_out[1] / 10 ** 6;
        return price_round * 10 ** 6;
    }

    function withdrawAll() external onlyOwner{
        uint256 balance = _SOONAddress.balanceOf(address(this));
        if(balance > 0) {
            _SOONAddress.transfer(msg.sender, balance);
        }

        emit WithdrawAll (msg.sender, balance);
    }

    function getUserPaidUSDC () public view returns (uint256) {
        return _userPaidUSDC[msg.sender];
    }

    function setAddress(address payable _addr) external onlyOwner {
        fundAddress = _addr;
    }

    function setMinCapUSDC(uint256 _minCap) external onlyOwner {
        minCapUSDC = _minCap;

        emit SetMinCap(_minCap);
    }

    function setMaxCapUSDC(uint256 _maxCap) external onlyOwner {
        maxCapUSDC = _maxCap;

        emit SetMaxCap(_maxCap);
    }

    function setStartTime(uint256 _time) external onlyOwner {
        start_time = _time;

        emit SetStartTime(_time);
    }

    function setEndTime(uint256 _time) external onlyOwner {
        end_time = _time;

        emit SetEndTime(_time);
    }

    function setpTokenPriceUSDC(uint256 _pTokenPrice) external onlyOwner {
        pTokenPrice_USDC = _pTokenPrice;

        emit SetpTokenPrice(_pTokenPrice, 1);
    }

    event Presale(address _from, address _to, uint256 _amount);
    event SetMinCap(uint256 _amount);
    event SetMaxCap(uint256 _amount);
    event SetpTokenPrice(uint256 _price, uint _type);
    event SetStartTime(uint256 _time);
    event SetEndTime(uint256 _time);
    event WithdrawAll(address addr, uint256 SOON);

    receive() payable external {}

    fallback() payable external {}
}