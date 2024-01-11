// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IPi.sol";
import "./IPETH.sol";
import "./TokensRecoverable.sol";
import "./Owned.sol";
import "./IUniswapV2Factory.sol";
import "./IPiTransferGate.sol";
import "./IUniswapV2Router02.sol";
import "./IERC31337.sol";
import "./IpETH_Direct.sol";
import "./ReentrancyGuard.sol";
import "./IVault.sol";
import "./IERC1155Pi.sol";
import "./IEventGate.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";


contract CircleDirect is Owned, TokensRecoverable, ReentrancyGuard 
{
    using SafeMath for uint256;
    IPETH public immutable pETH;
    IPi public immutable pi;
    IpETH_Direct public immutable pETHDirect;
    IPiTransferGate public immutable transferGate; 
    IERC31337 public immutable CircleNFT;
    IVault vaultContract;
    IERC1155 ERC1155Token;

    address public LPAddress;

    uint256 sCircleTokenId = 1;
    uint256 eCircleTokenId = 2;
    
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    event SlippageSet(uint slippage);

    constructor(IPETH _pETH, IPi _pi, IpETH_Direct _pETH_Direct, IPiTransferGate _transferGate, IERC31337 _pETH_Liquidity, IVault _vaultContract, IERC1155 _ERC1155Token)
    {
        pETH = _pETH;
        pETHDirect = _pETH_Direct;
        transferGate = _transferGate;
        CircleNFT = _pETH_Liquidity;
        pi = _pi;
        vaultContract = _vaultContract;
        ERC1155Token = _ERC1155Token;

        LPAddress = uniswapV2Factory.getPair(address(_pETH), address(_pi));

        _pETH.approve(address(_pETH_Direct), uint256(-1));
        _pi.approve(address(_pETH_Direct), uint256(-1));

        _pETH.approve(address(_transferGate), uint256(-1));
        _pi.approve(address(_transferGate), uint256(-1));

        _pETH.approve(address(uniswapV2Router), uint256(-1));
        _pi.approve(address(uniswapV2Router), uint256(-1));
 
        IERC20(LPAddress).approve(address(uniswapV2Router), uint256(-1));

        _ERC1155Token.setApprovalForAll(address(_vaultContract),true);

    }

    receive() external payable
    {
        require (msg.sender == address(pETH));
    }
   
   
     function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external  returns(bytes4){
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external  returns(bytes4){
        return 0xbc197c81;
    }     

    function estimateBuyLPFromBNB(uint256 _bnb_amount) external view returns(uint256){
        uint256 bnbToBuy = _bnb_amount.div(2);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(LPAddress).getReserves(); 
        uint256 piAmount = pETHDirect.estimateBuy(bnbToBuy);
        uint256 amt1 = piAmount.mul(IUniswapV2Pair(LPAddress).totalSupply()).div(reserve0.add(piAmount));
        uint256 amt2 = bnbToBuy.mul(IUniswapV2Pair(LPAddress).totalSupply()).div(reserve1.sub(bnbToBuy));

        if(amt1>amt2) return amt2;
        else return amt1;
    }

    function estimateBuyLPFromPi(uint256 _pi_amount) external view returns(uint256){
        uint256 piToBuy = _pi_amount.div(2);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(LPAddress).getReserves(); 
        uint256 bnbAmount = pETHDirect.estimateSell(piToBuy);
        uint256 amt1 = piToBuy.mul(IUniswapV2Pair(LPAddress).totalSupply()).div(reserve0.sub(piToBuy));
        uint256 amt2 = bnbAmount.mul(IUniswapV2Pair(LPAddress).totalSupply()).div(reserve1.add(bnbAmount));
        if(amt1>amt2) return amt2;
        else return amt1;
    }

    //  BNB => CircleNFT via LP
    function easyBuySmallCircle() external payable nonReentrant
    {
        uint256 prevpiAmount = pi.balanceOf(address(this));
        uint256 prevCircleNFTAmount = ERC1155Token.balanceOf(address(this), sCircleTokenId);

        uint256 tBNB=SafeMath.div(msg.value,2);
        pETH.deposit{ value: tBNB }();

        uint256 piAmt = pETHDirect.easyBuy{ value: tBNB }();
        address LPaddress = uniswapV2Factory.getPair(address(pi), address(pETH));

        uint256 prevLPBalance = IERC20(LPaddress).balanceOf(address(this));

        (, ,  uint256 LPtokens) =transferGate.safeAddLiquidity(uniswapV2Router, pETH, tBNB, piAmt);
 
        
        IERC20(LPaddress).approve(address(CircleNFT),LPtokens);


        CircleNFT.depositTokens(LPaddress, LPtokens);
    
        uint256 currCircleNFTAmount = ERC1155Token.balanceOf(address(this), sCircleTokenId);
        
        require(currCircleNFTAmount.sub(prevCircleNFTAmount)>0,"NFT mints should be more than 1");
        ERC1155Token.safeTransferFrom(address(this), msg.sender, sCircleTokenId, currCircleNFTAmount.sub(prevCircleNFTAmount), "0x");

        // any residue sent back to buyer/seller
        uint256 currLPBalance = IERC20(LPaddress).balanceOf(address(this));
        if(currLPBalance>prevLPBalance)
            IERC20(LPaddress).transfer(msg.sender, currLPBalance.sub(prevLPBalance));

        uint256 currpiAmount = pi.balanceOf(address(this)); 
        if(currpiAmount>prevpiAmount)
            pi.transfer(msg.sender,currpiAmount.sub(prevpiAmount));
    }

    //  sCircle => eCircle
    function buyBigCircle(uint256 sCircleValue) external nonReentrant
    {
        ERC1155Token.safeTransferFrom( msg.sender, address(this), sCircleTokenId, sCircleValue, "0x");        
        uint256 mints = vaultContract.depositSmallCircle(sCircleValue);        
        ERC1155Token.safeTransferFrom(address(this), msg.sender, eCircleTokenId, mints, "0x");
    }

    // sCircle => LPs
    function sellSmallCircleToLP(address _LPToken, uint256 sCircleValue) external{
        ERC1155Token.safeTransferFrom( msg.sender, address(this), sCircleTokenId, sCircleValue, "0x");        
        uint256 claimed = vaultContract.sellSmallCircle(_LPToken, sCircleValue);
        address LPaddress = uniswapV2Factory.getPair(address(pi), address(pETH));
        IERC20(LPaddress).transfer(msg.sender, claimed);
    }


    //  pETH => small Circle
    function easyBuyFromPETH(uint256 pETHAmt) public nonReentrant returns (uint256)
    {

        uint256 prevPETHAmount = pETH.balanceOf(address(this));
        uint256 prevpiAmount = pi.balanceOf(address(this));

        pETH.transferFrom(msg.sender,address(this),pETHAmt);

        //swap half pETH to pi    
        uint256 pETHForBuy = pETHAmt.div(2);

        uint256 piAmt = pETHDirect.easyBuyFromPETH(pETHForBuy);

        address LPaddress = uniswapV2Factory.getPair(address(pi), address(pETH));
        uint256 prevLPBalance = IERC20(LPaddress).balanceOf(address(this));

        (, ,  uint256 LPtokens) =transferGate.safeAddLiquidity(uniswapV2Router, IERC20(pETH), pETHForBuy, piAmt);

        
        IERC20(LPaddress).approve(address(CircleNFT),LPtokens);

        uint256 mints = CircleNFT.depositTokens(LPaddress, LPtokens);

        ERC1155Token.safeTransferFrom(address(this), msg.sender, sCircleTokenId, mints, "0x");

        // any residue sent back to buyer/seller
        uint256 currpiAmount = pi.balanceOf(address(this)); 
        uint256 currPETHAmount = pETH.balanceOf(address(this));
        uint256 currLPBalance = IERC20(LPaddress).balanceOf(address(this));

        if(currLPBalance>prevLPBalance)
            IERC20(LPaddress).transfer(msg.sender, currLPBalance.sub(prevLPBalance));

        if(currpiAmount>prevpiAmount)
            pi.transfer(msg.sender,currpiAmount.sub(prevpiAmount));

        if(currPETHAmount>prevPETHAmount)
            pETH.transfer(msg.sender,currPETHAmount.sub(prevPETHAmount));

        return mints;
  
    }

    //  pi => small Circle
    function easyBuyFromPi(uint256 piAmt) external nonReentrant
    {
        uint256 prevpETHAmount = pETH.balanceOf(address(this));
        uint256 prevpiAmount = pi.balanceOf(address(this));

        pi.transferFrom(msg.sender,address(this),piAmt);
        
        //swap half pETH to pi    
        uint256 piForBuy = piAmt.div(2);

        uint256 pETHAmt = pETHDirect.easySellToPETH(piForBuy);

        address LPaddress = uniswapV2Factory.getPair(address(pi), address(pETH));
        uint256 prevLPBalance = IERC20(LPaddress).balanceOf(address(this));

        (, ,  uint256 LPtokens) =transferGate.safeAddLiquidity(uniswapV2Router, IERC20(pETH), pETHAmt, piForBuy);

        
        IERC20(LPaddress).approve(address(CircleNFT),LPtokens);

        uint256 mints = CircleNFT.depositTokens(LPaddress, LPtokens);
        
        ERC1155Token.safeTransferFrom(address(this), msg.sender, sCircleTokenId, mints, "0x");

        // any residue sent back to buyer/seller
        uint256 currpETHAmount = pETH.balanceOf(address(this));
        uint256 currpiAmount = pi.balanceOf(address(this)); 
        uint256 currLPBalance = IERC20(LPaddress).balanceOf(address(this));

        if(currLPBalance>prevLPBalance)
            IERC20(LPaddress).transfer(msg.sender, currLPBalance.sub(prevLPBalance));

        if(currpiAmount>prevpiAmount)
            pi.transfer(msg.sender,currpiAmount.sub(prevpiAmount));
        
        if(currpETHAmount>prevpETHAmount)
            pETH.transfer(msg.sender,currpETHAmount.sub(prevpETHAmount));

    }


     //  CircleNFT => Pi
    function easySellSmallCircleToPi(address _LPToken, uint256 sCircleValue) external nonReentrant
    {

        uint256 prevpETHAmount = pETH.balanceOf(address(this));
        uint256 prevPiAmount = pi.balanceOf(address(this));

        ERC1155Token.safeTransferFrom( msg.sender, address(this), sCircleTokenId, sCircleValue, "0x");        
        uint256 claimed = vaultContract.sellSmallCircle(_LPToken, sCircleValue);

        uniswapV2Router.removeLiquidity(address(pETH), address(pi), claimed, 0, 0, address(this), block.timestamp);
     
        
        uint256 currpETHAmount = pETH.balanceOf(address(this));
        pETHDirect.easyBuyFromPETH(currpETHAmount.sub(prevpETHAmount));

        uint256 currpiAmount = pi.balanceOf(address(this)); 
        pi.transfer(msg.sender, currpiAmount.sub(prevPiAmount));

    }


    //  CircleNFT => pETH
    function easySellSmallCircleToPETH(address _LPToken, uint256 sCircleValue) external nonReentrant
    {
        uint256 prevpETHAmount = pETH.balanceOf(address(this));
        uint256 prevPiAmount = pi.balanceOf(address(this));

        ERC1155Token.safeTransferFrom(msg.sender, address(this), sCircleTokenId, sCircleValue, "0x");        
        uint256 claimed = vaultContract.sellSmallCircle(_LPToken, sCircleValue);

        uniswapV2Router.removeLiquidity(address(pETH), address(pi), claimed, 0, 0, address(this), block.timestamp);
                
        uint256 currpiAmount = pi.balanceOf(address(this)); 
        if(currpiAmount>prevPiAmount)
            pETHDirect.easySellToPETH(currpiAmount.sub(prevPiAmount));

        uint256 currpETHAmount = pETH.balanceOf(address(this));
        if(currpETHAmount>prevpETHAmount )
            pETH.transfer(msg.sender, currpETHAmount.sub(prevpETHAmount));
    }


    //  CircleNFT => BNB
    function easySellSmallCircleToBNB(address _LPToken, uint256 sCircleValue) external nonReentrant
    {
        uint256 prevpETHAmount = pETH.balanceOf(address(this));
        uint256 prevPiAmount = pi.balanceOf(address(this));

        ERC1155Token.safeTransferFrom( msg.sender, address(this), sCircleTokenId, sCircleValue, "0x");        
        uint256 claimed = vaultContract.sellSmallCircle(_LPToken, sCircleValue);

        uniswapV2Router.removeLiquidity(address(pETH), address(pi), claimed, 0, 0, address(this), block.timestamp);
        
        uint256 currpiAmount = pi.balanceOf(address(this)); 
        pETHDirect.easySellToPETH(currpiAmount.sub(prevPiAmount));

        uint256 currpETHAmount = pETH.balanceOf(address(this));
        uint256 pETHAmt = currpETHAmount.sub(prevpETHAmount);

        uint remAmount = pETHAmt;
        if(!pETH.isIgnored(msg.sender)){
            uint feeAmount= pETHAmt.mul(pETH.FEE()).div(100000);
            remAmount = pETHAmt.sub(feeAmount);
            pETH.transfer(pETH.FEE_ADDRESS(), feeAmount);
        }

        pETH.withdraw(remAmount);

        (bool success,) = msg.sender.call{ value: remAmount }("");
        require (success, "Transfer failed");
        
        // any residue sent back to buyer/seller
        if(pi.balanceOf(address(this))>prevPiAmount)
            pi.transfer(msg.sender,pi.balanceOf(address(this)).sub(prevPiAmount));
        
        if(pETH.balanceOf(address(this))>prevpETHAmount)
            pETH.transfer(msg.sender,pETH.balanceOf(address(this)).sub(prevpETHAmount));

    }
}