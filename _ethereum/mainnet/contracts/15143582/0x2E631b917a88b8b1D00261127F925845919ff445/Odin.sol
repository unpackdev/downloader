// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

interface IODINNFT {
    function checkAccountLevel(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _id) external view returns (address);
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IVRFV2RandomGeneration {
    function requestRandomWords() external;
    function getRandomWords() external view returns(uint256);
}

contract Odin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    string private _name = "Odineum";
    string private _symbol = "ODIN";
    uint8 private _decimals = 18;

    bool private _optionForOwner;
    uint256 public constant TIME_FOR_OPTION = 60 * 30;
    // uint256 public constant TIME_FOR_OPTION = 60 * 3;
    uint256 public launched_time;

    IUniswapV2Router02 public uniswapV2Router;
    address public uinswapV2Pair;
    address public usdtAddress;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000 * 10**6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tLiquidityAmount = 0;
    // 0.5% reward fee goes to contract itself
    uint256 public _rewardFee = 50;
    uint256 private _previousRewardFee = _rewardFee;
    // 1.5% tax fee goes to chartiy wallet
    uint256 public _taxFee = 150;
    uint256 private _previousTaxFee = _taxFee;
    // 3% tax nft fee goes to chartiy wallet
    uint256 public _taxNFTFee = 300;
    uint256 private _previousTaxNFTFee = _taxNFTFee;
    // 0.5% staking fee goes to stake contract address
    uint256 public _stakingFee = 50;
    uint256 private _previousStakingFee = _stakingFee;
    // reflection by nft levels
    uint256[] public levelFees = [50, 100, 150, 200, 300];
    uint256[] private _prevLevelFees = levelFees;
    // 0.001% max tx amount will trigger swap and add liquidity
    uint256 private _minTokenBalaceToLiquidity = _tTotal.mul(1).div(1000).div(100);
    uint256 public autoLiquidity = 0;
    uint256 private _prevAutoLiquidity = autoLiquidity;
    uint256 public lotteryHourly = 25;
    uint256 public lotteryDaily = 75;
    uint256 public _maxTxAmount = 10 * 10**6 * 10**_decimals;
    address private _charityAddress = 0x9Ad374DF6D6b7cF7808a4C3Fb0795f5827D7D5E7;
    address private _charityWallet;
    address private _stakingAddress;

    uint256 public lotteryLimitAmount = 10**6 * 10**_decimals;  // 0.001%
    uint256 public charityMinimum = 10**4 * 10**_decimals;
    uint256 public stakingMinimum = 10**4 * 10**_decimals;
    bool public pausedLottery = false;
    
    address public dailyAddress;
    address public hourlyAddress;
    IODINNFT public iODINNFT;

    uint256 public presaleEndsIn;

    address vrfFunctionAddress;
    IVRFV2RandomGeneration public iVRFV2RandomGeneration;

    struct GetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRewardFee;
        uint256 rStakingFee;
        uint256 tTransferAmount;
        uint256 tRewardFee;
        uint256 tBurnFee;
        uint256 tTaxFee;
        uint256 tStakingFee;
    }

    event SwapAndLiquify(uint256 tokensSwapped, uint256 usdtReceived, uint256 tokensIntoLiqudity);

    constructor(address _nftAddress, address payable routerAddress, address _usdtAddress, address _vrfAddress, uint256 _presaleEndsIn) {
        require(block.timestamp < _presaleEndsIn);
        presaleEndsIn = _presaleEndsIn;
        iODINNFT = IODINNFT(_nftAddress);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        usdtAddress = _usdtAddress;
        uinswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), address(usdtAddress));
        uniswapV2Router = _uniswapV2Router;
        _optionForOwner = true;
        launched_time = block.timestamp;

        _rOwned[_msgSender()] = _rTotal;
        _charityWallet = _charityAddress;
        // _stakingAddress = stakingAddress;
        _tOwned[_charityWallet] = 0;
        _rOwned[_charityWallet] = 0;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        vrfFunctionAddress = _vrfAddress;
        iVRFV2RandomGeneration = IVRFV2RandomGeneration(_vrfAddress);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function swapTokensForUSDT(
        address _routerAddress,
        uint256 tokenAmount,
        address _usdtAddress
    ) public {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_usdtAddress);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of usdt
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        address _routerAddress,
        address owner,
        uint256 tokenAmount,
        address _usdtAddress,
        uint256 usdtAmount
    ) internal {
        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            address(_usdtAddress),
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(balanceOf(recipient) + amount <= _tTotal * 2 / 100, "Overflow amount"); // 2% max wallet
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, address _account) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        GetValues memory item;
        if (!deductTransferFee) {
            item = _getValues(tAmount);
            return item.rAmount;
        } else {
            item = _getValues(tAmount);
            return item.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        GetValues memory item = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(item.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(item.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(item.rTransferAmount);
        _takeLiquidity(item.tBurnFee);
        _takeCharity(item.tTaxFee);
        _takeStaking(item.tStakingFee);
        emit Transfer(sender, recipient, item.tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function setStakingAddress(address _new) public onlyOwner() {
        _stakingAddress = _new;
    }

    function getStakingAddress() public view returns (address) {
        return _stakingAddress;
    }

    function _getValues(uint256 tAmount) private view returns (GetValues memory) {
        (uint256 tTransferAmount, uint256 tRewardFee, uint256 tBurnFee, uint256 tTaxFee, uint256 tStakingFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 rStakingFee) =
            _getRValues(tAmount, tRewardFee, tBurnFee, tTaxFee, tStakingFee);
        GetValues memory newValue = GetValues(rAmount, rTransferAmount, rRewardFee, rStakingFee, tTransferAmount, tRewardFee, tBurnFee, tTaxFee, tStakingFee);
        return newValue;
    }

    function _getTValues(uint256 tAmount) private view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _tAmount = tAmount;
        uint256 tRewardFee = calculateRewardFee(tAmount);
        uint256 tBurnFee = calculateLiquidityFee(tAmount);
        uint256 tTaxFee = calculateTaxFee(tAmount);
        uint256 tStakingFee = calculateStakingFee(tAmount);
        uint256 tTransferAmount = _tAmount.sub(tRewardFee).sub(tBurnFee).sub(tTaxFee).sub(tStakingFee);
        return (tTransferAmount, tRewardFee, tBurnFee, tTaxFee, tStakingFee);
    }

    function _getRValues(uint256 tAmount, uint256 tRewardFee, uint256 tBurnFee, uint256 tTaxFee, uint256 tStakingFee) private view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRewardFee = tRewardFee.mul(currentRate);
        uint256 rBurnFee = tBurnFee.mul(currentRate);
        uint256 rTaxFee = tTaxFee.mul(currentRate);
        uint256 rStakingFee = tStakingFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRewardFee).sub(rBurnFee).sub(rTaxFee).sub(rStakingFee);
        return (rAmount, rTransferAmount, rRewardFee, rStakingFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(10**4);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(autoLiquidity).div(10**4);
    }

    function calculateStakingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_stakingFee).div(10**4);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**4);
    }

    function removeAllFee() private {
        if (_taxFee == 0) return;
        _previousRewardFee = _rewardFee;
        _previousTaxFee = _taxFee;
        _previousTaxNFTFee = _taxNFTFee;
        _prevLevelFees = levelFees;
        
        _prevAutoLiquidity = autoLiquidity;
        _previousStakingFee = _stakingFee;

        _rewardFee = 0;
        _taxFee = 0;
        _taxNFTFee = 0;
        _stakingFee = 0;
        levelFees = [0, 0, 0, 0, 0, 0];
        autoLiquidity = 0;
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _taxFee = _previousTaxFee;
        _taxNFTFee = _previousTaxNFTFee;
        _stakingFee = _previousStakingFee;
        levelFees = _prevLevelFees;
        autoLiquidity = _prevAutoLiquidity;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        if(_optionForOwner && launched_time + TIME_FOR_OPTION >= block.timestamp) {
            require(iODINNFT.balanceOf(to) > 0, "Receipient must be a NFT holder.");
        }
        // if (block.timestamp <= presaleEndsIn) {
        //     require(iODINNFT.balanceOf(to) > 0, "Receipient must be a NFT holder.");
        // }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take reward, burn, tax fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        GetValues memory item = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(item.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(item.rTransferAmount);
        _takeLiquidity(item.tBurnFee);
        _takeCharity(item.tTaxFee);
        _reflectFee(item.rRewardFee, item.tRewardFee);
        _takeStaking(item.tStakingFee);
        emit Transfer(sender, recipient, item.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        GetValues memory item = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(item.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(item.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(item.rTransferAmount);
        _takeLiquidity(item.tBurnFee);
        _takeCharity(item.tTaxFee);
        _reflectFee(item.rRewardFee, item.tRewardFee);
        _takeStaking(item.tStakingFee);
        emit Transfer(sender, recipient, item.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        GetValues memory item = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(item.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(item.rTransferAmount);
        _takeLiquidity(item.tBurnFee);
        _takeCharity(item.tTaxFee);
        _reflectFee(item.rRewardFee, item.tRewardFee);
        _takeStaking(item.tStakingFee);
        emit Transfer(sender, recipient, item.tTransferAmount);
    }

    function _takeLiquidity(uint256 tBurnFee) private {
        _tLiquidityAmount = _tLiquidityAmount.add(tBurnFee);
        if (_tLiquidityAmount >= _minTokenBalaceToLiquidity) {
            // add liquidity
            autoSwapAndLiquidity(_tLiquidityAmount);
            _tLiquidityAmount = 0;
        }
    }

    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate = _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[_charityWallet] = _rOwned[_charityWallet].add(rCharity);
        uint256 initialBalance = IERC20(usdtAddress).balanceOf(address(this));
        if (_rOwned[_charityWallet] >= charityMinimum) {
            // add liquidity
            swapTokensForUSDT(address(uniswapV2Router), _rOwned[_charityWallet], usdtAddress);
            uint256 deltaBalance = IERC20(usdtAddress).balanceOf(address(this)).sub(initialBalance);
            _rOwned[_charityWallet] = 0;
            IERC20(usdtAddress).transfer(_charityWallet, deltaBalance);
        }
    }

    function _takeStaking(uint256 tStaking) private {
        uint256 currentRate = _getRate();
        uint256 rStaking = tStaking.mul(currentRate);
        _rOwned[_stakingAddress] = _rOwned[_stakingAddress].add(rStaking);
        uint256 initialBalance = IERC20(usdtAddress).balanceOf(address(this));
        if (_rOwned[_stakingAddress] >= stakingMinimum) {
            // add liquidity
            swapTokensForUSDT(address(uniswapV2Router), _rOwned[_stakingAddress], usdtAddress);
            uint256 deltaBalance = IERC20(usdtAddress).balanceOf(address(this)).sub(initialBalance);
            _rOwned[_stakingAddress] = 0;
            IERC20(usdtAddress).transfer(_stakingAddress, deltaBalance);
        }
    }

    function setLotteryAddress(address _dailyAddress, address _hourlyAddress) external onlyOwner {
        dailyAddress = _dailyAddress;
        hourlyAddress = _hourlyAddress;
    }

    function setLotteryState() external onlyOwner {
        pausedLottery = !pausedLottery;
    }

    function lotteryTransfer(address _winner) external {
        require(!pausedLottery, "Lottery is paused.");
        require(msg.sender == dailyAddress || msg.sender == hourlyAddress, "Can only be called by lottery contract");
        require(balanceOf(_winner) >= lotteryLimitAmount, "Can not be a winner from the efficient balance");
        uint256 lottery = 0;
        uint256 currentBalance = balanceOf(address(this));
        uint256 level = iODINNFT.checkAccountLevel(_winner);
        if (level == 0 || level > 6) return;
        uint256 levelPercent = levelFees[level - 1];
        uint256 lotteryPercent = lotteryHourly;
        if (_msgSender() == dailyAddress) lotteryPercent = lotteryDaily;
        lottery = currentBalance.mul(levelPercent).mul(lotteryPercent).div(10**8);
        _tokenTransfer(address(this), _winner, lottery, true);
    }

    function setLotteryLimit(uint256 _lotteryLimit) external onlyOwner {
        lotteryLimitAmount = _lotteryLimit;
    }

    function swapAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        bool shouldSell = contractTokenBalance >= _minTokenBalaceToLiquidity;
        if (
            shouldSell && 
            from != uinswapV2Pair && 
            !(from == address(this) && to == address(uinswapV2Pair)) // swap 1 time
        ) {
            contractTokenBalance = _minTokenBalaceToLiquidity;
            // add liquidity
            autoSwapAndLiquidity(contractTokenBalance);
        }
    }

    function autoSwapAndLiquidity(uint256 _tokenAmount) internal {
        // split the contract balance into 3 pieces
        uint256 pooledUSDT = _tokenAmount.div(2);
        uint256 piece = _tokenAmount.sub(pooledUSDT).div(2);
        uint256 otherPiece = _tokenAmount.sub(piece);
        uint256 tokenAmountToBeSwapped = pooledUSDT.add(piece);
        uint256 initialBalance = IERC20(usdtAddress).balanceOf(address(this));

        swapTokensForUSDT(address(uniswapV2Router), tokenAmountToBeSwapped, usdtAddress);
        uint256 deltaBalance = IERC20(usdtAddress).balanceOf(address(this)).sub(initialBalance);
        uint256 usdtToBeAddedToLiquidity = deltaBalance.div(3);
        // add liquidity to pancake
        addLiquidity(address(uniswapV2Router), owner(), otherPiece, usdtAddress, usdtToBeAddedToLiquidity);
        emit SwapAndLiquify(piece, deltaBalance, otherPiece);
    }

    function getWinner(uint256 seed) external view returns (address) {
        require(!pausedLottery, "Lottery is paused.");
        require(msg.sender == dailyAddress || msg.sender == hourlyAddress, "Can only be called by lottery contract");
        uint256 tSupply = iODINNFT.totalSupply();
        require(tSupply > 1, "Holders are not enough to run lottery");
        uint256 mod = tSupply - 1;

        uint256 rndNum = iVRFV2RandomGeneration.getRandomWords().mod(mod); // uint256(keccak256(abi.encode(block.timestamp, block.difficulty, block.coinbase, blockhash(block.number + 1), seed, block.number))).mod(mod);
        address winner = iODINNFT.ownerOf(rndNum);
        return winner;
    }

    function setWinner() external onlyOwner {
        iVRFV2RandomGeneration.requestRandomWords();
    }

    function turnOnOption() public onlyOwner {
        _optionForOwner = true;
    }

    function turnOffOption() public onlyOwner {
        _optionForOwner = false;
    }

    function getOption() public view returns (bool) {
        return _optionForOwner;
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getLimitTime() public view returns(uint256) {
        return launched_time + TIME_FOR_OPTION;
    }
}

