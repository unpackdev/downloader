/**

 /$$   /$$                              /$$$$$$                           /$$     /$$                           
| $$  | $$                             |_  $$_/                          |  $$   /$$/                           
| $$  | $$  /$$$$$$   /$$$$$$   /$$$$$$  | $$   /$$$$$$$  /$$   /$$       \  $$ /$$//$$$$$$   /$$$$$$   /$$$$$$ 
| $$$$$$$$ |____  $$ /$$__  $$ /$$__  $$ | $$  | $$__  $$| $$  | $$        \  $$$$//$$__  $$ |____  $$ /$$__  $$
| $$__  $$  /$$$$$$$| $$  \ $$| $$  \ $$ | $$  | $$  \ $$| $$  | $$         \  $$/| $$$$$$$$  /$$$$$$$| $$  \__/
| $$  | $$ /$$__  $$| $$  | $$| $$  | $$ | $$  | $$  | $$| $$  | $$          | $$ | $$_____/ /$$__  $$| $$      
| $$  | $$|  $$$$$$$| $$$$$$$/| $$$$$$$//$$$$$$| $$  | $$|  $$$$$$/          | $$ |  $$$$$$$|  $$$$$$$| $$      
|__/  |__/ \_______/| $$____/ | $$____/|______/|__/  |__/ \______/           |__/  \_______/ \_______/|__/      
                    | $$      | $$                                                                              
                    | $$      | $$                                                                              
                    |__/      |__/                                                                           

Twitter: https://twitter.com/Happinuyear2022
Telegram: https://t.me/happinuyear
Website: https://www.happinuyear.com

- Tokenomics: 80% burn (Every day, new random burn, from 1 to 10% of the remaining supply) | 10% use for liquidity | 10% use for presale
- Ownership will be transferred to the dead address after the audit
- 6% of the fee will be used to automatically add liquidity to the liquidityLockAddress. Liquidity will be sent to deadAdress to create a deflation mechanism that will reduce supply and increase liquidity by time.
- 3% fee sent to marketingAddress will be used to promote the project 100% transparency with the DAO.
- 3% fee sent to nftAddress will be used to buy NFT chosen by the DAO and share them randomly with token holders.
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.3;

import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract HappInuYear is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    address payable public marketingAddress = payable(0xfe727321BEbec92B515bC1F0F77FC1cBC47Eee9E);
    address payable public nftAddress = payable(0xd4F12167ED3DB5569C510783282dbD6256F44FD5);
    address payable public liquidityLockAddress = payable(0x000000000000000000000000000000000000dEaD);
    address public constant uniSwapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isSniper;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 2022 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "HappInuYear";
    string private constant _symbol = "HIY";

    uint8 private constant _decimals = 9;
    uint8 public taxFee;
    uint8 private _previousTaxFee = taxFee;
    uint8 public totalFee = 12;
    uint8 private _previousTotalFee = totalFee;
    uint8 public marketingFee = 3;
    uint8 public nftFee = 3;
    uint8 public highPriceImpactMultiplicator = 1;

    bool public swapAndLiquifyEnabled = false;
    bool public feesAfterHighPriceImpactEnabled = false;
    bool inSwapAndLiquify;

    uint256 public maxTxAmount = 20 * 10**6 * 10**9;
    uint256 private minimumTokensBeforeSwap = 1 * 10**6 * 10**9;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    event FeesAfterHighPriceImpactEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event UniswapV2PairUpdated(address pairAddress);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        uniswapV2Router = IUniswapV2Router02(uniSwapRouterAddress);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[nftAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function isBlockedSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function blockSniper(address account) external onlyOwner {
        require(!_isSniper[account], "Account is already blacklisted");
        _isSniper[account] = true;
    }

    function amnestySniper(address account) external onlyOwner {
        require(_isSniper[account], "Account is not blacklisted");
        _isSniper[account] = false;
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isSniper[to], "You have no power here!");
        require(!_isSniper[from], "You have no power here!");

        if (from != owner() && to != owner() && from != address(this)) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            to == uniswapV2Pair &&
            balanceOf(address(this)) >= minimumTokensBeforeSwap
        ) {
            swapAndLiquify(minimumTokensBeforeSwap);
        }

        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        if (!takeFee) removeAllFee();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(amount, to);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(from, to, tTransferAmount);
        if (!takeFee) restoreAllFee();
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        uint256 liquidityDivisor = totalFee.sub(marketingFee).sub(nftFee).div(2);
        uint256 tokenForLiquify = tokenAmount.mul(liquidityDivisor).div(totalFee);
        uint256 tokenForSwap = tokenAmount.sub(tokenForLiquify);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokenForSwap);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 balanceForLiquidity = transferredBalance.mul(liquidityDivisor).div(totalFee.sub(liquidityDivisor));
        addLiquidity(tokenForLiquify, balanceForLiquidity);

        uint256 leftoverBalance = address(this).balance;
        uint256 halfAmount = leftoverBalance.div(2);
        transferToAddressETH(marketingAddress, halfAmount);
        transferToAddressETH(nftAddress, leftoverBalance.sub(halfAmount));

        emit SwapAndLiquify(tokenForSwap, balanceForLiquidity, tokenForLiquify);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        require(tokenAmount <= balanceOf(address(this)), "Not enough HIY in contract balance");
        require(ethAmount <= address(this).balance, "Not enough ETH in contract balance");
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityLockAddress,
            block.timestamp
        );
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

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, address recipient)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, recipient);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, address recipient)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(10**2);
        uint256 tLiquidity = calculateFinalFee(tAmount, recipient);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _priceImpact(uint256 transferAmount) private view returns (uint256) {
        (uint256 reserves0, uint256 reserves1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        (uint256 reserveA, uint256 reserveB) = address(this) == IUniswapV2Pair(uniswapV2Pair).token0()
            ? (reserves0, reserves1)
            : (reserves1, reserves0);
        if (reserveA == 0 || reserveB == 0) {
            return 0;
        }
        uint256 exactQuote = transferAmount.mul(reserveB).div(reserveA);
        uint256 outputAmount = IUniswapV2Router02(uniSwapRouterAddress).getAmountOut(
            transferAmount,
            reserveA,
            reserveB
        );
        return exactQuote.sub(outputAmount).mul(10**2).div(exactQuote);
    }

    function _calculateHighPriceImpactFee(uint256 priceImpact) private view returns (uint256) {
        uint256 tax = 0;
        if (priceImpact >= 1 && priceImpact < 2) {
            tax = 2;
        } else if (priceImpact >= 2 && priceImpact < 3) {
            tax = 3;
        } else if (priceImpact >= 3 && priceImpact < 4) {
            tax = 4;
        } else if (priceImpact >= 4) {
            tax = 5;
        }
        return tax.mul(highPriceImpactMultiplicator);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }

    function calculateFinalFee(uint256 _amount, address recipient) private view returns (uint256) {
        if (!swapAndLiquifyEnabled) {
            return 0;
        }
        if (feesAfterHighPriceImpactEnabled && recipient == uniswapV2Pair && totalFee > 0) {
            uint256 priceImpact = _priceImpact(_amount);
            uint256 highPriceImpactFee = _calculateHighPriceImpactFee(priceImpact);
            uint256 finalFee = totalFee.add(highPriceImpactFee);
            return _amount.mul(finalFee).div(10**2);
        }
        return _amount.mul(totalFee).div(10**2);
    }

    function removeAllFee() private {
        if (taxFee == 0 && totalFee == 0) return;
        _previousTaxFee = taxFee;
        _previousTotalFee = totalFee;
        taxFee = 0;
        totalFee = 0;
    }

    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        totalFee = _previousTotalFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint8 fee) external onlyOwner {
        require(fee <= 5, "fee too high");
        taxFee = fee;
    }

    function setTotalFeePercent(uint8 fee) external onlyOwner {
        require(fee <= 10, "fee too high");
        totalFee = fee;
    }

    function setMaxTxAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount;
    }

    function setMarketingFee(uint8 fee) external onlyOwner {
        require(fee <= 3, "fee too high");
        marketingFee = fee;
    }

    function setNftFee(uint8 fee) external onlyOwner {
        require(fee <= 3, "fee too high");
        nftFee = fee;
    }

    function setHighPriceImpactMultiplicator(uint8 multiplicator) external onlyOwner {
        require(multiplicator <= 10, "multiplicator too high");
        highPriceImpactMultiplicator = multiplicator;
    }

    function setMinimumTokensBeforeSwap(uint256 _minimumTokensBeforeSwap) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
    }

    function setNftAddress(address _nftAddress) external onlyOwner {
        nftAddress = payable(_nftAddress);
    }

    function setLiquidityLockAddress(address _liquidityLockAddress) external onlyOwner {
        liquidityLockAddress = payable(_liquidityLockAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setFeesAfterHighPriceImpactEnabled(bool _enabled) public onlyOwner {
        feesAfterHighPriceImpactEnabled = _enabled;
        emit FeesAfterHighPriceImpactEnabledUpdated(_enabled);
    }

    function setUniswapV2Pair(address _uniswapV2Pair) public onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
        emit UniswapV2PairUpdated(_uniswapV2Pair);
    }

    function prepareForPreSale() external onlyOwner {
        swapAndLiquifyEnabled = false;
        feesAfterHighPriceImpactEnabled = false;
    }

    function beforeLiquidityAdded() external onlyOwner {
        swapAndLiquifyEnabled = true;
    }

    function afterLiquidityAdded(address _uniswapV2Pair) external onlyOwner {
        setUniswapV2Pair(_uniswapV2Pair);
        swapAndLiquifyEnabled = true;
        feesAfterHighPriceImpactEnabled = true;
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    receive() external payable {}
}
