// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Cousin is Context, IERC20, Ownable
{
    using Address for address;

    string public name = "Cousin";
    string public symbol = "CUZ";

    uint public decimals = 18;
    uint public totalSupply = 1000000000 * 10 ** decimals;

    uint public swapThresholdMin = totalSupply / 5000;
    uint public swapThresholdMax = totalSupply / 1000;

    address public dexPair;
    IUniswapV2Router02 public dexRouter;

    address payable public marketingAddress;

    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowances;

    bool private MEVMilk;
    uint private milkLevel;
    uint private milkPenalty;

    mapping (address => uint) private transferTime;
    mapping (address => bool) private isTrackerExempt;
    mapping (address => bool) private isCaughtMEV;

    mapping (address => bool) public isMarketPair;
    mapping (address => bool) private isFeeExempt;

    struct Fees
    {
        uint inFee;
        uint outFee;
        uint transferFee;
    }

    Fees public fees;

    bool public MEVMilkRenounced;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public swapAndLiquifyByLimitOnly;

    event SwapAndLiquifyStatusUpdated(bool status);
    event SwapAndLiquifyByLimitStatusUpdated(bool status);
    event SwapTokensForETH(uint amountIn, address[] path);

    modifier lockTheSwap
    {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _marketing)
    {
        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        allowances[address(this)][address(dexRouter)] = type(uint).max;

        marketingAddress = payable(_marketing);

        fees.inFee = 200;
        fees.outFee = 200;
        fees.transferFee = 0;

        MEVMilk = true;
        milkLevel = 2;
        milkPenalty = 9900;

        swapAndLiquifyEnabled = true;
        swapAndLiquifyByLimitOnly = true;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(0)] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingAddress] = true;

        isTrackerExempt[address(dexPair)] = true;
        isTrackerExempt[address(dexRouter)] = true;

        isMarketPair[address(dexPair)] = true;

        balances[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function balanceOf(address wallet) public view override returns (uint)
    {
        return balances[wallet];
    }

    function allowance(address owner, address spender) public view override returns (uint)
    {
        return allowances[owner][spender];
    }

    function getCirculatingSupply() public view returns (uint)
    {
        return totalSupply - balanceOf(address(0));
    }

    function getMEVStatus(address wallet) public view returns (bool)
    {
        return isCaughtMEV[wallet];
    }

    function getCheckMEVStatus(address wallet) public view returns (bool)
    {
        return isTrackerExempt[wallet];
    }

    function getMilkLevel() public view returns (string memory)
    {
        if (!MEVMilk)
            return "Milk Off";
        else if (milkLevel == 0)
            return "Milk Warning";
        else if (milkLevel == 1)
            return "99% MEV Milk";
        else
            return "99% MEV Milk+";
    }

    function setMarketingAddress(address wallet) external onlyOwner()
    {
        require(wallet != address(0), "ERROR: Wallet must not be null address!");
        require(wallet != marketingAddress, "ERROR: Wallet must not be existing address!");

        isFeeExempt[marketingAddress] = false;

        marketingAddress = payable(wallet);
        isFeeExempt[marketingAddress] = true;
    }

    function setMarketPairStatus(address wallet, bool status) external onlyOwner()
    {
        isMarketPair[wallet] = status;
    }

    function setMEVMilk(bool status) external onlyOwner()
    {
        require(!MEVMilkRenounced, "ERROR: Anti-MEV system is permanently disabled!");
        MEVMilk = status;
    }

    function setMilkLevel(uint level) external onlyOwner()
    {
        require(!MEVMilkRenounced, "ERROR: Anti-MEV system is permanently disabled!");
        require(level == 0 || level == 1 || level == 2, "ERROR: Protection level must be 0, 1 or 2");
        milkLevel = level;
    }

    function setMilkPenalty(uint penalty) external onlyOwner()
    {
        require(!MEVMilkRenounced, "ERROR: Anti-MEV system is permanently disabled!");
        require(milkPenalty <= 10000, "ERROR: Penalty exceeds 100%!");
        milkPenalty = penalty;
    }

    function setCaughtMEV(address[] memory wallets, bool status) external onlyOwner()
    {
        require(!MEVMilkRenounced, "ERROR: Anti-MEV system is permanently disabled!");
        require(wallets.length <= 200, "ERROR: Maximum wallets at once is 200!");

        for (uint i = 0; i < wallets.length; i++)
            isCaughtMEV[wallets[i]] = status;
    }

    function setCheckMEV(address[] memory wallets, bool status) external onlyOwner()
    {
        require(!MEVMilkRenounced, "ERROR: Anti-MEV system is permanently disabled!");
        require(wallets.length <= 200, "ERROR: Maximum wallets at once is 200!");

        for (uint i = 0; i < wallets.length; i++)
            isTrackerExempt[wallets[i]] = status;
    }

    function renounceMEVMilk() external onlyOwner()
    {
        require(!MEVMilkRenounced, "ERROR: Anti-MEV system is already renounced!");
        MEVMilkRenounced = true;
    }

    function setFees(uint inFee, uint outFee, uint transferFee) external onlyOwner()
    {
        require(inFee <= 200 && outFee <= 200 && transferFee <= 200, "ERROR: Maximum directional fee is 2%!");

        fees.inFee = inFee;
        fees.outFee = outFee;
        fees.transferFee = transferFee;
    }

    function setSwapThresholds(uint swapMin, uint swapMax) external onlyOwner()
    {
        swapThresholdMin = swapMin;
        swapThresholdMax = swapMax;
    }

    function setSwapAndLiquifyStatus(bool status) external onlyOwner()
    {
        swapAndLiquifyEnabled = status;
        emit SwapAndLiquifyStatusUpdated(status);
    }

    function setSwapAndLiquifyByLimitStatus(bool status) external onlyOwner()
    {
        swapAndLiquifyByLimitOnly = status;
        emit SwapAndLiquifyByLimitStatusUpdated(status);
    }

    function approve(address spender, uint amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private
    {
        require(owner != address(0), "ERROR: Approve from the zero address!");
        require(spender != address(0), "ERROR: Approve to the zero address!");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool)
    {
        if (allowances[sender][_msgSender()] != type(uint256).max)
            allowances[sender][_msgSender()] -= amount;

        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint amount) private returns (bool)
    {
        require(sender != address(0), "ERROR: Transfer from the zero address!");
        require(recipient != address(0), "ERROR: Transfer to the zero address!");
        require(!isCaughtMEV[recipient] && !isCaughtMEV[sender], "ERROR: Transfers are not permitted!");

        if (inSwapAndLiquify)
        {
            unchecked
            {
                require(amount <= balances[sender], "ERROR: Insufficient balance!");
                balances[sender] -= amount;
            }

            balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
            return true;
        }
        else
        {
            uint contractTokenBalance = balanceOf(address(this));
            if (!inSwapAndLiquify && swapAndLiquifyEnabled && !isMarketPair[sender] && contractTokenBalance >= swapThresholdMin)
            {
                if (swapAndLiquifyByLimitOnly)
                    contractTokenBalance = min(amount, min(contractTokenBalance, swapThresholdMax));

                swapAndLiquify(contractTokenBalance);
            }

            unchecked
            {
                require(amount <= balances[sender], "ERROR: Insufficient balance!");
                balances[sender] -= amount;
            }

            uint finalAmount = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, recipient, amount);
            balances[recipient] += finalAmount;

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function swapAndLiquify(uint amount) private lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, marketingAddress, block.timestamp)
        {
            emit SwapTokensForETH(amount, path);
        }
        catch
        {
            return;
        }
    }

    function takeFee(address sender, address recipient, uint amount) internal returns (uint)
    {
        uint feeAmount = 0;

        if (MEVMilk)
        {
            if (!isTrackerExempt[recipient])
                transferTime[recipient] = block.timestamp;

            if (!isTrackerExempt[sender])
            {
                if (transferTime[sender] == block.timestamp)
                {
                    if (milkLevel == 0)
                        revert("ERROR: You must wait 1 block between transfers!");
                    else
                    {
                        if (milkLevel == 2)
                            isCaughtMEV[sender] = true;

                        feeAmount = (amount * milkPenalty) / 10000;

                        balances[marketingAddress] += feeAmount;
                        emit Transfer(sender, marketingAddress, feeAmount);

                        return amount - feeAmount;
                    }
                }

                transferTime[sender] = block.timestamp;
            }
        }

        if (isMarketPair[sender])
            feeAmount = (amount * fees.inFee) / 10000;
        else if (isMarketPair[recipient])
            feeAmount = (amount * fees.outFee) / 10000;
        else
            feeAmount = (amount * fees.transferFee) / 10000;

        if (feeAmount > 0)
        {
            balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }

    function withdrawStuckNative(address recipient, uint amount) external onlyOwner()
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");
        payable(recipient).transfer(amount);
    }

    function withdrawForeignToken(address tokenAddress, address recipient, uint amount) external onlyOwner()
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");
        IERC20(tokenAddress).transfer(recipient, amount);
    }

    function min(uint a, uint b) private pure returns (uint)
    {
        return (a >= b) ? b : a;
    }

    receive() external payable {}
}