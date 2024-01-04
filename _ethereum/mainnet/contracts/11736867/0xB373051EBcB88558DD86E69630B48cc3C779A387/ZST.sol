// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./Constants.sol";
import "./Setters.sol";

contract ZStable is Setters, Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    modifier taxlessTx {
        _taxLess = true;
        _;
        _taxLess = false;
    }

    constructor () public {
        // uniswapRouterV2 = IUniswapV2Router02(Constants.getRouterAdd());
        // uniswapFactory = IUniswapV2Factory(Constants.getFactoryAdd());
        updateEpoch();
        initializeLargeTotal();
        _totalSupply = 10**5 * 10**9;
        uint256 currentFactor = getFactor();
        _largeBalances[_msgSender()] = _largeBalances[_msgSender()].add(_totalSupply.mul(currentFactor));
        emit Transfer(address(0),_msgSender(),_totalSupply);
    }

    function name() public view returns (string memory) {
        return Constants.getName();
    }
    
    function symbol() public view returns (string memory) {
        return Constants.getSymbol();
    }
    
    function decimals() public view returns (uint8) {
        return Constants.getDecimals();
    }
    
    function totalSupply() public view override returns (uint256) {
        return getTotalSupply();
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        uint256 currentFactor = getFactor();
        return getLargeBalances(account).div(currentFactor);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return getAllowances(owner,spender);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), getAllowances(sender,_msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        setAllowances(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balanceOf(sender),"Amount exceeds balance");
        require(isPresaleDone(),"Presale yet to close");
        if (now > getCurrentEpoch().add(Constants.getEpochLength())) updateEpoch();
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amount.mul(currentFactor);
        uint256 txType;
        if (isTaxLess()) {
            txType = 3;
        } else {
            bool lpBurn;
            if (isSupportedPool(sender)) {
                lpBurn = syncPair(sender);
            } else if (isSupportedPool(recipient)){
                silentSyncPair(recipient);
            } else {
                silentSyncPair(_mainPool);
            }
            txType = _getTxType(sender, recipient, lpBurn);
        }
        // Buy Transaction from supported pools - requires mint, no utility fee
        if (txType == 1) {
            uint256 totalMint = getMintValue(sender, amount);
            // uint256 mintSize = amount.div(100);
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            _totalSupply = _totalSupply.add(totalMint);
            emit Transfer(sender, recipient, amount);
        }
        // Sells to supported pools or unsupported transfer - requires exit burn and utility fee
        else if (txType == 2) {
            (uint256 burnSize, uint256 largeBurnSize) = getBurnValues(recipient, amount);
            uint256 actualTransferAmount = amount.sub(burnSize);
            uint256 largeTransferAmount = actualTransferAmount.mul(currentFactor);
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeTransferAmount);
            _totalSupply = _totalSupply.sub(burnSize);
            _largeTotal = _largeTotal.sub(largeBurnSize);
            emit Transfer(sender, recipient, actualTransferAmount);
            emit Transfer(sender, address(0), burnSize);
        } 
        // Add Liquidity via interface or Remove Liquidity Transaction to supported pools - no fee of any sort
        else if (txType == 3) {
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _getTxType(address sender, address recipient, bool lpBurn) private returns(uint256) {
        uint256 txType = 2;
        if (isSupportedPool(sender)) {
            if (lpBurn) {
                txType = 3;
            } else {
                txType = 1;
            }
        } else if (sender == Constants.getRouterAdd()) {
            txType = 3;
        }
        return txType;
    }

    function setPresaleDone() public onlyOwner() {
        require(totalSupply() <= Constants.getLaunchSupply(), "Total supply is already minted");
        _mintRemaining();
        _presaleDone = true;
        _createEthPool();
    }

    function mintPresale(address[] memory presalers, uint256[] memory amounts, uint256 length) external onlyOwner() {
        require(!isPresaleDone(),"Presale is done");
        uint256 currentFactor = getFactor();
        for(uint256 i=0; i<length; i++) {
            uint256 largeAmount = amounts[i].mul(currentFactor);
            _largeBalances[owner()] = _largeBalances[owner()].sub(largeAmount);
            _largeBalances[presalers[i]] = _largeBalances[presalers[i]].add(largeAmount);
            emit Transfer(owner(), presalers[i], amounts[i]);
        }
    }

    function _mintRemaining() private {
        require(!isPresaleDone(), "Cannot mint post presale");
        addToAccount(address(this),80000 * 10 ** 9);
        addToAccount(owner(),20000 * 10 ** 9);
        emit Transfer(address(0),address(this),80000 * 10 ** 9);
    }

    function _createEthPool() private taxlessTx {
        IUniswapV2Router02 uniswapRouterV2 = getUniswapRouter();
        IUniswapV2Factory uniswapFactory = getUniswapFactory();
        address tokenUniswapPair;
        if (uniswapFactory.getPair(address(uniswapRouterV2.WETH()), address(this)) == address(0)) {
            tokenUniswapPair = uniswapFactory.createPair(
            address(uniswapRouterV2.WETH()), address(this));
        } else {
            tokenUniswapPair = uniswapFactory.getPair(address(this),uniswapRouterV2.WETH());
        }
        _approve(address(this), 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 8 * 10**4 * 10**9);
        uniswapRouterV2.addLiquidityETH{value: address(this).balance}(address(this),
            8 * 10**4 * 10**9, 0, 0, address(this), block.timestamp);
        addSupportedPool(tokenUniswapPair, address(uniswapRouterV2.WETH()));
        _mainPool = tokenUniswapPair;
    }

    function createTokenPool(address pairToken, uint256 amount) external onlyOwner() taxlessTx {
        IUniswapV2Router02 uniswapRouterV2 = getUniswapRouter();
        IUniswapV2Factory uniswapFactory = getUniswapFactory();
        address tokenUniswapPair;
        if (uniswapFactory.getPair(pairToken, address(this)) == address(0)) {
            tokenUniswapPair = uniswapFactory.createPair(
            pairToken, address(this));
        } else {
            tokenUniswapPair = uniswapFactory.getPair(pairToken,address(this));
        }
        require(uniswapFactory.getPair(pairToken,address(uniswapRouterV2.WETH())) != address(0), "Eth pairing does not exist");
        require(balanceOf(address(this)) >= amount, "Amount exceeds the token balance");
        uint256 toConvert = amount.div(2);
        uint256 toAdd = amount.sub(toConvert);
        uint256 initialBalance = IERC20(pairToken).balanceOf(address(this));
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();
        path[2] = pairToken;
        _approve(address(this), address(uniswapRouterV2), toConvert);
        uniswapRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            toConvert, 0, path, address(this), block.timestamp);
        uint256 newBalance = IERC20(pairToken).balanceOf(address(this)).sub(initialBalance);
        _approve(address(this), address(uniswapRouterV2), toAdd);
        IERC20(pairToken).approve(address(uniswapRouterV2), newBalance);
        uniswapRouterV2.addLiquidity(address(this),pairToken,toAdd,newBalance,0,0,address(this),block.timestamp);
        addSupportedPool(tokenUniswapPair, pairToken);
    }

    function addNewSupportedPool(address pool, address pairToken) external onlyOwner() {
        addSupportedPool(pool, pairToken);
    }

    function removeOldSupportedPool(address pool) external onlyOwner() {
        removeSupportedPool(pool);
    }

    receive() external payable {

    }

}