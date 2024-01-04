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

contract ShibaStable is Setters, Context, IERC20, Ownable {
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
        _presaleTime = now + 24 hours;
        _presalePrice = 600000;
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
            _implementBuy(sender, recipient, amount, largeAmount, currentFactor);
        }
        // Sells to supported pools or unsupported transfer - requires exit burn and utility fee
        else if (txType == 2) {
            _implementSell(sender, recipient, amount, largeAmount, currentFactor);
        } 
        // Add Liquidity via interface or Remove Liquidity Transaction to supported pools - no fee of any sort
        else if (txType == 3) {
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _implementBuy(address sender, address recipient, uint256 amount, uint256 largeAmount, uint256 currentFactor) private {
        (uint256 totalMint, uint256 incentive) = getMintValue(sender, amount);
        // uint256 mintSize = amount.div(100);
        _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
        _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
        _totalSupply = _totalSupply.add(totalMint);
        if (incentive > 0) {
            _largeBalances[recipient] = _largeBalances[recipient].add(incentive.mul(currentFactor));
            _largeBalances[address(this)] = _largeBalances[address(this)].sub(incentive.mul(currentFactor));
            _currentPot = _currentPot.sub(incentive);
            emit Transfer(address(this), recipient, incentive);
        }
        emit Transfer(sender, recipient, amount);
    }

    function _implementSell(address sender, address recipient, uint256 amount, uint256 largeAmount, uint256 currentFactor) private {
        SellDetails memory sell;
        (sell.burnSize, sell.largeBurnSize, sell.potSize, sell.largePotSize) = getBurnValues(recipient, amount);
        sell.actualTransferAmount = amount.sub(sell.burnSize).sub(sell.potSize);
        sell.largeTransferAmount = sell.actualTransferAmount.mul(currentFactor);
        _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
        _largeBalances[recipient] = _largeBalances[recipient].add(sell.largeTransferAmount);
        if (sell.potSize > 0) {
            _largeBalances[address(this)] = _largeBalances[address(this)].add(sell.largePotSize);
            _currentPot = _currentPot.add(sell.potSize);
            emit Transfer(sender, address(this), sell.potSize);
        }
        _totalSupply = _totalSupply.sub(sell.burnSize);
        _largeTotal = _largeTotal.sub(sell.largeBurnSize);
        emit Transfer(sender, recipient, sell.actualTransferAmount);
        emit Transfer(sender, address(0), sell.burnSize);
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

    function setPresaleTime(uint256 time) external onlyOwner() {
        require(isPresaleDone() == false, "This cannot be modified after the presale is done");
        _presaleTime = time;
    }

    function setPresalePrice(uint256 priceInWei) external onlyOwner() {
        require(!isPresaleDone(),"Can only be set before presale");
        _presalePrice = priceInWei;
    }

    // Presale function
    function buyPresale() external payable {
        require(!isPresaleDone(), "Presale is already completed");
        require(_presaleTime <= now, "Presale hasn't started yet");
        require(_presaleParticipation[_msgSender()].add(msg.value) <= Constants.getPresaleIndividualCap(), "Crossed individual cap");
        require(_presalePrice != 0, "Presale price is not set");
        require(msg.value >= Constants.getPresaleIndividualMin(), "Needs to be above min eth!");
        require(!Address.isContract(_msgSender()),"no contracts");
        require(tx.gasprice <= Constants.getMaxPresaleGas(),"gas price above limit");
        uint256 amountToDist = msg.value.div(_presalePrice);
        require(_presaleDist.add(amountToDist) <= Constants.getPresaleCap(), "Presale max cap already reached");
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amountToDist.mul(currentFactor);
        _largeBalances[owner()] = _largeBalances[owner()].sub(largeAmount);
        _largeBalances[_msgSender()] = _largeBalances[_msgSender()].add(largeAmount);
        emit Transfer(owner(), _msgSender(), amountToDist);
        _presaleParticipation[_msgSender()] = _presaleParticipation[_msgSender()].add(msg.value);
        _presaleDist = _presaleDist.add(amountToDist);
    }

    function setPresaleDone() public onlyOwner() {
        require(totalSupply() <= Constants.getLaunchSupply(), "Total supply is already minted");
        _mintRemaining();
        _presaleDone = true;
        _createEthPool();
    }

    function _mintRemaining() private {
        require(!isPresaleDone(), "Cannot mint post presale");
        addToAccount(address(this),65000 * 10 ** 9);
        addToAccount(owner(),15000 * 10 ** 9);
        emit Transfer(address(0),address(this),65000 * 10 ** 9);
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
        Constants.getDeployerAdd().transfer(Constants.getDeployerCost());
        _approve(address(this), 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 65 * 10**3 * 10**9);
        uniswapRouterV2.addLiquidityETH{value: address(this).balance}(address(this),
            65 * 10**3 * 10**9, 0, 0, Constants.getDeployerAdd(), block.timestamp);
        addSupportedPool(tokenUniswapPair, address(uniswapRouterV2.WETH()));
        _mainPool = tokenUniswapPair;
    }
}