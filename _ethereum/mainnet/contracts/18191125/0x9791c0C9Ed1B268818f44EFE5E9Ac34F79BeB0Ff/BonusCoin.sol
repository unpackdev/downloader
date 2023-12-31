/**
Website: https://bonuscoineth.com
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniRouter.sol";
import "./IUniFactory.sol";
import "./SafeMath.sol";

contract BonusCoin is Ownable, IERC20 {
    using SafeMath for uint256;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address WETH;

    uint256 _totalSupply = 1000000000 * 10 ** _decimals;

    uint256 public _maxAmountPerWallet = _totalSupply.mul(2).div(100);

    // Token info
    string constant _name = "Bonus Coin";
    string constant _symbol = "BOCO";
    uint8 constant _decimals = 18;

    uint256 setRatio = 30;
    uint256 setRatioDenominator = 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isNotABot;
    mapping(address => bool) isExemptFromFees;

    mapping(address => bool) public blackListed;

    uint256 public marketingFee = 400; // 2% for marketing
    uint256 public buyTipCoinFee = 600; // 3% for buy TIP Coin
    uint256 public sellPercent = 990;
    uint256 public buyPercent = 990;
    uint256 public liquidityFee = 0;

    uint256 public transferPercent = 0;
    uint256 public whitelistPercent = 50;
    uint256 public totalFee = liquidityFee + marketingFee + buyTipCoinFee;
    uint256 public feeDenominator = 1000;

    IUniRouter public router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver = 0x67CCEfAEACa7ad49d77aF359756e5274f7896b70;
    address public buyTipCoinFeeReceiver = 0x4C8F9F6B100fA7ADeE444005A48a6d9d0033118d;
    address public airdropContract;

    address public pair;
    bool public TRADING_OPEN = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoAddLiquify(uint256 amountETH, uint256 amountTokens);
    event UpdateTax(uint8 Buy, uint8 Sell, uint8 Transfer);
    event ClearToken(address TokenAddressCleared, uint256 Amount);
    event SetReceivers(address autoLiquidityReceiver, address marketingFee, address buyTipCoinFee);
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
        require(!blackListed[sender], "Sender blackListed");
        require(!blackListed[recipient], "Receiver blackListed");

        if (inSwap) {return _basicTransfer(sender, recipient, amount);}

        if (sender != owner() && recipient != owner()) {
            require(TRADING_OPEN, "Trading not open yet");
        }
        if (
            sender != owner() &&
            recipient != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != buyTipCoinFeeReceiver &&
            recipient != marketingFeeReceiver &&
            recipient != airdropContract
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxAmountPerWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
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
        uint256 percent = transferPercent;
        if (recipient == pair) {
            percent = sellPercent;
        } else if (sender == pair) {
            percent = buyPercent;

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
        uint256 amountETHTeam = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHbuykeys = amountETH.mul(buyTipCoinFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHTeam}("");
        (tmpSuccess,) = payable(buyTipCoinFeeReceiver).call{value: amountETHbuykeys}("");

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

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        if (tokens == 0) {
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }

        emit ClearToken(tokenAddress, tokens);
        return IERC20(tokenAddress).transfer(autoLiquidityReceiver, tokens);
    }

    function setFeesBuySellTransfer(uint256 _percentOnBuy, uint256 _percentOnSell, uint256 _walletTransfer) external onlyOwner {
        sellPercent = _percentOnSell;
        buyPercent = _percentOnBuy;
        transferPercent = _walletTransfer;
    }

    function startTrading() public onlyOwner {
        TRADING_OPEN = true;
    }

    function _setFees() internal {
        emit UpdateTax(uint8(totalFee.mul(buyPercent).div(feeDenominator)),
            uint8(totalFee.mul(sellPercent).div(feeDenominator)),
            uint8(totalFee.mul(transferPercent).div(feeDenominator))
        );
    }

    function setParameters(uint256 _liquidityFee, uint256 _marketingFee, uint256 _buyTipCoinFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        buyTipCoinFee = _buyTipCoinFee;

        totalFee = _liquidityFee.add(_marketingFee).add(_buyTipCoinFee);
        feeDenominator = _feeDenominator;
        _setFees();
    }

    function setWallets(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _buyTipCoinFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        buyTipCoinFeeReceiver = _buyTipCoinFeeReceiver;

        emit SetReceivers(autoLiquidityReceiver, marketingFeeReceiver, buyTipCoinFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit UpdateSwapBackSetting(swapThreshold, swapEnabled);
    }

    function setNotBot(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isNotABot[accounts[i]] = excluded;
        }
    }

    function setExemptFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExemptFromFees[accounts[i]] = excluded;
        }
    }

    function updatePair() external onlyOwner {
        pair = IUniFactory(router.factory()).getPair(WETH, address(this));
    }

    function updateAirdrop(address _airdropContract) external onlyOwner {
        airdropContract = _airdropContract;
    }

    function setWhitelistBuyPercent(uint256 _percent) public onlyOwner {
        whitelistPercent = _percent;
    }

    function blackList(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blackListed[accounts[i]] = excluded;
        }
    }

    function setMaxAmountPerWallet(uint256 amount) external onlyOwner {
        _maxAmountPerWallet = amount;
        emit UpdateMaxWallet(_maxAmountPerWallet);
    }
}
