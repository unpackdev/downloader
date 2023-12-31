/**
Website: https://earnx.tech
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniRouter.sol";
import "./IUniFactory.sol";
import "./SafeMath.sol";

contract Earn is Ownable, IERC20 {
    using SafeMath for uint256;

    address WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "EarnX";
    string constant _symbol = "EARN";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * 10 ** _decimals; // 100B

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isNotABot;
    mapping(address => bool) isExemptFromFees;

    mapping(address => bool) public blacklisted;

    uint256 private liquidityFee = 0;
    uint256 private devFee = 400; // 2%
    uint256 private buyFriendTechKeysFee = 600; // 3%
    uint256 public totalFee = liquidityFee + devFee + buyFriendTechKeysFee;
    uint256 private feeDenominator = 1000;

    // no bots tax
    uint256 public sellpercent = 490;
    uint256 public buypercent = 490;
    uint256 public transferpercent = 0;
    uint256 public whitelistPercent = 0;

    // Fee Receiver
    address private devFeeReceiver = 0x8ac5e8047356c67A53cC8ADe0e29e170381E0D54;
    address private buyFriendTechKeysFeesReceiver = 0x8C6B5D1FdeA7877fD3FbBbEeac00e6fA4D0Df95D;
    address private autoLiquidityReceiver;

    uint256 setRatio = 30;
    uint256 setRatioDenominator = 100;

    IUniRouter public router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public pair;
    bool public TRADING_OPEN = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    bool inSwap;

    // Events
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Events
    event AutoAddLiquify(uint256 amountETH, uint256 amountTokens);
    event UpdateTax(uint8 Buy, uint8 Sell, uint8 Transfer);
    event ClearToken(address TokenAddressCleared, uint256 Amount);
    event SetReceivers(address autoLiquidityReceiver, address devFee, address buyFriendTechKeysFee);
    event UpdateMaxWallet(uint256 maxWallet);
    event UpdateSwapBackSetting(uint256 Amount, bool Enabled);

    constructor () {
        WETH = router.WETH();
        _allowances[address(this)][address(router)] = type(uint256).max;

        autoLiquidityReceiver = msg.sender;

        isExemptFromFees[msg.sender] = true;
        isNotABot[msg.sender] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function decimals() external pure returns (uint8) {return _decimals;}

    function symbol() external pure returns (string memory) {return _symbol;}

    function name() external pure returns (string memory) {return _name;}

    function getOwner() external view returns (address) {return owner();}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function checkRatio(uint256 ratio, uint256 accuracy) public view returns (bool) {
        return showBacking(accuracy) > ratio;
    }

    function showBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(showSupply());
    }

    function showSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function manualSend() external {
        payable(autoLiquidityReceiver).transfer(address(this).balance);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!blacklisted[sender], "Sender blacklisted");
        require(!blacklisted[recipient], "Receiver blacklisted");

        if (inSwap) {return _basicTransfer(sender, recipient, amount);}

        if (sender != owner() && recipient != owner()) {
            require(TRADING_OPEN, "Trading not open yet");
        }

        if (_shouldSwapBack()) {
            _swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isExemptFromFees[sender] || isExemptFromFees[recipient]) ? amount : _takeFee(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _shouldTakeFee(address sender) internal view returns (bool) {
        return !isExemptFromFees[sender];
    }

    function _takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        uint256 percent = transferpercent;
        if (recipient == pair) {
            percent = sellpercent;
        } else if (sender == pair) {
            percent = buypercent;

            if (isNotABot[recipient]) {
                percent = whitelistPercent;
            }
        }

        uint256 feeAmount = amount.mul(totalFee).mul(percent).div(feeDenominator * 1000);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
    }

    function _swapBack() internal swapping {
        uint256 dynamicLiquidityFee = checkRatio(setRatio, setRatioDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHTeam = amountETH.mul(devFee).div(totalETHFee);
        uint256 amountETHbuykeys = amountETH.mul(buyFriendTechKeysFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHTeam}("");
        (tmpSuccess,) = payable(buyFriendTechKeysFeesReceiver).call{value: amountETHbuykeys}("");

        tmpSuccess = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoAddLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function _setFees() internal {
        emit UpdateTax(uint8(totalFee.mul(buypercent).div(feeDenominator)),
            uint8(totalFee.mul(sellpercent).div(feeDenominator)),
            uint8(totalFee.mul(transferpercent).div(feeDenominator))
        );
    }

    // ====================================== OWNER =============================================
    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        if (tokens == 0) {
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }

        emit ClearToken(tokenAddress, tokens);
        return IERC20(tokenAddress).transfer(autoLiquidityReceiver, tokens);
    }

    function updateFees(uint256 _percentonbuy, uint256 _percentonsell, uint256 _wallettransfer) external onlyOwner {
        sellpercent = _percentonsell;
        buypercent = _percentonbuy;
        transferpercent = _wallettransfer;
    }

    function startTrading() public onlyOwner {
        TRADING_OPEN = true;
    }

    function setParameters(uint256 _liquidityFee, uint256 _devFee, uint256 _buyFriendTechKeysFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        devFee = _devFee;
        buyFriendTechKeysFee = _buyFriendTechKeysFee;

        totalFee = _liquidityFee.add(_devFee).add(_buyFriendTechKeysFee);
        feeDenominator = _feeDenominator;
        _setFees();
    }

    function setWallets(address _autoLiquidityReceiver, address _devFeeReceiver, address _buyFriendTechKeysFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        devFeeReceiver = _devFeeReceiver;
        buyFriendTechKeysFeesReceiver = _buyFriendTechKeysFeeReceiver;

        emit SetReceivers(autoLiquidityReceiver, devFeeReceiver, buyFriendTechKeysFeesReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit UpdateSwapBackSetting(swapThreshold, swapEnabled);
    }

    function markNotBot(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isNotABot[accounts[i]] = excluded;
        }
    }

    function setExemptFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExemptFromFees[accounts[i]] = excluded;
        }
    }

    function setWhitelistBuyPercent(uint256 _percent) public onlyOwner {
        whitelistPercent = _percent;
    }

    function blacklist(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklisted[accounts[i]] = excluded;
        }
    }

    function updatePair() external onlyOwner {
        pair = IUniFactory(router.factory()).getPair(WETH, address(this));
    }
}
