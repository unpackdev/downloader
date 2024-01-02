// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IPool.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./Iinfl.sol";

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract OE is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    string private _name = "ODD/EVEN TOKEN";
    string private _symbol = "OE";
    uint8 private _decimals = 18;

    address payable public buybackAddress;
    address payable public soFiPoolAddress;
    address payable public housePoolAddress;
    Iinfl public marketingWalletAddress;
    IPool public prizePoolAddress;
    IUniswapV2Router02 public _uniswapV2Router;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public usdtAddress;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;

    //Contract fees
    uint256 public _buyPrizeFee = 15;
    uint256 public _sellPrizeFee = 15;

    uint256 public _buyLpFee = 2;
    uint256 public _sellLpFee = 2;

    uint256 public _buyBuyBackFee = 2;
    uint256 public _sellBuyBackFee = 2;

    uint256 public _buyMarketingFee = 2;
    uint256 public _sellMarketingFee = 2;

    uint256 public _buySofiFee = 2;
    uint256 public _sellSofiFee = 2;

    uint256 public _buyHouseFee = 2;
    uint256 public _sellHouseFee = 2;

    //Contract share parameters
    uint256 public _prizeShare = 15;
    uint256 public _lpShare = 2;
    uint256 public _buyBackShare = 2;
    uint256 public _marketingShare = 2;
    uint256 public _sofiShare = 2;
    uint256 public _houseShare = 2;

    uint256 public _totalTaxIfBuying = 25;
    uint256 public _totalTaxIfSelling = 25;
    uint256 public _totalDistributionShares = 25;

    uint256 private _totalSupply = 111_111 * 10**_decimals;
    uint256 public _maxTxAmount = 111_111 * 10**_decimals;
    uint256 public _walletMax = 111_111 * 10**_decimals;
    uint256 private minimumTokensBeforeSwap = 1_111 * 10**_decimals;

    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (
        address _router,
        address _prizePool,
        address _buyBack,
        address _marketing,
        address _sofi,
        address _house,
        address _usdt
    ) {

        _uniswapV2Router = IUniswapV2Router02(_router);
        prizePoolAddress = IPool(_prizePool);
        buybackAddress = payable(_buyBack);
        marketingWalletAddress = Iinfl(_marketing);
        soFiPoolAddress = payable(_sofi);
        housePoolAddress = payable(_house);
        usdtAddress = _usdt;

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_buyBack] = true;
        isExcludedFromFee[_marketing] = true;

        _totalTaxIfBuying = _buyPrizeFee + _buyBuyBackFee + _buyLpFee + _buyMarketingFee + _buySofiFee + _buyHouseFee;
        _totalTaxIfSelling = _sellPrizeFee + _sellLpFee + _sellBuyBackFee + _sellMarketingFee + _sellSofiFee + _sellHouseFee;
        _totalDistributionShares = _marketingShare + _prizeShare + _lpShare + _buyBackShare + _sofiShare + _houseShare;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function setDistributionShares(
        uint256 prizeShare,
        uint256 lpShare,
        uint256 buyBackShare,
        uint256 marketingShare,
        uint256 sofiShare,
        uint256 houseShare
    ) external onlyOwner {
        _marketingShare = marketingShare;
        _prizeShare = prizeShare;
        _lpShare = lpShare;
        _buyBackShare = buyBackShare;
        _sofiShare = sofiShare;
        _houseShare = houseShare;

        _totalDistributionShares = _marketingShare + _prizeShare + _lpShare + _buyBackShare + _sofiShare + _houseShare;
    }

    function setBuyTaxes(
        uint256 newMarketingTax,
        uint256 newLpPercent,
        uint256 newBuyBackPercent,
        uint256 newPrizePercent,
        uint256 newSofiPercent,
        uint256 newHousePercent
    ) external onlyOwner {
        _buyMarketingFee = newMarketingTax;
        _buyLpFee = newLpPercent;
        _buyBuyBackFee = newBuyBackPercent;
        _buyPrizeFee = newPrizePercent;
        _buySofiFee = newSofiPercent;
        _buyHouseFee = newHousePercent;

        _totalTaxIfBuying = _buyPrizeFee + _buyBuyBackFee + _buyLpFee + _buyMarketingFee + _buySofiFee + _buyHouseFee;
        require(_totalTaxIfBuying <= 25, 'Error fee too high');
    }

    function setSellTaxes(
        uint256 newMarketingTax,
        uint256 newLpPercent,
        uint256 newBuyBackPercent,
        uint256 newPrizePercent,
        uint256 newSofiPercent,
        uint256 newHousePercent
    ) external onlyOwner {
        _sellMarketingFee = newMarketingTax;
        _sellBuyBackFee = newBuyBackPercent;
        _sellLpFee = newLpPercent;
        _sellPrizeFee = newPrizePercent;
        _sellSofiFee = newSofiPercent;
        _sellHouseFee = newHousePercent;

        _totalTaxIfSelling = _sellPrizeFee + _sellLpFee + _sellBuyBackFee + _sellMarketingFee + _sellSofiFee + _sellHouseFee;
        require(_totalTaxIfSelling <= 25, 'Error fee to high');
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        require(maxTxAmount >= 2_500_000, 'Min maxTxAmount error');
        _maxTxAmount = maxTxAmount;
    }

    function enableDisableWalletLimit(bool newValue) external onlyOwner {
        checkWalletLimit = newValue;
    }

    function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax  = newLimit;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMarketingWalletAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), 'newAddress must not be equal to 0x');
        marketingWalletAddress = Iinfl(newAddress);
    }

    function setSofiPoolWalletAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), 'newAddress must not be equal to 0x');
        soFiPoolAddress = payable(newAddress);
    }

    function setBuybackAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), 'newAddress must not be equal to 0x');
        buybackAddress = payable(newAddress);
    }

    function setHouseWalletAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), 'newAddress must not be equal to 0x');
        housePoolAddress = payable(newAddress);
    }

    function setPrizePoolAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), 'newAddress must not be equal to 0x');
        prizePoolAddress = IPool(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        _uniswapV2Router = IUniswapV2Router02(newRouterAddress);

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; //Set new pair address

        isWalletLimitExempt[address(uniswapPair)] = true;
        isMarketPair[address(uniswapPair)] = true;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inSwapAndLiquify)
        {
            return _basicTransfer(sender, recipient, amount);
        }
        else
        {
            uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ?
            amount : takeFee(sender, recipient, amount);

            if (sender != buybackAddress && recipient != buybackAddress) {
                if (isMarketPair[sender] && recipient != address(this)) {
                    prizePoolAddress.addBuyer(recipient, finalAmount, _getIsOdd());
                }

                if (isMarketPair[recipient] && sender != address(this) && sender != owner()) {
                    prizePoolAddress.updateBuyer(sender, amount, _getIsOdd());
                }

                if (!isMarketPair[sender] && !isMarketPair[recipient]) {
                    prizePoolAddress.deleteBuyer(sender);
                }
            }

            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled)
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(checkWalletLimit && !isWalletLimitExempt[recipient])
                require(balanceOf(recipient).add(finalAmount) <= _walletMax);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(_lpShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = _totalDistributionShares.sub(_lpShare.div(2));

        uint256 amountETHLiquidity = amountReceived.mul(_lpShare).div(totalETHFee).div(2);
        uint256 amountETHPool = amountReceived.mul(_prizeShare).div(totalETHFee);
        uint256 amountETHBuyback = amountReceived.mul(_buyBackShare).div(totalETHFee);
        uint256 amountETHSofi = amountReceived.mul(_sofiShare).div(totalETHFee);
        uint256 amountETHHouse = amountReceived.mul(_houseShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived - amountETHLiquidity - amountETHPool - amountETHBuyback - amountETHSofi - amountETHHouse;

        if(amountETHMarketing > 0)
            marketingWalletAddress.addPayment{value: amountETHMarketing}();

        if(amountETHBuyback > 0)
            transferToAddressETH(payable(address(buybackAddress)), amountETHBuyback);

        if(amountETHSofi > 0) {
            transferToAddressETH(soFiPoolAddress, amountETHSofi);
        }

        if(amountETHHouse > 0) {
            transferToAddressETH(housePoolAddress, amountETHHouse);
        }

        if(amountETHPool > 0)
            transferToAddressETH(payable(address(prizePoolAddress)), amountETHPool);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = 0;

        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function getUsdtEthPrice() external view returns(uint256) {
        return _getUsdtEthPrice();
    }

    function getPrice() external view returns(uint256) {
        return _getPrice();
    }

    function _getUsdtEthPrice() internal view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_getUsdtPair());
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if (token0 == usdtAddress) {
            return uint256(reserve0 * (10**30) / reserve1);
        } else {
            return uint256(reserve1 * (10**30) / reserve0);
        }
    }

    function getIsOdd() external view returns(bool) {
        return _getIsOdd();
    }

    function _getIsOdd() internal view returns(bool) {
        uint reminder = _getTokenPriceInUsd() % 2;
        if(reminder == 0)
            return false;
        else
            return true;
    }

    function getTokenPriceInUsd() external view returns(uint256) {
        return _getTokenPriceInUsd();
    }

    function _getTokenPriceInUsd() internal view returns(uint256) {
        return (_getPrice() * _getUsdtEthPrice()) / 10**30;
    }

    function _getUsdtPair() internal view returns(address) {
        return IUniswapV2Factory(_uniswapV2Router.factory()).getPair(usdtAddress, _uniswapV2Router.WETH());
    }

    function _getPrice() internal view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if (token0 == address(this)) {
            return uint256(reserve1 * 1 ether / reserve0);
        } else {
            return uint256(reserve0 * 1 ether / reserve1);
        }
    }
}