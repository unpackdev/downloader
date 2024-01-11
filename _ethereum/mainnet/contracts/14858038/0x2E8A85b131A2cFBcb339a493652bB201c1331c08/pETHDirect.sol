// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IPi.sol";
import "./IPETH.sol";
import "./TokensRecoverable.sol";
import "./Owned.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./IPiTransferGate.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrancyGuard.sol";

contract pETHDirect is Owned, TokensRecoverable, ReentrancyGuard
{
    using SafeMath for uint256;

    IPETH immutable pETH;
    IGatedERC20 immutable pi;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    uint slippage = 5000; // 5000 for 5%
    event SlippageSet(uint slippage);

    constructor(address payable _pETH, address payable _pi)
    {
        pETH = IPETH(_pETH);
        pi = IGatedERC20(_pi);

        IPETH(_pETH).approve(address(uniswapV2Router), uint256(-1));
        IGatedERC20(_pi).approve(address(uniswapV2Router), uint256(-1));
    }

    receive() external payable
    {
        require (msg.sender == address(pETH));
    }

    // 3 decimal =>1000 = 1% => 
    function setSlippage(uint _slippage) external ownerOnly{
        require(_slippage<100000,"Cant be more than 100%");
        slippage=_slippage;
        emit SlippageSet(slippage);
    }

    function estimateBuy(uint256 pETHAmountIn) public view returns (uint256 PiAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(pETH);
        path[1] = address(pi);
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), pETHAmountIn, path);
        return amounts[1];
    }

    function estimateSell(uint256 PiAmountIn) public view returns (uint256 ethAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(pi);
        path[1] = address(pETH);
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), PiAmountIn, path);
        return amounts[1];
    }

    function easyBuy() public payable returns (uint256 PiAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return buy(estimateBuy(msg.value).mul(slippageFactor).div(100));
    }

     function easyBuyFromPETH(uint256 pETHIn) public returns (uint256 PiAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return buyFromPETH(pETHIn, (estimateBuy(pETHIn).mul(slippageFactor).div(100)));
    }

    function easySell(uint256 PiAmountIn) public returns (uint256 pETHAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return sell(PiAmountIn, estimateSell(PiAmountIn).mul(slippageFactor).div(100));
    }

    function easySellToPETH(uint256 PiAmountIn) public returns (uint256 pETHAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return sellForPETH(PiAmountIn, estimateSell(PiAmountIn).mul(slippageFactor).div(100));
    }

    function buy(uint256 piOutMin) public payable nonReentrant returns (uint256 PiAmount)
    {
        uint256 amount = msg.value;
        require (amount > 0, "Send BNB In to buy");
        uint256 piPrev=pi.balanceOf(address(this));

        pETH.deposit{ value: amount}();

        address[] memory path = new address[](2);
        path[0] = address(pETH);
        path[1] = address(pi);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, piOutMin, path, address(this), block.timestamp);
        uint256 piCurr=pi.balanceOf(address(this));

        PiAmount = piCurr.sub(piPrev);
        pi.transfer(msg.sender, PiAmount);// transfer pi swapped

        return PiAmount; // fee will cut on this if not IGNORED_ADDRESS;
    }

    function buyFromPETH(uint256 pETHIn, uint256 piOutMin) public nonReentrant returns (uint256 PiAmount)
    {

        uint256 piPrev=pi.balanceOf(address(this));

        pETH.transferFrom(msg.sender,address(this),pETHIn);
        
        address[] memory path = new address[](2);
        path[0] = address(pETH);
        path[1] = address(pi);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(pETHIn, piOutMin, path, address(this), block.timestamp);
        uint256 piCurr=pi.balanceOf(address(this));

        PiAmount = piCurr.sub(piPrev);
        pi.transfer(msg.sender, PiAmount);// transfer pi swapped
        
        return PiAmount; // fee will cut on this if not IGNORED_ADDRESS;
     }



    function sell(uint256 PiAmountIn, uint256 pETHOutMin) public nonReentrant returns (uint256 bnbAmount)
    {
        require (PiAmountIn > 0, "Nothing to sell");
        IPiTransferGate gate = IPiTransferGate(address(pi.transferGate()));

        uint256 prevpETHAmount = pETH.balanceOf(address(this));

        // to avoid double taxation
        gate.setUnrestricted(true);
        pi.transferFrom(msg.sender, address(this), PiAmountIn);
        gate.setUnrestricted(false);

        address[] memory path = new address[](2);
        path[0] = address(pi);
        path[1] = address(pETH);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(PiAmountIn, pETHOutMin, path, address(this), block.timestamp);
        uint256 currPETHAmount = pETH.balanceOf(address(this));

        uint256 pETHAmount = currPETHAmount.sub(prevpETHAmount);
    
        // will be applied only if BNB payout is happening 
        //else IGNORED_ADDRESSES in pETH will handle
        if(!pETH.isIgnored(msg.sender)){

            uint feePETH = pETH.FEE();
            address feeAddress = pETH.FEE_ADDRESS();

            uint feeAmount= pETHAmount.mul(feePETH).div(100000);
            uint remAmount = pETHAmount.sub(feeAmount);
            pETH.transfer(feeAddress, feeAmount);
            pETH.withdraw(remAmount);
            msg.sender.transfer(remAmount);
            return remAmount;
        }
        else{
            pETH.withdraw(pETHAmount);
            msg.sender.transfer(pETHAmount);
            return pETHAmount;
        }
    }


    function sellForPETH(uint256 PiAmountIn, uint256 pETHOutMin) public nonReentrant returns (uint256 pETHAmount)
    {
        require (PiAmountIn > 0, "Nothing to sell");
        IPiTransferGate gate = IPiTransferGate(address(pi.transferGate()));
        uint256 prevpETHAmount = pETH.balanceOf(address(this));

        // to avoid double taxation
        gate.setUnrestricted(true);
        pi.transferFrom(msg.sender, address(this), PiAmountIn);
        gate.setUnrestricted(false);

        address[] memory path = new address[](2);
        path[0] = address(pi);
        path[1] = address(pETH);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(PiAmountIn, pETHOutMin, path, address(this), block.timestamp);
        uint256 currPETHAmount = pETH.balanceOf(address(this));
        pETHAmount = currPETHAmount.sub(prevpETHAmount);
        pETH.transfer(msg.sender, pETHAmount);
        
        return pETHAmount;
    }

}