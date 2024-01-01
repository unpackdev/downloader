/* Olympus AI <OMAI> has it's own telegram bot which goes through all the products on Amazon.com and allows users to find out which products have the highest ROI for Amazon FBA.
It also tracks volume in different niches throughout Amazon and users can find out winning products.
It also has OpenAI’s GPT-4 included into the bot to ensure it's scalability of information is far and wide.

Join the revolution of AI:
https://olympus-ai.org/
https://t.me/OlympusAI_ETH
https://t.me/OlympusAI_BOT
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

interface IUniswapV2Pair {
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function factory() external view returns (address);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address _address) public onlyOwner {
        _whiteList[_address] = true;
    }

    function includeManyToWhiteList(
        address[] memory _addresses
    ) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _whiteList[_addresses[i]] = true;
        }
    }
}

contract OLYMPUSAI is Context, IERC20, LockToken {
    using SafeMath for uint256;
    address payable public treasuryAddress =
        payable(0xea978B8D7465ddD9462edD570ddB73dA5161E87e);
    address payable public projectAddress =
        payable(0xea978B8D7465ddD9462edD570ddB73dA5161E87e);
    address public newOwner = 0xea978B8D7465ddD9462edD570ddB73dA5161E87e;
    address public uniV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isWhitelistedFee;
    mapping(address => bool) private _isExcludedFromWhale;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;

    string private _name = "Olympus AI";
    string private _symbol = "OMAI";
    uint8 private _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _buyAutoLPFee = 0;
    uint256 public _buyTreasuryFee = 250;
    uint256 public _buyProjectFee = 50;

    uint256 public buyTotalFee =
        _buyAutoLPFee + _buyTreasuryFee + _buyProjectFee;
    uint256[] public buyFeesBackup = [
        _buyAutoLPFee,
        _buyTreasuryFee,
        _buyProjectFee
    ];

    uint256 public _sellAutoLPFee = 0;
    uint256 public _sellTreasuryFee = 250;
    uint256 public _sellProjectFee = 50;
    uint256 public sellTotalFee =
        _sellAutoLPFee + _sellTreasuryFee + _sellProjectFee;

    uint256 public _tfrAutoLPFee = 0;
    uint256 public _tfrTreasuryFee = 0;
    uint256 public _tfrProjectFee = 0;
    uint256 public transferTotalFee =
        _tfrAutoLPFee + _tfrTreasuryFee + _tfrProjectFee;

    uint256 public _maxTxAmount = _tTotal.div(100).mul(1); //x% of total supply
    uint256 public _walletHoldingMaxLimit = _tTotal.div(100).mul(2); //x% of total supply
    uint256 private minimumTokensBeforeSwap = 1000000 * 10 ** _decimals;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[newOwner] = _rTotal;
        emit Transfer(address(0), newOwner, _tTotal);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniV2RouterAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isWhitelistedFee[newOwner] = true;
        _isWhitelistedFee[address(this)] = true;
        includeToWhiteList(newOwner);
        _isExcludedFromWhale[newOwner] = true;
        excludeWalletsFromWhales();
        transferOwnership(newOwner);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
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
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private open(from, to) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;

        checkForWhale(from, to, amount);

        if (
            !inSwapAndLiquify && swapAndLiquifyEnabled && from != uniswapV2Pair
        ) {
            if (overMinimumTokenBalance) {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }
        }

        bool takeFee = true;

        //if any account belongs to _isWhitelistedFee account then remove the fee
        if (_isWhitelistedFee[from] || _isWhitelistedFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 __buyTotalFee = _buyAutoLPFee.add(_buyTreasuryFee).add(
            _buyProjectFee
        );
        uint256 __sellTotalFee = _sellAutoLPFee.add(_sellTreasuryFee).add(
            _sellProjectFee
        );
        uint256 totalSwapableFees = __buyTotalFee.add(__sellTotalFee);
        
        if (totalSwapableFees == 0) {
            return;
        }

        uint256 halfLiquidityTokens = contractTokenBalance
            .mul(_buyAutoLPFee + _sellAutoLPFee)
            .div(totalSwapableFees)
            .div(2);
        uint256 swapableTokens = contractTokenBalance.sub(halfLiquidityTokens);
        swapTokensForEth(swapableTokens);

        uint256 newBalance = address(this).balance;
        uint256 ethForLiquidity = newBalance
            .mul(_buyAutoLPFee + _sellAutoLPFee)
            .div(totalSwapableFees)
            .div(2);

        if (halfLiquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(halfLiquidityTokens, ethForLiquidity);
        }

        uint256 ethForTreasury = newBalance
            .mul(_buyTreasuryFee + _sellTreasuryFee)
            .div(totalSwapableFees);
        if (ethForTreasury > 0) {
            treasuryAddress.transfer(ethForTreasury);
        }

        uint256 ethForDev = newBalance.sub(ethForLiquidity).sub(ethForTreasury);
        if (ethForDev > 0) {
            projectAddress.transfer(ethForDev);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            removeAllFee();
        } else {
            if (recipient == uniswapV2Pair) {
                setSellFee();
            }

            if (sender != uniswapV2Pair && recipient != uniswapV2Pair) {
                setWalletToWalletTransferFee();
            }
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tLiquidity > 0) {
            emit Transfer(sender, address(this), tLiquidity);
        }
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tLiquidity > 0) {
            emit Transfer(sender, address(this), tLiquidity);
        }
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tLiquidity > 0) {
            emit Transfer(sender, address(this), tLiquidity);
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tLiquidity > 0) {
            emit Transfer(sender, address(this), tLiquidity);
        }
    }

    function _getValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(
            tAmount,
            tLiquidity,
            _getRate()
        );
        return (rAmount, rTransferAmount, tTransferAmount, tLiquidity);
    }

    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256) {
        uint256 tLiquidity = calculateAutoLPFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tLiquidity,
        uint256 currentRate
    ) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
    }

    function calculateAutoLPFee(
        uint256 _amount
    ) private view returns (uint256) {
        uint256 fees = _buyAutoLPFee.add(_buyTreasuryFee).add(
            _buyProjectFee
        );
        return _amount.mul(fees).div(1000);
    }

    function isWhitelistedFee(
        address account
    ) public view onlyOwner returns (bool) {
        return _isWhitelistedFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isWhitelistedFee[account] = true;
    }

    function excludeFromFeeMany(address[] memory accounts) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isWhitelistedFee[accounts[i]] = true;
        }
    }

    function includeInFee(address account) public onlyOwner {
        _isWhitelistedFee[account] = false;
    }

    function removeAllFee() private {
        _buyAutoLPFee = 0;
        _buyTreasuryFee = 0;
        _buyProjectFee = 0;
    }

    function restoreAllFee() private {
        _buyAutoLPFee = buyFeesBackup[0];
        _buyTreasuryFee = buyFeesBackup[1];
        _buyProjectFee = buyFeesBackup[2];
    }

    function setSellFee() private {
        _buyAutoLPFee = _sellAutoLPFee;
        _buyTreasuryFee = _sellTreasuryFee;
        _buyProjectFee = _sellProjectFee;
    }

    function setWalletToWalletTransferFee() private {
        _buyAutoLPFee = _tfrAutoLPFee;
        _buyTreasuryFee = _tfrTreasuryFee;
        _buyProjectFee = _tfrProjectFee;
    }

    function setBuyFeePercentages(
        uint256 _autoLPFee,
        uint256 _treasuryFee,
        uint256 _projectFee
    ) external onlyOwner {
        _buyAutoLPFee = _autoLPFee;
        _buyTreasuryFee = _treasuryFee;
        _buyProjectFee = _projectFee;
        buyFeesBackup = [_buyAutoLPFee, _buyTreasuryFee, _buyProjectFee];
        uint256 totalFee = _autoLPFee.add(_treasuryFee).add(_projectFee);
        buyTotalFee = _buyAutoLPFee + _buyTreasuryFee + _buyProjectFee;
        require(totalFee <= 600, "Too High Fee");
    }

    function setSellFeePercentages(
        uint256 _autoLPFee,
        uint256 _treasuryFee,
        uint256 _projectFee
    ) external onlyOwner {
        _sellAutoLPFee = _autoLPFee;
        _sellTreasuryFee = _treasuryFee;
        _sellProjectFee = _projectFee;
        uint256 totalFee = _autoLPFee.add(_treasuryFee).add(_projectFee);
        sellTotalFee = _sellAutoLPFee + _sellTreasuryFee + _sellProjectFee;
        require(totalFee <= 600, "Too High Fee");
    }

    function setTransferFeePercentages(
        uint256 _autoLPFee,
        uint256 _treasuryFee,
        uint256 _projectFee
    ) external onlyOwner {
        _tfrAutoLPFee = _autoLPFee;
        _tfrTreasuryFee = _treasuryFee;
        _tfrProjectFee = _projectFee;
        transferTotalFee = _tfrAutoLPFee + _tfrTreasuryFee + _tfrProjectFee;
        uint256 totalFee = _autoLPFee.add(_treasuryFee).add(_projectFee);
        require(totalFee <= 100, "Too High Fee");
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
        require(_maxTxAmount >= _tTotal.div(10000).mul(1), "Too low limit");
    }

    function setMinimumTokensBeforeSwap(
        uint256 _minimumTokensBeforeSwap
    ) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = payable(_treasuryAddress);
    }

    function setProjectAddress(address _projectAddress) external onlyOwner {
        projectAddress = payable(_projectAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function excludeWalletsFromWhales() private {
        _isExcludedFromWhale[owner()] = true;
        _isExcludedFromWhale[address(this)] = true;
        _isExcludedFromWhale[uniswapV2Pair] = true;
        _isExcludedFromWhale[projectAddress] = true;
        _isExcludedFromWhale[treasuryAddress] = true;
    }

    function checkForWhale(
        address from,
        address to,
        uint256 amount
    ) private view {
        uint256 newBalance = balanceOf(to).add(amount);
        if (!_isExcludedFromWhale[from] && !_isExcludedFromWhale[to]) {
            require(
                newBalance <= _walletHoldingMaxLimit,
                "Exceeding max tokens limit in the wallet"
            );
        }
        if (from == uniswapV2Pair && !_isExcludedFromWhale[to]) {
            require(
                newBalance <= _walletHoldingMaxLimit,
                "Exceeding max tokens limit in the wallet"
            );
        }
    }

    function setExcludedFromWhale(
        address account,
        bool _enabled
    ) public onlyOwner {
        _isExcludedFromWhale[account] = _enabled;
    }

    function setExcludedFromWhaleMany(
        address[] memory accounts,
        bool _enabled
    ) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromWhale[accounts[i]] = _enabled;
        }
    }

    function setWalletMaxHoldingLimit(uint256 _amount) public onlyOwner {
        _walletHoldingMaxLimit = _amount;
        require(
            _walletHoldingMaxLimit > _tTotal.div(10000).mul(1),
            "Too less limit"
        );
    }

    function rescueStuckBalance() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}