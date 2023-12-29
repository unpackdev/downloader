// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract FloridaMan is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _NAME = "Florida Man";
    string private constant _SYMBOL = "FMAN";
    uint8 private constant _DECIMALS = 18;

    uint256 private _totalSupply = 10000000 * (10 ** _DECIMALS);

    uint256 private _maxTxAmountPercent = 200; // 10000;
    uint256 private _maxTransferPercent = 200;
    uint256 private _maxWalletPercent = 200;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;

    IUniswapV2Router02 _router;
    address public pair;

    bool private _tradingAllowed = false;
    bool private _swapEnabled = true;
    uint256 private _swapTimes;
    bool private _swapping;

    uint256 private _liquidityFee = 0;
    uint256 private _rewardFee = 100;
    uint256 private _developmentFee = 100;
    uint256 private _totalFee = 300;
    uint256 private _sellFee = 300;
    uint256 private _denominator = 10000;

    uint256 public swapThreshold = (_totalSupply * 200) / 100000;
    uint256 private _minTokenAmount = (_totalSupply * 10) / 100000;

    modifier lockTheSwap() {
        _swapping = true;
        _;
        _swapping = false;
    }

    address internal constant _DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal _liquidityAddress = 0x000000000000000000000000000000000000dEaD;
    address internal _developmentAddress = 0x2726E6981a8a991108dE59D455F432DEeEC93A3A;
    address internal _rewardsAddress = 0x6611Ac05ed5849DCa21aAAfbe8A5DC46481420F4;

    constructor(address _ownerAddress) {
        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        address _pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        _router = router;
        pair = _pair;

        isFeeExempt[address(this)] = true;
        isFeeExempt[_liquidityAddress] = true;
        isFeeExempt[_rewardsAddress] = true;
        isFeeExempt[_ownerAddress] = true;

        _balances[_ownerAddress] = _totalSupply;
        emit Transfer(address(0), _ownerAddress, _totalSupply);

        transferOwnership(_ownerAddress);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function enableTrading() external onlyOwner {
        _tradingAllowed = true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    // solhint-disable-next-line private-vars-leading-underscore
    function isCont(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function setIsFeeExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address] = _enabled;
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function maxWalletToken() public view returns (uint256) {
        return (totalSupply() * _maxWalletPercent) / _denominator;
    }

    function maxTxAmount() public view returns (uint256) {
        return (totalSupply() * _maxTxAmountPercent) / _denominator;
    }

    function maxTransferAmount() public view returns (uint256) {
        return (totalSupply() * _maxTransferPercent) / _denominator;
    }

    function _preTxCheck(address _sender, address _recipient, uint256 _amount) internal view {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > uint256(0), "Transfer amount must be greater than zero");
        require(_amount <= balanceOf(_sender), "You are trying to transfer more than your balance");
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        _preTxCheck(_sender, _recipient, _amount);
        _checkTradingAllowed(_sender, _recipient);
        _checkMaxWallet(_sender, _recipient, _amount);
        _swapbackCounters(_sender, _recipient);
        _checkTxLimit(_sender, _recipient, _amount);
        _swapBack(_sender, _recipient, _amount);
        _balances[_sender] = _balances[_sender].sub(_amount);
        uint256 amountReceived = _shouldTakeFee(_sender, _recipient) ? _takeFee(_sender, _recipient, _amount) : _amount;
        _balances[_recipient] = _balances[_recipient].add(amountReceived);
        emit Transfer(_sender, _recipient, amountReceived);
    }

    function setFees(uint256 _liquidity, uint256 _reward, uint256 _development, uint256 _total, uint256 _sell)
        external
        onlyOwner
    {
        _liquidityFee = _liquidity;
        _rewardFee = _reward;
        _developmentFee = _development;
        _totalFee = _total;
        _sellFee = _sell;

        require(
            _totalFee <= _denominator.mul(10).div(25) && _sellFee <= _denominator.mul(10).div(25),
            "totalFee and sellFee cannot be more than 20%"
        );
    }

    function setLimits(uint256 _buy, uint256 _trans, uint256 _wallet) external onlyOwner {
        uint256 newTx = (totalSupply() * _buy) / 10000;
        uint256 newTransfer = (totalSupply() * _trans) / 10000;
        uint256 newWallet = (totalSupply() * _wallet) / 10000;
        _maxTxAmountPercent = _buy;
        _maxTransferPercent = _trans;
        _maxWalletPercent = _wallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(
            newTx >= limit && newTransfer >= limit && newWallet >= limit,
            "Max TXs and Max Wallet cannot be less than .5%"
        );
    }

    function _checkTradingAllowed(address _sender, address _recipient) internal view {
        if (!isFeeExempt[_sender] && !isFeeExempt[_recipient]) {
            require(_tradingAllowed, "_tradingAllowed");
        }
    }

    function _checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if (
            !isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(_DEAD)
        ) {
            require((_balances[recipient].add(amount)) <= maxWalletToken(), "Exceeds maximum wallet amount.");
        }
    }

    function _swapbackCounters(address sender, address recipient) internal {
        if (recipient == pair && !isFeeExempt[sender]) {
            _swapTimes += uint256(1);
        }
    }

    function _checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (sender != pair) {
            require(amount <= maxTransferAmount() || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
        }
        require(amount <= maxTxAmount() || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function _swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator = (_liquidityFee.add(1).add(_rewardFee).add(_developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(_liquidityFee).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        _swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance = deltaBalance.div(denominator.sub(_liquidityFee));
        uint256 ethToAddLiquidityWith = unitBalance.mul(_liquidityFee);
        if (ethToAddLiquidityWith > uint256(0)) _addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        uint256 nftRewardsAmt = unitBalance.mul(2).mul(_rewardFee);
        if (nftRewardsAmt > 0) payable(_rewardsAddress).transfer(nftRewardsAmt);
        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > uint256(0)) payable(_developmentAddress).transfer(remainingBalance);
    }

    function _swapTokensForETH(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), _tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(_router), _tokenAmount);
        _router.addLiquidityETH{value: _ethAmount}(
            address(this), _tokenAmount, 0, 0, _liquidityAddress, block.timestamp
        );
    }

    function _shouldSwapBack(address _sender, address _recipient, uint256 _amount) internal view returns (bool) {
        bool aboveMin = _amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !_swapping && _swapEnabled && _tradingAllowed && aboveMin && !isFeeExempt[_sender] && _recipient == pair
            && _swapTimes >= uint256(1) && aboveThreshold;
    }

    function _swapBack(address _sender, address _recipient, uint256 _amount) internal {
        if (_shouldSwapBack(_sender, _recipient, _amount)) {
            _swapAndLiquify(swapThreshold);
            _swapTimes = uint256(0);
        }
    }

    function _shouldTakeFee(address _sender, address _recipient) internal view returns (bool) {
        return !isFeeExempt[_sender] && !isFeeExempt[_recipient];
    }

    function _getTotalFee(address _sender, address _recipient) internal view returns (uint256) {
        if (_recipient == pair) {
            return _sellFee;
        }
        if (_sender == pair) {
            return _totalFee;
        }
        return 0;
    }

    function setLiquidityAddress(address _address) public onlyOwner {
        _liquidityAddress = _address;
    }

    function setRewardsAddress(address _address) public onlyOwner {
        _rewardsAddress = _address;
    }

    function setDevelopmentAddress(address _address) public onlyOwner {
        _developmentAddress = _address;
    }

    function changeSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
    }

    function _takeFee(address _sender, address _recipient, uint256 _amount) internal returns (uint256) {
        uint256 totalFee = _getTotalFee(_sender, _recipient);

        if (totalFee > 0) {
            uint256 feeAmount = _amount.mul(totalFee).div(_denominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(_sender, address(this), feeAmount);
            return _amount.sub(feeAmount);
        }
        return _amount;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            msg.sender,
            _allowances[_sender][msg.sender].sub(_amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}
