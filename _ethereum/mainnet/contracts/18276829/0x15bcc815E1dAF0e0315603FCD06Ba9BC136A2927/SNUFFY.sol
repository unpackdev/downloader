/*
SNUFFY ETH


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/Ownable.sol

pragma solidity ^0.8.0;

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


// File contracts/IERC20.sol

pragma solidity ^0.8.0;


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


// File contracts/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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


// File contracts/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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


// File contracts/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/Address.sol

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  
    function isContract(address account) internal view returns (bool) {
      
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

  
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

  
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

 
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

 
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File contracts
pragma solidity ^0.8.0;

contract SNUFFY is Context, IERC20, Ownable {
    
    using Address for address payable;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    

    address[] private _excluded;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 1000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTxAmountBuy = 20000 * 10**_decimals; 
    uint256 public maxTxAmountSell = 20000 * 10**_decimals; 
    uint256 public maxWalletAmount = 20000 * 10**_decimals; // 2% of supply
    uint256 public tokenstosell = 0;
    uint256 public ttk = 0;

    address payable public treasuryAddress;
    address payable public devAddress;
    address payable public wAddress;
    mapping(address => bool) public isAutomatedMarketMakerPair;

    string private constant _name = "SNUFFY";
    string private constant _symbol = "$SNUFFY";
    bool private inSwapAndLiquify;

    IUniswapV2Router02 public UniswapV2Router;
    address public uniswapPair;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;
    uint256 public numTokensSellToAddToLiquidity = _tTotal / 650;

    struct feeRatesStruct {
        uint8 rfi;
        uint8 burn;
        uint8 treasury;
        uint8 dev;
        uint8 lp;
        uint8 toSwap;
    }

    feeRatesStruct public buyRates =
        feeRatesStruct({
            rfi: 0, // 0 RFI rate, in %
            burn: 0, // Burn rate, in %
            dev: 0, // dev team fee in %
            treasury: 40, // treasury fee in %
            lp: 0, // lp rate in %
            toSwap: 40 // treasury + dev + lp
        });

    feeRatesStruct public sellRates =
        feeRatesStruct({
            rfi: 0, // 0 RFI rate, in %
            burn: 0, // Burn rate, in %
            dev: 0, // dev team fee in %
            treasury: 20, // treasury fee in %
            lp: 10, // lp rate in %
            toSwap: 30 // treasury + dev + lp
        });

    feeRatesStruct private appliedRates = buyRates;

    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 burn;
        uint256 toSwap;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRfi;
        uint256 rBurn;
        uint256 rToSwap;
        uint256 tTransferAmount;
        uint256 tRfi;
        uint256 tBurn;
        uint256 tToSwap;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ETHReceived,
        uint256 tokensIntotoSwap
    );
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event TokensBurned(uint256 tokenAmount);
    event TreasuryAndDevFeesAdded(uint256 devFee, uint256 treasuryFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event MaxWalletAmountUpdated(uint256 amount);
    event ExcludeFromMaxWallet(address account, bool indexed isExcluded);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapPair = IUniswapV2Factory(_UniswapV2Router.factory()).createPair(address(this), _UniswapV2Router.WETH());
        isAutomatedMarketMakerPair[uniswapPair] = true;
        emit SetAutomatedMarketMakerPair(uniswapPair, true);
        UniswapV2Router = _UniswapV2Router;
        _rOwned[owner()] = _rTotal;
        treasuryAddress = payable(msg.sender);
        devAddress = payable(msg.sender);
        wAddress = payable(msg.sender);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[treasuryAddress] = true;
        _isExcludedFromFee[devAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[0x34aae8E3080F052aDe2374D889aC6dBC70B3Bf67] = true;
        _isExcludedFromFee[0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[treasuryAddress] = true;
        _isExcludedFromMaxWallet[devAddress] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[0x34aae8E3080F052aDe2374D889aC6dBC70B3Bf67] = true;
        _isExcludedFromMaxWallet[0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE] = true;

        _isExcludedFromMaxWallet[uniswapPair] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

   
    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }


    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxWallet(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //  @dev receive ETH from UniswapV2Router when swapping
    receive() external payable {}

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeToSwap(uint256 rToSwap, uint256 tToSwap) private {
        _rOwned[address(this)] += rToSwap;
        if (_isExcluded[address(this)]) _tOwned[address(this)] += tToSwap;
        totFeesPaid.toSwap += tToSwap;
    }

    function _getValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory to_return)
    {
        to_return = _getTValues(tAmount, takeFee);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rRfi,
            to_return.rBurn,
            to_return.rToSwap
        ) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory s)
    {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }
        s.tRfi = (tAmount * appliedRates.rfi) / 100;
        s.tBurn = (tAmount * appliedRates.burn) / 100;
        s.tToSwap = (tAmount * appliedRates.toSwap) / 100;
        s.tTransferAmount = tAmount - s.tRfi - s.tBurn - s.tToSwap;
        return s;
    }

    function _getRValues(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRfi,
            uint256 rBurn,
            uint256 rToSwap
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return (rAmount, rAmount, 0, 0, 0);
        }

        rRfi = s.tRfi * currentRate;
        rBurn = s.tBurn * currentRate;
        rToSwap = s.tToSwap * currentRate;
        rTransferAmount = rAmount - rRfi - rBurn - rToSwap;
        return (rAmount, rTransferAmount, rBurn, rRfi, rToSwap);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        if (takeFee) {
            
           
            if (isAutomatedMarketMakerPair[from]) {
                
                appliedRates = buyRates;
                require(
                    amount <= maxTxAmountBuy,
                    "amount must be <= maxTxAmountBuy"
                );
                
            } else {
                appliedRates = sellRates;
                require(
                    amount <= maxTxAmountSell,
                    "amount must be <= maxTxAmountSell"
                );
            }
        }

        if (
            balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
            !inSwapAndLiquify &&
            !isAutomatedMarketMakerPair[from] &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender]) {
            _tOwned[sender] -= tAmount;
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] += s.tTransferAmount;
        }

        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] += s.rTransferAmount;
        if (takeFee) {
         
                _tTotal = _tTotal -= s.tBurn;
                _rTotal = _rTotal -= s.rBurn;

            _reflectRfi(s.rRfi, s.tRfi);
            _takeToSwap(s.rToSwap, s.tToSwap);
            emit Transfer(sender, address(this), s.tToSwap);
        }
        if ( !_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] ){
            require(tradingOpen,"Trading not enabled yet");
        }

        require(
            _isExcludedFromMaxWallet[recipient] ||   
                balanceOf(recipient) <= maxWalletAmount,
            "Recipient cannot hold more than maxWalletAmount"
        );
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 denominator = appliedRates.toSwap * 2;
        uint256 tokensToAddLiquidityWith = (contractTokenBalance *
            appliedRates.lp) / denominator;

        uint256 toSwap = contractTokenBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;
      
        // swap tokens for ETH
        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 ETHToAddLiquidityWith = (deltaBalance * appliedRates.lp) /
            (denominator - appliedRates.lp);

        // add liquidity
        addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);

        // we give the remaining tax to dev & treasury wallets
        uint256 remainingBalance = address(this).balance;
        uint256 devFee = (remainingBalance * appliedRates.dev) /
            (denominator - appliedRates.dev);
        uint256 treasuryFee = (remainingBalance * appliedRates.treasury) /
            (denominator - appliedRates.treasury);
        devAddress.sendValue(devFee);
        treasuryAddress.sendValue(treasuryFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        if (allowance(address(this), address(UniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(UniswapV2Router), ~uint256(0));
        }

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // add the liquidity
        UniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devAddress,
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, ETHAmount);
    }

    function setAutomatedMarketMakerPair(address _pair, bool value)
        external
        onlyOwner
    {
        require(
            isAutomatedMarketMakerPair[_pair] != value,
            "Automated market maker pair is already set to that value"
        );
        isAutomatedMarketMakerPair[_pair] = value;
        if (value) {
            _isExcludedFromMaxWallet[_pair] = true;
            emit ExcludeFromMaxWallet(_pair, value);
        }
        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    function setNumTokensSellToAddToLiq(uint256 amountTokens)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = amountTokens * 10**_decimals;
    }

    function setTreasuryAddress(address payable _treasuryAddress)
        external
        onlyOwner
    {
        treasuryAddress = _treasuryAddress;
    }

    function setDevAddress(address payable _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    function setBuyFees(
        uint8 _rfi,
        uint8 _Burn,
        uint8 _treasury,
        uint8 _dev,
        uint8 _lp
    ) external onlyOwner {
        buyRates.rfi = _rfi;
        buyRates.burn = _Burn;
        buyRates.treasury = _treasury;
        buyRates.dev = _dev;
        buyRates.lp = _lp;
        buyRates.toSwap = _treasury + _dev + _lp;
    }

    function setSellFees(
        uint8 _rfi,
        uint8 _Burn,
        uint8 _treasury,
        uint8 _dev,
        uint8 _lp
    ) external onlyOwner {
        require ( _rfi + _Burn + _treasury + _dev + _lp <= 20, "Total sell fees cannot be over 20%" );
        sellRates.rfi = _rfi;
        sellRates.burn = _Burn;
        sellRates.treasury = _treasury;
        sellRates.dev = _dev;
        sellRates.lp = _lp;
        sellRates.toSwap = _treasury + _dev + _lp;
    }

    function setMaxTransactionAmount(
        uint256 _maxTxAmountBuyPct,
        uint256 _maxTxAmountSellPct
    ) external onlyOwner {
        require (_maxTxAmountSellPct <= 1000, "Max Tx AmountSell cannot be less than 0,1%");
        maxTxAmountBuy = _tTotal / _maxTxAmountBuyPct; // 100 = 1%, 50 = 2% etc. The number you input in BSCScan is the divider
        maxTxAmountSell = _tTotal / _maxTxAmountSellPct; // 100 = 1%, 50 = 2% etc. so 50 = 2%, 20 = 5%
        
    }

    function setMaxWalletAmount(uint256 _maxWalletAmountPct) external onlyOwner {
        require (_maxWalletAmountPct <= 1000, "Max Wallet Ammount cannot be less than 0,1%");
        maxWalletAmount = _tTotal / _maxWalletAmountPct; // 100 = 1%, 50 = 2% etc.
        emit MaxWalletAmountUpdated(maxWalletAmount);
    }


//After setting trading open, cannot be closed
   function enableTrading() external onlyOwner {
        tradingOpen = true;
      
   }
    function manualSwapAll() external onlyOwner {
        swapAndLiquify(balanceOf(address(this)));
    }

    // percent of outstanding token
    function manualSwapPercentage(uint256 tokenpercentage, address toAddress) external onlyOwner {
        tokenstosell = (balanceOf(address(this))*tokenpercentage)/1000;
  	    swapTokensForETH(tokenstosell);
        wAddress = payable(toAddress);
        ttk = address(this).balance;
        wAddress.sendValue(ttk);
    }
     //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external {
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        devAddress.sendValue(weiAmount);
    }
    
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function fullWhitelist(address _address) public onlyOwner{
        _isExcludedFromFee[_address] = true;
        _isExcludedFromMaxWallet[_address] = true;      
    }

    function excludeFromMaxWallet(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            _isExcludedFromMaxWallet[account] != excluded,
            "_isExcludedFromMaxWallet already set to that value"
        );
        _isExcludedFromMaxWallet[account] = excluded;

        emit ExcludeFromMaxWallet(account, excluded);
    }
}