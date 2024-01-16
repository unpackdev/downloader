// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Tianlong is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router;

    mapping (address => uint) private _cooldown;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private _isBlacklisted;

    bool public tradingOpen;
    bool private _swapping;
    bool public swapEnabled = false;
    bool public cooldownEnabled = false;
    bool public feesEnabled = true;

    string private constant _name = "Tianlong";
    string private constant _symbol = "LONG";

    uint8 private constant _decimals = 18;

    uint256 private constant _totalSupply = 1e15 * (10**_decimals);

    uint256 public mxBuy = _totalSupply;
    uint256 public mxSell = _totalSupply;
    uint256 public mxWallet = _totalSupply;

    uint256 public oklgBlock = 0;
    uint256 private _blocksToBlacklist = 0;
    uint256 private _cdBlocks = 0;

    uint256 public constant FEE_DIVISOR = 1000;

    uint256 public buyFee = 60;
    uint256 private _previousBuyFee = buyFee;
    uint256 public sellFee = 60;
    uint256 private _previousSellFee = sellFee;

    uint256 private _tokensForFee;
    uint256 private _swapTokensAtAmount = 0;

    address payable private feeWalletAddress;
    address private _uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    constructor () {
        feeWalletAddress = payable(_msgSender());

        _balances[_msgSender()] = _totalSupply;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;

        emit Transfer(ZERO, _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != ZERO, "ERC20: Transfer from the zero address");
        require(to != ZERO, "ERC20: Transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");

        bool takeFee = true;
        bool shouldSwap = false;

        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {
            require(!_isBlacklisted[from] && !_isBlacklisted[to]);

            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "ERC20: Trading is not allowed yet");

            if (cooldownEnabled) {
                if (to != address(_uniswapV2Router) && to != address(_uniswapV2Pair)) {
                    require(_cooldown[tx.origin] < block.number - _cdBlocks && _cooldown[to] < block.number - _cdBlocks, "ERC20: Transfer delay enabled. Try again later.");
                    _cooldown[tx.origin] = block.number;
                    _cooldown[to] = block.number;
                }
            }

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= mxBuy, "ERC20: Transfer amount exceeds the mxBuy");
                require(balanceOf(to) + amount <= mxWallet, "ERC20: Exceeds maximum wallet token amount");
            }
            
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= mxSell, "ERC20: Transfer amount exceeds the mxSell.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled) takeFee = false;

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > _swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        
        if (contractBalance == 0 || _tokensForFee == 0) return;

        if (contractBalance > _swapTokensAtAmount * 5) contractBalance = _swapTokensAtAmount * 5;

        swapTokensForETH(contractBalance); 
        
        _tokensForFee = 0;
        
        (success,) = address(feeWalletAddress).call{value: address(this).balance}("");
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        feeWalletAddress.transfer(amount);
    }

    function isBlacklisted(address wallet) external view returns (bool) {
        return _isBlacklisted[wallet];
    }

    function removeAllFee() private {
        if (buyFee == 0 && sellFee == 0) return;

        _previousBuyFee = buyFee;
        _previousSellFee = sellFee;
        
        buyFee = 0;
        sellFee = 0;
    }
    
    function restoreAllFee() private {
        buyFee = _previousBuyFee;
        sellFee = _previousSellFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if (!takeFee) removeAllFee();
        else amount = _takeFees(sender, amount, isSell);

        _transferStandard(sender, recipient, amount);
        
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        if (oklgBlock + _blocksToBlacklist >= block.number) _totalFees = _getBotFees();
        else _totalFees = _getTotalFees(isSell);
        
        uint256 fees;
        if (_totalFees > 0) {
            fees = amount.mul(_totalFees).div(FEE_DIVISOR);
            _tokensForFee += fees * _totalFees / _totalFees;
        }
            
        if (fees > 0) _transferStandard(sender, address(this), fees);
            
        return amount -= fees;
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) return sellFee;
        return buyFee;
    }

    function _getBotFees() private pure returns(uint256) {
        return 899;
    }

    receive() external payable {}
    fallback() external payable {}

    function LAUNCH_oklg(uint256 blocks) public onlyOwner {
        require(!tradingOpen,"ERC20: Trading is already open");
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), _totalSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        mxBuy = _totalSupply.mul(1).div(100);
        mxSell = _totalSupply.mul(1).div(100);
        mxWallet = _totalSupply.mul(15).div(1000);
        _swapTokensAtAmount = _totalSupply.mul(1).div(1000);
        tradingOpen = true;
        oklgBlock = block.number;
        _blocksToBlacklist = blocks;
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
    }
    
    function CONFIG_CooldownEnabled(bool onoff) public onlyOwner {
        cooldownEnabled = onoff;
    }

    function CONFIG_SwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function CONFIG_FeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }    
    
    function CONFIG_MaxBuy(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(10000)), "ERC20: Max buy cannot be lower than 0.01% total supply");
        mxBuy = amount;
    }

    function CONFIG_MaxSell(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(10000)), "ERC20: Max sell cannot be lower than 0.01% total supply");
        mxSell = amount;
    }
    
    function CONFIG_MaxWallet(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(1000)), "ERC20: Max wallet cannot be lower than 0.1% total supply");
        mxWallet = amount;
    }
    
    function CONFIG_SwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(100000)), "ERC20: Swap amount cannot be lower than 0.001% total supply");
        require(amount <= (totalSupply().mul(5).div(1000)), "ERC20: Swap amount cannot be higher than 0.5% total supply");
        _swapTokensAtAmount = amount;
    }

    function CONFIG_OperationsWalletAddress(address opsWalletAddy) public onlyOwner {
        require(opsWalletAddy != ZERO, "ERC20: feeWalletAddress address cannot be 0");
        _isExcludedFromFees[feeWalletAddress] = false;
        _isExcludedMaxTransactionAmount[feeWalletAddress] = false;
        feeWalletAddress = payable(opsWalletAddy);
        _isExcludedFromFees[feeWalletAddress] = true;
        _isExcludedMaxTransactionAmount[feeWalletAddress] = true;
    }

    function CONFIG_BuyFee(uint256 newbuyFee) public onlyOwner {
        require(newbuyFee <= 100, "ERC20: Must keep buy taxes below 10%");
        buyFee = newbuyFee;
    }

    function CONFIG_SellFee(uint256 newsellFee) public onlyOwner {
        require(newsellFee <= 100, "ERC20: Must keep sell taxes below 10%");
        sellFee = newsellFee;
    }

    function CONFIG_CdBlocks(uint256 blocks) public onlyOwner {
        _cdBlocks = blocks;
    }

    function CONFIG_RemoveLimits() public onlyOwner {
        mxBuy = _totalSupply;
        mxSell = _totalSupply;
        mxWallet = _totalSupply;
        cooldownEnabled = false;
    }

    function AC_ExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = isEx;
    }
    
    function AC_ExcludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
    }
    
    function AC_Blacklist(address[] memory accounts, bool isBL) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isBlacklisted[accounts[i]] = isBL;
    }

    function UTILS_Unclog() public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized");
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }
    
    function UTILS_DistributeFees() public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized");
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function UTILS_RescueETH() public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized.");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function UTILS_RescueTokens(address tkn) public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized");
        require(tkn != address(this), "ERC20: Cannot withdraw this token");
        require(IERC20(tkn).balanceOf(address(this)) > 0, "ERC20: No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

}