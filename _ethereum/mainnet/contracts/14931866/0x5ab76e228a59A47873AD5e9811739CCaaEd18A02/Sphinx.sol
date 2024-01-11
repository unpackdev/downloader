// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./INonfungiblePositionManager.sol";
import "./TransferHelper.sol";
import "./ISwapRouter02.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./Util.sol";
import "./UniswapV2.sol";

contract Sphinx is Context, IERC20, IERC721Receiver, Ownable{
    using SafeMath for uint256;
    using Address for address;
    mapping(uint256 => uint128) public deposits;
    address payable public devAddress = payable(0xBc09BB32e3bA81e3969f680B86a37f3f6abaAF80); 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 60 * 10 ** 6 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = "Secret of The Sphinx";
    string private constant _symbol = "SPHINX";
    uint8 private constant _decimals = 18;
    uint256 private constant BUY = 1;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;
    uint256 public startTime;
    uint256 public unlockTime;
    bool public autoFeeEnabled = false;
    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _buyTaxFee = 20;
    uint256 public _buyLiquidityFee = 80;
    uint256 public _buyDevFee = 50;
    bool public tradingActive = false;
    bool public antiBotsActive = false;
    mapping(address => uint256) public _blockNumberByAddress;
    mapping(address => bool) public isContractExempt;
    uint public blockCooldownAmount = 1;
    uint256 private _liquidityTokensToSwap;
    uint256 private _devTokensToSwap;
    mapping (address => bool) public automatedMarketMakerPairs;
    ISwapRouter02 public uniswapV3Router;
    IUniswapV3Pool public v3Pool;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;  //Ethereum mainnet
    uint24 public constant poolFee = 500;
    INonfungiblePositionManager public nonfungiblePositionManager;
    uint256 public positionX1;
    uint256 public positionX2;
    uint256 public positionX3;
    uint256 public positionX4;
    uint256 public currentPrice;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool inSwap;
    bool public swapEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        address newOwner = msg.sender;    
        _rOwned[newOwner] = _rTotal;
        uniswapV3Router = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), USDC);
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        _isExcludedFromFee[newOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        isContractExempt[address(this)] = true;
        isContractExempt[address(uniswapV2Router)] = true;
        isContractExempt[address(uniswapV3Router)] = true;
        isContractExempt[address(uniswapV2Pair)] = true;
        isContractExempt[address(nonfungiblePositionManager)] = true;
        emit Transfer(address(0), newOwner, _tTotal);
    }

    function _createDeposit(uint256 tokenId) internal {
        (, , , , , , , uint128 liquidity, , , , ) =
            nonfungiblePositionManager.positions(tokenId);
        deposits[tokenId] = liquidity;
    }

    function init(address _v3Address, uint256 tokenVal, uint256 usdcVal) external onlyOwner {
        TransferHelper.safeTransferFrom(address(this), msg.sender, address(this), tokenVal);
        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), usdcVal);
        startTime = block.timestamp;
        unlockTime = startTime + (180 days);
        tradingActive = true;
        swapEnabled = true;
        antiBotsActive = true;
        autoFeeEnabled = true;
        isContractExempt[_v3Address] = true;
        _setAutomatedMarketMakerPair(_v3Address, true);
        v3Pool = IUniswapV3Pool(_v3Address);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = v3Pool.slot0();
        int24 lessTick = tick < 0 ? (tick / 10) * 10 - 10 : (tick / 10) * 10 + 10;
        int24 overTick = tick < 0 ? (tick / 10) * 10 + 10 : (tick / 10) * 10 - 10;
        currentPrice = uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(1e18) >> (96 * 2);
        (int24 tickX1, int24 tickX2, int24 tickX3, int24 tickX4) = calculateTicks(currentPrice, tick);
        positionX1 = mintNewPosition(0, usdcVal, tickX1, lessTick);
        positionX2 = mintNewPosition(tokenVal.mul(20).div(100), 0, overTick, tickX2);
        positionX3 = mintNewPosition(tokenVal.mul(30).div(100), 0, tickX2, tickX3);
        positionX4 = mintNewPosition(tokenVal.mul(50).div(100), 0, tickX3, tickX4);
    }

    function reorg() public onlyOwner {
        decreaseLiquidity(positionX1);
        collectFees(positionX1);
        decreaseLiquidity(positionX2);
        collectFees(positionX2);
        decreaseLiquidity(positionX3);
        collectFees(positionX3);
        decreaseLiquidity(positionX4);
        collectFees(positionX4);
        uint256 tokenVal = balanceOf(address(this));
        uint256 usdcVal = IERC20(USDC).balanceOf(address(this)); 

        uint256 usdcForDev = usdcVal.div(100);
        TransferHelper.safeTransfer(USDC, devAddress, usdcForDev);

        usdcVal = usdcVal - usdcForDev;

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = v3Pool.slot0();
        int24 lessTick = tick < 0 ? (tick / 10) * 10 - 10 : (tick / 10) * 10 + 10;
        int24 overTick = tick < 0 ? (tick / 10) * 10 + 10 : (tick / 10) * 10 - 10;
        currentPrice = uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(1e18) >> (96 * 2);
        (int24 tickX1, int24 tickX2, int24 tickX3, int24 tickX4) = calculateTicks(currentPrice, tick);
        positionX1 = mintNewPosition(0, usdcVal, tickX1, lessTick);
        positionX2 = mintNewPosition(tokenVal.mul(20).div(100), 0, overTick, tickX2);
        positionX3 = mintNewPosition(tokenVal.mul(30).div(100), 0, tickX2, tickX3);
        positionX4 = mintNewPosition(tokenVal.mul(50).div(100), 0, tickX3, tickX4);
    }

    function unlock() external onlyOwner {
        require(unlockTime < block.timestamp, "Cannot unlock until 6 month");
        decreaseLiquidity(positionX1);
        collectFees(positionX1);
        decreaseLiquidity(positionX2);
        collectFees(positionX2);
        decreaseLiquidity(positionX3);
        collectFees(positionX3);
        decreaseLiquidity(positionX4);
        collectFees(positionX4);
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this)); 
        uint256 tokenBalance = balanceOf(address(this));
        TransferHelper.safeTransfer(USDC, devAddress, usdcBalance);
        TransferHelper.safeTransfer(address(this), devAddress, tokenBalance);
    }

    function calculateTicks(uint256 _currentPrice, int24 _currentTick)internal pure returns(int24 tickX1, int24 tickX2, int24 tickX3, int24 tickX4){
        uint160 sqrtX1; 
        uint160 sqrtX2;
        uint160 sqrtX3;
        uint160 sqrtX4;
        if(_currentTick < 0){
            sqrtX1 = uint160(Util.sqrt(((_currentPrice - _currentPrice.div(10)) << (96 * 2)).div(1e18)));
            sqrtX2 = uint160(Util.sqrt(((_currentPrice.mul(2)) << (96 * 2)).div(1e18)));
            sqrtX3 = uint160(Util.sqrt(((_currentPrice.mul(3)) << (96 * 2)).div(1e18)));
            sqrtX4 = uint160(Util.sqrt(((_currentPrice.mul(4)) << (96 * 2)).div(1e18)));
        }else{
            sqrtX1 = uint160(Util.sqrt(((_currentPrice + _currentPrice.div(10)) << (96 * 2)).div(1e18)));
            sqrtX2 = uint160(Util.sqrt(((_currentPrice.div(2)) << (96 * 2)).div(1e18)));
            sqrtX3 = uint160(Util.sqrt(((_currentPrice.div(3)) << (96 * 2)).div(1e18)));
            sqrtX4 = uint160(Util.sqrt(((_currentPrice.div(4)) << (96 * 2)).div(1e18)));
        }
       
        tickX1 = (TickMath.getTickAtSqrtRatio(sqrtX1) / 10) * 10;
        tickX2 = (TickMath.getTickAtSqrtRatio(sqrtX2) / 10) * 10;
        tickX3 = (TickMath.getTickAtSqrtRatio(sqrtX3) / 10) * 10;
        tickX4 = (TickMath.getTickAtSqrtRatio(sqrtX4) / 10) * 10;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
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
    ) external override returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
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

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Cannot remove pair");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        if(value){excludeFromReward(pair);}
        if(!value){includeInReward(pair);}
    }

    // How many reward received, deductTransferFee = true
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
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
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length + 1 <= 50, "Cannot exclude more than 50 accounts.");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
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
        
        if (!tradingActive){
            require(!automatedMarketMakerPairs[from] || !automatedMarketMakerPairs[to] , "Cannot add liquidity");
        }

        if(antiBotsActive)
        {
            if(!isContractExempt[from] && !isContractExempt[to])
            {
                address human = Util.ensureOneHuman(from, to);
                ensureMaxTxFrequency(human);
                _blockNumberByAddress[human] = block.number;
            }
        }

        removeAllFee();

        if(autoFeeEnabled){
            if( block.timestamp < startTime + (7 days)){
                _buyTaxFee = 20;
                _buyLiquidityFee = 50;
                _buyDevFee = 30;
                autoFeeEnabled = false;
            }
        }

        buyOrSellSwitch = TRANSFER;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee + _buyDevFee;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = BUY;
                }
            }
        }

        _tokenTransfer(from, to, amount);

        restoreAllFee();
    }

    function swapExactInputSingle(uint256 _amount) private {
        approve(address(uniswapV3Router), _amount);
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                amountIn: _amount / 2,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uniswapV3Router.exactInputSingle(params);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
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
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
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
        if(buyOrSellSwitch == BUY){
            _liquidityTokensToSwap += tLiquidity * _buyLiquidityFee / _liquidityFee;
            _devTokensToSwap += tLiquidity * _buyDevFee / _liquidityFee;
        } 
        
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**3);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**3);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setFee(uint256 buyTaxFee, uint256 buyLiquidityFee, uint256 buyDevFee, address _devAddress) external onlyOwner {
        _buyTaxFee = buyTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyDevFee = buyDevFee;
        devAddress = payable(_devAddress);
        _isExcludedFromFee[devAddress] = true;
    }

    function mintNewPosition(uint256 tokenAmount, uint256 usdcAmount, int24 xTickLower, int24 xTickUpper)
        private
        returns (
            uint256 tokenId
        )
    {
        address token0;
        address token1;
        uint token0Amount;
        uint token1Amount;
        int24 minTick = xTickLower < xTickUpper ? xTickLower : xTickUpper;
        int24 maxTick = xTickLower < xTickUpper ? xTickUpper : xTickLower;
        maxTick = TickMath.MAX_TICK < maxTick ? TickMath.MAX_TICK : maxTick;
        minTick = minTick < TickMath.MIN_TICK? TickMath.MIN_TICK : minTick;
        TransferHelper.safeApprove(address(this), address(nonfungiblePositionManager), tokenAmount);
        TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), usdcAmount);
        if (address(this) < USDC) {
            token0 = address(this);
            token1 = USDC;
            token0Amount = tokenAmount;
            token1Amount = usdcAmount;
        } else {
            token0 = USDC;
            token1 = address(this);
            token0Amount = usdcAmount;
            token1Amount = tokenAmount;
        }
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: poolFee,
                tickLower: minTick,
                tickUpper: maxTick,
                amount0Desired: token0Amount,
                amount1Desired: token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });
        (tokenId, , , ) = nonfungiblePositionManager.mint(params);
        _createDeposit(tokenId);
    }

    function decreaseLiquidity(uint256 tokenId) private {
        uint128 liquidity = deposits[tokenId];
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        nonfungiblePositionManager.decreaseLiquidity(params);
    }

    function collectFees(uint256 tokenId) private {
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        nonfungiblePositionManager.collect(params);
    }

    function extendUnLock(uint256 _unlockDates) external onlyOwner {
        unlockTime = block.timestamp + _unlockDates * (1 days);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        _createDeposit(tokenId);
        return this.onERC721Received.selector;
    }

    function ensureMaxTxFrequency(address addr) internal virtual {
        bool isAllowed = _blockNumberByAddress[addr] == 0 ||
            ((_blockNumberByAddress[addr] + blockCooldownAmount) < (block.number + 1));
        require(isAllowed, "Max tx frequency exceeded!");
    }

    function setContractExempt(address account, bool value) external onlyOwner {
        isContractExempt[account] = value;
    }

    receive() external payable {}

    function removeStuck(address _token, address _to) external onlyOwner {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, _to, _contractBalance);
    }
}